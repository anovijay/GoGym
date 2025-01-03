//
//  GymLocationViewModel.swift
//  GoGym
//
//  Created by Anoop Vijayan on 02.01.25.
//
import SwiftUI
import MapKit
import CoreLocation
import Combine

final class GymLocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region: MKCoordinateRegion
    @Published var selectedGymLocation: CLLocationCoordinate2D?
    @Published var geofenceRadius: Double
    @Published var showLocationAlert = false
    @Published var showSaveConfirmation = false
    @Published var saveError: String?

    private let locationManager: CLLocationManager
    
    override init() {
        self.locationManager = CLLocationManager()
        self.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        self.geofenceRadius = 50

        super.init()
        self.locationManager.delegate = self
        self.setupLocationManager()
    }

    private func setupLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            switch locationManager.authorizationStatus {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                updateRegionToUserLocation()
            case .denied, .restricted:
                showLocationAlert = true
            default:
                break
            }
        } else {
            showLocationAlert = true
        }
    }


    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            updateRegionToUserLocation()
        case .denied, .restricted:
            showLocationAlert = true
        default: break
        }
    }

    private func updateRegionToUserLocation() {
        if let location = locationManager.location?.coordinate {
            region = MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        }
    }

    func saveGeofence() {
        guard let location = selectedGymLocation else {
            saveError = "No gym location selected."
            return
        }

        do {
            let defaults = UserDefaults.standard
            defaults.set(location.latitude, forKey: "gymLatitude")
            defaults.set(location.longitude, forKey: "gymLongitude")
            defaults.set(geofenceRadius, forKey: "geofenceRadius")

            if defaults.synchronize() {
                showSaveConfirmation = true
            } else {
                throw NSError(domain: "SaveError", code: 1, userInfo: nil)
            }
        } catch {
            saveError = "Failed to save the gym location."
        }
    }
}
