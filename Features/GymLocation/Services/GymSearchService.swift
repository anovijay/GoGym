import Foundation
import CoreLocation
import MapKit

class GymSearchService {
    // MARK: - Private Properties
    private let searchRadius: CLLocationDistance = 5000 // 5km radius
    private let pageSize = 20
    private let errorHandler: ErrorHandling
    private let searchCache: SearchCache
    
    // MARK: - Initialization
    init(errorHandler: ErrorHandling) {
        self.errorHandler = errorHandler
        self.searchCache = SearchCache()
    }
    
    // MARK: - Public Methods
    func fetchNearbyGyms(
        near location: CLLocationCoordinate2D?,
        searchText: String = "",
        page: Int = 1
    ) async throws -> [NearbyGym] {
        guard let location = location else {
            throw LocationError.locationNotAvailable
        }
        
        if let cached = searchCache.getCached(for: searchText) {
            return paginateResults(cached, page: page)
        }

        var allResults: [MKMapItem] = []
        
        // Define search queries for different types of fitness venues
        let searchQueries = searchText.isEmpty ?
            ["gym", "fitness", "yoga studio", "martial arts", "health club", "crossfit"] :
            ["\(searchText)", "\(searchText) gym", "\(searchText) fitness", "\(searchText) yoga"]
        
        // Search for each query type with initial radius
        for query in searchQueries {
            if let results = try? await performSearch(near: location, searchText: query, radius: 2000) {
                allResults.append(contentsOf: results)
            }
        }
        
        // If we don't find enough results, try wider radius
        if allResults.count < 5 {
            for query in searchQueries {
                if let results = try? await performSearch(near: location, searchText: query, radius: searchRadius) {
                    allResults.append(contentsOf: results)
                }
            }
        }

        let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let gyms = processMapItems(allResults, userLocation: userLocation)
        
        // Remove duplicates and sort
        let uniqueGyms = removeDuplicates(from: gyms)
        let sortedGyms = uniqueGyms.sorted { ($0.distance ?? 0) < ($1.distance ?? 0) }
        
        searchCache.cache(sortedGyms, for: searchText)
        return paginateResults(sortedGyms, page: page)
    }
    
    // MARK: - Private Methods
    private func performSearch(
        near location: CLLocationCoordinate2D,
        searchText: String,
        radius: CLLocationDistance
    ) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.resultTypes = .pointOfInterest
        request.naturalLanguageQuery = searchText
        request.region = MKCoordinateRegion(
            center: location,
            latitudinalMeters: radius,
            longitudinalMeters: radius
        )
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            return response.mapItems
        } catch {
            throw LocationError.searchFailed
        }
    }
    
    private func processMapItems(_ items: [MKMapItem], userLocation: CLLocation) -> [NearbyGym] {
        items.map { item in
            let itemLocation = CLLocation(
                latitude: item.placemark.coordinate.latitude,
                longitude: item.placemark.coordinate.longitude
            )
            let distance = itemLocation.distance(from: userLocation)
            return NearbyGym(
                id: UUID(),
                name: item.name ?? "Unknown Gym",
                coordinate: item.placemark.coordinate,
                address: formatAddress(from: item.placemark),
                distance: distance,
                type: determineGymType(from: item)
            )
        }
    }
    
    private func removeDuplicates(from gyms: [NearbyGym]) -> [NearbyGym] {
        var uniqueGyms: [NearbyGym] = []
        var seenLocations: Set<String> = []
        
        for gym in gyms {
            // Create a location key with reduced precision to group nearby locations
            let latKey = String(format: "%.4f", gym.coordinate.latitude)
            let lonKey = String(format: "%.4f", gym.coordinate.longitude)
            let locationKey = "\(latKey),\(lonKey)"
            
            if !seenLocations.contains(locationKey) {
                uniqueGyms.append(gym)
                seenLocations.insert(locationKey)
            }
        }
        
        return uniqueGyms
    }
    
    private func paginateResults(_ gyms: [NearbyGym], page: Int) -> [NearbyGym] {
        let startIndex = (page - 1) * pageSize
        let endIndex = min(startIndex + pageSize, gyms.count)
        return Array(gyms[startIndex..<endIndex])
    }
    
    private func formatAddress(from placemark: MKPlacemark) -> String {
        [
            placemark.subThoroughfare,
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }
    
    private func determineGymType(from item: MKMapItem) -> GymType {
        let lowercasedName = item.name?.lowercased() ?? ""
        
        // Check for yoga-specific terms
        if lowercasedName.contains("yoga") ||
           lowercasedName.contains("ashtanga") ||
           lowercasedName.contains("vinyasa") {
            return .yoga
        }
        
        // Check for CrossFit
        if lowercasedName.contains("crossfit") ||
           lowercasedName.contains("cross fit") {
            return .crossfit
        }
        
        // Check for martial arts
        if lowercasedName.contains("martial") ||
           lowercasedName.contains("karate") ||
           lowercasedName.contains("jiu") ||
           lowercasedName.contains("dojo") ||
           lowercasedName.contains("taekwondo") {
            return .martialArts
        }
        
        return .fitness
    }
}
