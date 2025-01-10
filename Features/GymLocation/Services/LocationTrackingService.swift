import Foundation
import CoreLocation
import Combine

class LocationTrackingService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var currentLocation: CLLocationCoordinate2D?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    
    // MARK: - Private Properties
    private let locationManager: CLLocationManager
    private let errorHandler: ErrorHandling
    private let maxRetries = 3
    private var currentRetries = 0
    private var desiredAccuracy: CLLocationAccuracy = 100 // 100 meters initially
    
    // MARK: - Initialization
    init(errorHandler: ErrorHandling) {
        self.errorHandler = errorHandler
        self.locationManager = CLLocationManager()
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  // Request best accuracy
        locationManager.distanceFilter = 10  // Update if moved by 10 meters
        locationManager.activityType = .fitness
    }
    
    // MARK: - Public Methods
    func startUpdatingLocation() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            errorHandler.handle("Location access is required. Please enable location services in Settings.")
        @unknown default:
            break
        }
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
}

// MARK: - LocationTrackingService CLLocationManagerDelegate
extension LocationTrackingService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            currentRetries = 0
        case .denied, .restricted:
            errorHandler.handle("Location access is required. Please enable location services in Settings.")
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Check if accuracy is good enough
        if location.horizontalAccuracy <= desiredAccuracy {
            currentLocation = location.coordinate
            // Once we get accurate location, tighten accuracy requirement
            desiredAccuracy = min(desiredAccuracy, location.horizontalAccuracy)
            currentRetries = 0
            print("📍 Location accuracy: \(location.horizontalAccuracy)m")
        } else {
            print("📍 Waiting for better accuracy. Current: \(location.horizontalAccuracy)m, Desired: \(desiredAccuracy)m")
            // After some retries, gradually relax accuracy requirement
            if currentRetries > maxRetries {
                desiredAccuracy *= 1.5  // Increase acceptable accuracy by 50%
                currentRetries = 0
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError {
            switch error.code {
            case .locationUnknown:
                // Temporary error, keep trying
                currentRetries += 1
                if currentRetries <= maxRetries {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.locationManager.startUpdatingLocation()
                    }
                }
            case .denied:
                errorHandler.handle("Location access denied")
            default:
                errorHandler.handle(error)
            }
        } else {
            errorHandler.handle(error)
        }
    }
}
