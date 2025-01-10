// GymVisitTrackingService.swift
import Foundation
import CoreLocation
import Combine

class GymVisitTrackingService: NSObject, ObservableObject {
    struct Config {
        static let defaultGeofenceRadius: Double = 50.0
        static let minGeofenceRadius: Double = 25.0
        static let maxGeofenceRadius: Double = 200.0
    }
    
    // MARK: - Published Properties
    @Published private(set) var currentVisit: GymVisit?
    @Published private(set) var monitoredGyms: [GymDetails] = []
    
    // MARK: - Private Properties
    private let locationManager: CLLocationManager
    private let errorHandler: ErrorHandling
    private var monitoredRegions: Set<String> = []
    private var locationUpdateTimer: Timer?
    
    // MARK: - Initialization
    init(errorHandler: ErrorHandling = AppErrorHandler.shared) {
        self.errorHandler = errorHandler
        self.locationManager = CLLocationManager()
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = true  // Enable power saving
        locationManager.activityType = .fitness  // Optimize for fitness tracking
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters  // Reduce accuracy requirement
        
        // Only start significant location updates if needed
        if Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") != nil {
            locationManager.startMonitoringSignificantLocationChanges()
        }
    }
    
    func restartMonitoring() {
        for gym in monitoredGyms {
            stopMonitoring(gym)
            startMonitoring(gym)
        }
    }
    
    // MARK: - Public Methods
    func startMonitoring(_ gym: GymDetails) {
        let identifier = gym.id.uuidString
        
        // Check for existing monitoring
        guard !monitoredRegions.contains(identifier) else { return }
        
        // Validate maximum regions (iOS limit is 20)
        if locationManager.monitoredRegions.count >= 20 {
            errorHandler.handle("Maximum number of monitored regions reached")
            return
        }
        
        let region = CLCircularRegion(
            center: gym.coordinate,
            radius: gym.geofenceRadius,
            identifier: identifier
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
        monitoredRegions.insert(identifier)
        monitoredGyms.append(gym)
    }
    
    func stopMonitoring(_ gym: GymDetails) {
        let identifier = gym.id.uuidString
        locationManager.monitoredRegions
            .filter { $0.identifier == identifier }
            .forEach { locationManager.stopMonitoring(for: $0) }
        monitoredRegions.remove(identifier)
        monitoredGyms.removeAll { $0.id == gym.id }
    }
    
    func stopMonitoringAll() {
        locationManager.monitoredRegions.forEach { locationManager.stopMonitoring(for: $0) }
        monitoredRegions.removeAll()
        monitoredGyms.removeAll()
    }
    
    func isMonitoring(_ gym: GymDetails) -> Bool {
        return monitoredRegions.contains(gym.id.uuidString)
    }
    
    func requestPermissions() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization()
        case .authorizedAlways:
            // We have what we need
            break
        case .denied, .restricted:
            errorHandler.handle("Always allow location access to track gym visits.")
        @unknown default:
            break
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension GymVisitTrackingService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            // We have the permissions we need
            break
        case .authorizedWhenInUse:
            // We need "Always" permission for background monitoring
            manager.requestAlwaysAuthorization()
        case .denied, .restricted:
            errorHandler.handle("Always allow location access to track gym visits.")
        case .notDetermined:
            manager.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let gym = monitoredGyms.first(where: { $0.id.uuidString == region.identifier }) else {
            return
        }
        
        let visit = GymVisit(
            id: UUID(),
            gymId: gym.id,
            startTime: Date(),
            endTime: nil
        )
        
        currentVisit = visit
        
        NotificationCenter.default.post(
            name: .gymVisitStarted,
            object: nil,
            userInfo: ["visit": visit, "gym": gym]
        )
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard let gym = monitoredGyms.first(where: { $0.id.uuidString == region.identifier }) else {
            return
        }
        
        if var visit = currentVisit, visit.gymId == gym.id {
            visit.endTime = Date()
            currentVisit = nil
            
            NotificationCenter.default.post(
                name: .gymVisitEnded,
                object: nil,
                userInfo: ["visit": visit, "gym": gym]
            )
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        errorHandler.handle("Failed to monitor region: \(error.localizedDescription)")
    }
}
