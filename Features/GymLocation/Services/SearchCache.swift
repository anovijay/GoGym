//
//  SearchCache.swift
//  GoGym
//
//  Created by Anoop Vijayan on 10.01.25.
//
import Foundation

class SearchCache {
    // MARK: - Private Properties
    private var cache: [String: (gyms: [NearbyGym], timestamp: Date)] = [:]
    private let timeout: TimeInterval = 300 // 5 minutes
    
    // MARK: - Public Methods
    func getCached(for query: String) -> [NearbyGym]? {
        guard let cached = cache[query],
              Date().timeIntervalSince(cached.timestamp) < timeout else {
            cache.removeValue(forKey: query)
            return nil
        }
        return cached.gyms
    }
    
    func cache(_ gyms: [NearbyGym], for query: String) {
        cache[query] = (gyms: gyms, timestamp: Date())
    }
    
    func clear() {
        cache.removeAll()
    }
}
