import Foundation
import CoreLocation
import MapKit
import Combine

class GymLocationService: NSObject, ObservableObject {
    // MARK: - Debug Configuration
    static var isDebugEnabled: Bool = false
    private func logDebug(_ message: String) {
        guard Self.isDebugEnabled else { return }
        print("🔍 GymLocationService: \(message)")
    }
    
    // MARK: - Published Properties
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus
    
    // MARK: - Service Components
    private let locationTracker: LocationTrackingService
    private let gymSearchService: GymSearchService
    private let gymStorageService: GymStorageService
    private let errorHandler: ErrorHandling
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(errorHandler: ErrorHandling = AppErrorHandler.shared) {
        self.errorHandler = errorHandler
        
        // Initialize temporary location manager to get initial authorization status
        let tempLocationManager = CLLocationManager()
        self.authorizationStatus = tempLocationManager.authorizationStatus
        
        // Initialize components
        self.locationTracker = LocationTrackingService(errorHandler: errorHandler)
        self.gymSearchService = GymSearchService(errorHandler: errorHandler)
        self.gymStorageService = GymStorageService(errorHandler: errorHandler)
        
        super.init()
        setupBindings()
    }
    
    private func setupBindings() {
        locationTracker.$currentLocation
            .assign(to: &$currentLocation)
        
        locationTracker.$authorizationStatus
            .assign(to: &$authorizationStatus)
    }
    
    // MARK: - Public Methods
    func startLocationUpdates() {
        logDebug("Starting location updates")
        locationTracker.startUpdatingLocation()
    }
    
    @MainActor
    func fetchNearbyGyms(searchText: String = "", page: Int = 1) async throws -> [NearbyGym] {
        logDebug("Fetching nearby gyms with search: '\(searchText)', page: \(page)")
        return try await gymSearchService.fetchNearbyGyms(
            near: currentLocation,
            searchText: searchText,
            page: page
        )
    }
    
    @MainActor
    func saveGymLocation(_ gym: GymDetails) {
        logDebug("Saving gym location: \(gym.name)")
        gymStorageService.saveGym(gym)
    }
    
    @MainActor
    func deleteGymLocation(_ gym: GymDetails) {
        logDebug("Deleting gym location: \(gym.name)")
        gymStorageService.deleteGym(gym)
    }
    
    @MainActor
    func loadSavedGyms() -> [GymDetails] {
        logDebug("Loading saved gyms")
        return gymStorageService.loadSavedGyms()
    }
    
    func requestLocationPermission() {
        logDebug("Requesting location permission")
        locationTracker.requestLocationPermission()
    }
}
