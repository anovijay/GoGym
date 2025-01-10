//
//  LocationTrackingService.swift
//  GoGym
//
//  Created by Anoop Vijayan on 10.01.25.
//

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
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 10
        locationManager.activityType = .fitness
        locationManager.pausesLocationUpdatesAutomatically = true
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
        guard let location = locations.last,
              location.horizontalAccuracy <= 100 else { return }
        
        currentLocation = location.coordinate
        currentRetries = 0
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if currentRetries < maxRetries {
            currentRetries += 1
            manager.startUpdatingLocation()
        } else {
            errorHandler.handle(error)
        }
    }
}
