// GymLocationService.swift
import Foundation
import CoreLocation
import MapKit
import Combine

class GymLocationService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private let searchRadius: CLLocationDistance = 5000 // 5km
    private var cachedGyms: [String: (gyms: [NearbyGym], timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    private let errorHandler: ErrorHandling
    private let maxRetries = 3
    private var currentRetries = 0
    private let pageSize = 20
    private let locationSubject = PassthroughSubject<CLLocationCoordinate2D, Never>()
    
    // MARK: - Initialization
    init(errorHandler: ErrorHandling = AppErrorHandler.shared) {
        self.errorHandler = errorHandler
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
    }
    
    // MARK: - Location Methods
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationUpdates() -> AsyncStream<CLLocationCoordinate2D> {
        AsyncStream { continuation in
            let cancellable = locationSubject
                .sink { coordinate in
                    continuation.yield(coordinate)
                }
            
            continuation.onTermination = { @Sendable _ in
                cancellable.cancel()
            }
        }
    }
    
    // MARK: - Gym Search Methods
    @MainActor
    func fetchNearbyGyms(searchText: String = "", page: Int = 1) async throws -> [NearbyGym] {
        if let cached = getCachedResults(for: searchText) {
            return cached
        }
        
        guard let location = self.currentLocation else {
            throw LocationError.locationNotAvailable
        }
        
        let request = MKLocalSearch.Request()
        request.resultTypes = .pointOfInterest
        request.naturalLanguageQuery = searchText.isEmpty ? "gym fitness" : "\(searchText) gym"
        request.region = MKCoordinateRegion(
            center: location,
            latitudinalMeters: self.searchRadius,
            longitudinalMeters: self.searchRadius
        )
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            let gyms = processMapItems(response.mapItems, userLocation: userLocation)
            
            cacheResults(gyms, for: searchText)
            return paginateResults(gyms, page: page)
            
        } catch {
            self.errorHandler.handle(error)
            throw LocationError.searchFailed
        }
    }
    
    // MARK: - Gym Management Methods
    @MainActor
    func deleteGymLocation(_ gym: GymDetails) {
        var savedGyms = loadSavedGyms()
        savedGyms.removeAll { $0.id == gym.id }
        do {
            let data = try JSONEncoder().encode(savedGyms)
            UserDefaults.standard.set(data, forKey: "savedGyms")
            NotificationCenter.default.post(name: .gymLocationUpdated, object: nil)
        } catch {
            self.errorHandler.handle("Failed to delete gym location: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func addVisit(for gym: GymDetails) {
        var savedGyms = loadSavedGyms()
        if let index = savedGyms.firstIndex(where: { $0.id == gym.id }) {
            var updatedGym = savedGyms[index]
            updatedGym.visits.append(Date())
            savedGyms[index] = updatedGym
            do {
                let data = try JSONEncoder().encode(savedGyms)
                UserDefaults.standard.set(data, forKey: "savedGyms")
                NotificationCenter.default.post(name: .gymLocationUpdated, object: nil)
            } catch {
                self.errorHandler.handle("Failed to update gym visits: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    func loadSavedGyms() -> [GymDetails] {
        guard let data = UserDefaults.standard.data(forKey: "savedGyms") else {
            return []
        }
        do {
            return try JSONDecoder().decode([GymDetails].self, from: data)
        } catch {
            self.errorHandler.handle("Failed to load saved gyms: \(error.localizedDescription)")
            return []
        }
    }
    
    @MainActor
    func loadSavedGym() -> GymDetails? {
        guard let data = UserDefaults.standard.data(forKey: "savedGym") else {
            return nil
        }
        do {
            return try JSONDecoder().decode(GymDetails.self, from: data)
        } catch {
            self.errorHandler.handle("Failed to load saved gym: \(error.localizedDescription)")
            return nil
        }
    }
    
    @MainActor
    func saveGymLocation(_ gym: GymDetails) {
        var savedGyms = loadSavedGyms()
        if !savedGyms.contains(gym) {
            savedGyms.append(gym)
            do {
                let data = try JSONEncoder().encode(savedGyms)
                UserDefaults.standard.set(data, forKey: "savedGyms")
                NotificationCenter.default.post(name: .gymLocationUpdated, object: nil)
            } catch {
                self.errorHandler.handle("Failed to save gym location: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Private Helper Methods
    private func processMapItems(_ items: [MKMapItem], userLocation: CLLocation) -> [NearbyGym] {
        let gyms = items.map { item -> NearbyGym in
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
        
        return gyms.sorted { ($0.distance ?? 0) < ($1.distance ?? 0) }
    }
    
    private func paginateResults(_ gyms: [NearbyGym], page: Int) -> [NearbyGym] {
        let startIndex = (page - 1) * self.pageSize
        let endIndex = min(startIndex + self.pageSize, gyms.count)
        return Array(gyms[startIndex..<endIndex])
    }
    
    private func getCachedResults(for query: String) -> [NearbyGym]? {
        guard let cached = self.cachedGyms[query] else { return nil }
        let now = Date()
        guard now.timeIntervalSince(cached.timestamp) < self.cacheTimeout else {
            self.cachedGyms.removeValue(forKey: query)
            return nil
        }
        return cached.gyms
    }
    
    private func cacheResults(_ gyms: [NearbyGym], for query: String) {
        self.cachedGyms[query] = (gyms: gyms, timestamp: Date())
    }
    
    private func determineGymType(from item: MKMapItem) -> GymType {
        let lowercasedName = item.name?.lowercased() ?? ""
        if lowercasedName.contains("crossfit") {
            return .crossfit
        } else if lowercasedName.contains("yoga") {
            return .yoga
        } else if lowercasedName.contains("martial") || lowercasedName.contains("karate") || lowercasedName.contains("jiu") {
            return .martialArts
        } else {
            return .fitness
        }
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
}

// MARK: - CLLocationManagerDelegate
extension GymLocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
                currentRetries = 0
            case .denied, .restricted:
                errorHandler.handle("Location access is required to find nearby gyms. Please enable location services in Settings.")
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            @unknown default:
                break
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last,
              location.horizontalAccuracy <= 100 else { return }
        
        Task { @MainActor in
            currentLocation = location.coordinate
            locationSubject.send(location.coordinate)
            currentRetries = 0
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if currentRetries < maxRetries {
                currentRetries += 1
                manager.startUpdatingLocation()
            } else {
                errorHandler.handle(error)
            }
        }
    }
}
