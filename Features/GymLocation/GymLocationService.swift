// GymLocationService.swift
import Foundation
import CoreLocation
import MapKit
import Combine

class GymLocationService: NSObject, ObservableObject {
    // MARK: - Debug Configuration
    static var isDebugEnabled: Bool = false
    private func logDebug(_ message: String) {
        guard GymLocationService.isDebugEnabled else { return }
        print("🔍 GymLocationService: \(message)")
    }
    
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
    private var startTime: Date = Date()
    private var updateCount: Int = 0
    
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
        logDebug("Location manager setup completed")
    }
    
    // MARK: - Location Methods
    func requestLocationPermission() {
        logDebug("Requesting location permission")
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
            startTime = Date()
            updateCount = 0
            logDebug("⏱️ startLocationUpdates called - Current status: \(locationManager.authorizationStatus.rawValue)")
            logDebug("⏱️ Current location at start: \(String(describing: currentLocation))")
            
            switch locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                logDebug("Authorization status: authorized")
                locationManager.startUpdatingLocation()
            case .notDetermined:
                logDebug("Authorization status: not determined")
                locationManager.requestWhenInUseAuthorization()
            case .denied, .restricted:
                logDebug("Authorization status: denied/restricted")
                errorHandler.handle("Location access is required to find nearby gyms. Please enable location services in Settings.")
            @unknown default:
                logDebug("Authorization status: unknown")
                break
            }
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
        logDebug("Fetching nearby gyms with search: '\(searchText)', page: \(page)")
        
        if let cached = getCachedResults(for: searchText) {
            logDebug("Returning cached results")
            return cached
        }
        
        guard let location = self.currentLocation else {
            logDebug("Current location not available")
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
            
            logDebug("Found \(gyms.count) gyms")
            cacheResults(gyms, for: searchText)
            return paginateResults(gyms, page: page)
            
        } catch {
            logDebug("Search failed with error: \(error.localizedDescription)")
            self.errorHandler.handle(error)
            throw LocationError.searchFailed
        }
    }
    
    // MARK: - Gym Management Methods
    @MainActor
    func deleteGymLocation(_ gym: GymDetails) {
        logDebug("Deleting gym: \(gym.name)")
        var savedGyms = loadSavedGyms()
        savedGyms.removeAll { $0.id == gym.id }
        do {
            let data = try JSONEncoder().encode(savedGyms)
            UserDefaults.standard.set(data, forKey: "savedGyms")
            NotificationCenter.default.post(name: .gymLocationUpdated, object: nil)
            logDebug("Gym deleted successfully")
        } catch {
            logDebug("Failed to delete gym: \(error.localizedDescription)")
            self.errorHandler.handle("Failed to delete gym location: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func addVisit(for gym: GymDetails) {
        logDebug("Adding visit for gym: \(gym.name)")
        var savedGyms = loadSavedGyms()
        if let index = savedGyms.firstIndex(where: { $0.id == gym.id }) {
            var updatedGym = savedGyms[index]
            updatedGym.visits.append(Date())
            savedGyms[index] = updatedGym
            do {
                let data = try JSONEncoder().encode(savedGyms)
                UserDefaults.standard.set(data, forKey: "savedGyms")
                NotificationCenter.default.post(name: .gymLocationUpdated, object: nil)
                logDebug("Visit added successfully")
            } catch {
                logDebug("Failed to add visit: \(error.localizedDescription)")
                self.errorHandler.handle("Failed to update gym visits: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor
    func loadSavedGyms() -> [GymDetails] {
        logDebug("Loading saved gyms")
        guard let data = UserDefaults.standard.data(forKey: "savedGyms") else {
            logDebug("No saved gyms found")
            return []
        }
        do {
            let gyms = try JSONDecoder().decode([GymDetails].self, from: data)
            logDebug("Loaded \(gyms.count) saved gyms")
            return gyms
        } catch {
            logDebug("Failed to load saved gyms: \(error.localizedDescription)")
            self.errorHandler.handle("Failed to load saved gyms: \(error.localizedDescription)")
            return []
        }
    }
    
    @MainActor
    func loadSavedGym() -> GymDetails? {
        logDebug("Loading saved gym")
        guard let data = UserDefaults.standard.data(forKey: "savedGym") else {
            logDebug("No saved gym found")
            return nil
        }
        do {
            let gym = try JSONDecoder().decode(GymDetails.self, from: data)
            logDebug("Loaded saved gym: \(gym.name)")
            return gym
        } catch {
            logDebug("Failed to load saved gym: \(error.localizedDescription)")
            self.errorHandler.handle("Failed to load saved gym: \(error.localizedDescription)")
            return nil
        }
    }
    
    @MainActor
    func saveGymLocation(_ gym: GymDetails) {
        logDebug("Saving gym location: \(gym.name)")
        var savedGyms = loadSavedGyms()
        if !savedGyms.contains(gym) {
            savedGyms.append(gym)
            do {
                let data = try JSONEncoder().encode(savedGyms)
                UserDefaults.standard.set(data, forKey: "savedGyms")
                NotificationCenter.default.post(name: .gymLocationUpdated, object: nil)
                logDebug("Gym saved successfully")
            } catch {
                logDebug("Failed to save gym: \(error.localizedDescription)")
                self.errorHandler.handle("Failed to save gym location: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Private Helper Methods
    private func processMapItems(_ items: [MKMapItem], userLocation: CLLocation) -> [NearbyGym] {
        logDebug("Processing \(items.count) map items")
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
        let paginatedGyms = Array(gyms[startIndex..<endIndex])
        logDebug("Paginated results: \(paginatedGyms.count) gyms for page \(page)")
        return paginatedGyms
    }
    
    private func getCachedResults(for query: String) -> [NearbyGym]? {
        guard let cached = self.cachedGyms[query] else { return nil }
        let now = Date()
        guard now.timeIntervalSince(cached.timestamp) < self.cacheTimeout else {
            self.cachedGyms.removeValue(forKey: query)
            logDebug("Cache expired for query: \(query)")
            return nil
        }
        logDebug("Returning cached results for query: \(query)")
        return cached.gyms
    }
    
    private func cacheResults(_ gyms: [NearbyGym], for query: String) {
        logDebug("Caching \(gyms.count) gyms for query: \(query)")
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
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        logDebug("Authorization changed to: \(manager.authorizationStatus.rawValue)")
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            logDebug("Starting location updates after authorization")
            manager.startUpdatingLocation()
            currentRetries = 0
        case .denied, .restricted:
            logDebug("Location access denied/restricted")
            errorHandler.handle("Location access is required to find nearby gyms. Please enable location services in Settings.")
        case .notDetermined:
            logDebug("Requesting location authorization")
            manager.requestWhenInUseAuthorization()
        @unknown default:
            logDebug("Unknown authorization status")
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            updateCount += 1
            
            guard let location = locations.last,
                  location.horizontalAccuracy <= 100 else {
                logDebug("⏱️ Location update rejected - Accuracy: \(String(describing: locations.last?.horizontalAccuracy))")
                logDebug("⏱️ Time since start: \(Date().timeIntervalSince(startTime)) seconds")
                logDebug("⏱️ Update count: \(updateCount)")
                return
            }
            
            logDebug("⏱️ Received location update #\(updateCount) after \(Date().timeIntervalSince(startTime)) seconds")
            logDebug("⏱️ Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            currentLocation = location.coordinate
            locationSubject.send(location.coordinate)
            currentRetries = 0
        }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logDebug("Location update failed with error: \(error.localizedDescription)")
        if currentRetries < maxRetries {
            currentRetries += 1
            logDebug("Retrying location update (attempt \(currentRetries)/\(maxRetries))")
            manager.startUpdatingLocation()
        } else {
            logDebug("Max retries reached, handling error")
            errorHandler.handle(error)
        }
    }
}
