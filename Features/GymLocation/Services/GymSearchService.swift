//
//  GymSearchService.swift
//  GoGym
//
//  Created by Anoop Vijayan on 10.01.25.
//
import Foundation
import CoreLocation
import MapKit

class GymSearchService {
    // MARK: - Private Properties
    private let searchRadius: CLLocationDistance = 5000
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
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText.isEmpty ? "gym fitness" : "\(searchText) gym"
        request.region = MKCoordinateRegion(
            center: location,
            latitudinalMeters: searchRadius,
            longitudinalMeters: searchRadius
        )
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            let gyms = processMapItems(response.mapItems, userLocation: userLocation)
            
            searchCache.cache(gyms, for: searchText)
            return paginateResults(gyms, page: page)
        } catch {
            throw LocationError.searchFailed
        }
    }
    
    // MARK: - Private Methods
    private func processMapItems(_ items: [MKMapItem], userLocation: CLLocation) -> [NearbyGym] {
        items.map { item in
            let itemLocation = CLLocation(
                latitude: item.placemark.coordinate.latitude,
                longitude: item.placemark.coordinate.longitude
            )
            return NearbyGym.from(item, distance: itemLocation.distance(from: userLocation))
        }.sorted { ($0.distance ?? 0) < ($1.distance ?? 0) }
    }
    
    private func paginateResults(_ gyms: [NearbyGym], page: Int) -> [NearbyGym] {
        let startIndex = (page - 1) * pageSize
        let endIndex = min(startIndex + pageSize, gyms.count)
        return Array(gyms[startIndex..<endIndex])
    }
}
