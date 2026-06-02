import Foundation

/// A thread-safe actor that manages in-memory and disk caching for API responses
actor CacheManager {
    static let shared = CacheManager()

    /// Cache entry with data and timestamp
    private struct CacheEntry: Codable {
        let data: Data
        let timestamp: Date
    }

    /// In-memory cache
    private var memoryCache: [String: CacheEntry] = [:]

    /// Disk cache directory
    private let cacheDirectory: URL

    private init() {
        // Use Caches directory (system can clean when storage is low)
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDir.appendingPathComponent("APICache", isDirectory: true)

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Load existing disk cache into memory
        Task {
            await loadDiskCache()
        }
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

    // MARK: - Disk Cache Operations

    private func loadDiskCache() {
        guard let files = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }

        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let entry = try? JSONDecoder().decode(CacheEntry.self, from: data) else {
                continue
            }

            let key = file.deletingPathExtension().lastPathComponent
            memoryCache[key] = entry
        }
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
