//
//  ExpiringCache.swift
//  WeatherForecast
//
//  Created by Vivek Sadariya on 01/11/26.
//
import Foundation

/// How long cached values are used.
struct CachePolicy: Sendable {
    /// Returned without fetching while younger than this.
    let freshFor: TimeInterval
    /// Returned, marked stale, when a fetch fails and the cached value is younger than this.
    let usableAfterErrorFor: TimeInterval
}

/// An in-memory cache that fetches on a miss and falls back to older values when a fetch fails.
/// Lives as long as the app process; nothing is written to disk.
actor ExpiringCache<Key: Hashable & Sendable, Value: Sendable> {
    private struct Entry {
        let value: Value
        let storedAt: Date
    }

    private let policy: CachePolicy
    private let now: @Sendable () -> Date
    private var entries: [Key: Entry] = [:]

    init(policy: CachePolicy, now: @escaping @Sendable () -> Date = { .now }) {
        self.policy = policy
        self.now = now
    }

    /// The cached value while it's fresh; otherwise a newly fetched one, which replaces it.
    /// If the fetch fails, returns a cached value younger than `usableAfterErrorFor` with `isStale` set.
    /// Cancellation is passed through, never answered with cached data.
    func value(
        for key: Key,
        fetch: @Sendable () async throws -> Value
    ) async throws -> (value: Value, isStale: Bool) {
        let requestedAt = now()
        if let entry = entries[key], requestedAt.timeIntervalSince(entry.storedAt) < policy.freshFor {
            return (entry.value, false)
        }

        do {
            let value = try await fetch()
            let storedAt = now()
            entries[key] = Entry(value: value, storedAt: storedAt)
            // Drop entries no request could use anymore, so the cache can't grow without bound.
            entries = entries.filter { storedAt.timeIntervalSince($0.value.storedAt) < policy.usableAfterErrorFor }
            return (value, false)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            guard let entry = entries[key],
                  requestedAt.timeIntervalSince(entry.storedAt) < policy.usableAfterErrorFor else {
                throw error
            }
            return (entry.value, true)
        }
    }
}
