import Foundation

/// A thread-safe actor that manages in-memory and disk caching for API responses
actor CacheManager {
    static let shared = CacheManager()

    /// Cache entry with data and timestamp
    private struct CacheEntry: Codable {
        let data: Data
        let timestamp: Date
    }

    /// In-memory cache, filled from disk the first time any method touches it.
    /// The load runs on the actor before that access continues, so a read on
    /// a cold launch can't miss data that's on disk, and a load can never
    /// land after a later write or wipe.
    private lazy var memoryCache: [String: CacheEntry] = loadDiskCache()

    /// Disk cache directory
    private let cacheDirectory: URL

    /// UserDefaults key for the user id the cache belongs to
    private static let ownerKey = "cache_manager.owner_user_id"

    private init() {
        // Use Caches directory (system can clean when storage is low)
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDir.appendingPathComponent("APICache", isDirectory: true)

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Public API

    /// Get a cached value for the given key
    func get<T: Decodable>(_ key: CacheKey) -> T? {
        guard let entry = memoryCache[key.stringValue] else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: entry.data)
        } catch {
            print("CacheManager: Failed to decode cached data for key \(key.stringValue): \(error)")
            return nil
        }
    }

    /// Set a value in the cache (both memory and disk)
    func set<T: Encodable>(_ key: CacheKey, value: T) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(value)
            let entry = CacheEntry(data: data, timestamp: Date())

            // Store in memory
            memoryCache[key.stringValue] = entry

            // Store on disk
            saveToDisk(key: key, entry: entry)
        } catch {
            print("CacheManager: Failed to encode data for key \(key.stringValue): \(error)")
        }
    }

    /// Invalidate specific cache keys
    func invalidate(_ keys: CacheKey...) {
        for key in keys {
            memoryCache.removeValue(forKey: key.stringValue)
            removeFromDisk(key: key)
        }
    }

    /// Invalidate multiple keys at once (for programmatic use)
    func invalidateKeys(_ keys: [CacheKey]) {
        for key in keys {
            memoryCache.removeValue(forKey: key.stringValue)
            removeFromDisk(key: key)
        }
    }

    /// Invalidate all cached data
    func invalidateAll() {
        memoryCache.removeAll()
        clearDiskCache()
    }

    /// Record which user the cached responses belong to, wiping everything
    /// when that changes so the next account never sees the previous one's
    /// data. `nil` means signed out. The owner is persisted so a relaunch
    /// can tell whether the disk cache is still the signed-in user's; an
    /// unknown owner (first run after upgrading) counts as a change.
    func setOwner(_ userId: String?) {
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: Self.ownerKey) != userId else { return }

        invalidateAll()
        if let userId {
            defaults.set(userId, forKey: Self.ownerKey)
        } else {
            defaults.removeObject(forKey: Self.ownerKey)
        }
    }

    // MARK: - Disk Cache Operations

    private func loadDiskCache() -> [String: CacheEntry] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return [:]
        }

        var entries: [String: CacheEntry] = [:]
        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let entry = try? JSONDecoder().decode(CacheEntry.self, from: data) else {
                continue
            }

            let key = file.deletingPathExtension().lastPathComponent
            entries[key] = entry
        }
        return entries
    }

    private func saveToDisk(key: CacheKey, entry: CacheEntry) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key.stringValue).json")

        do {
            let data = try JSONEncoder().encode(entry)
            try data.write(to: fileURL)
        } catch {
            print("CacheManager: Failed to save to disk for key \(key.stringValue): \(error)")
        }
    }

    private func removeFromDisk(key: CacheKey) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key.stringValue).json")
        try? FileManager.default.removeItem(at: fileURL)
    }

    private func clearDiskCache() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }

        for file in files {
            try? FileManager.default.removeItem(at: file)
        }
    }
}
