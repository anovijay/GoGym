import SwiftUI
import MapKit
import CoreLocation
import os

struct MarkGymLocationView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0), // Default location
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var locationManager = CLLocationManager()
    @State private var locationPermissionStatus: LocationPermissionStatus = .notDetermined
    @State private var showPermissionOverlay = false

    // Logger instance for structured tracing
    private let logger = Logger(subsystem: "com.example.GoGym", category: "MarkGymLocationView")

    var body: some View {
        ZStack {
            MapView(region: $region)
                .onAppear {
                    logger.debug("MarkGymLocationView appeared.")
                    checkLocationAuthorization()
                }

            if showPermissionOverlay {
                VStack {
                    Text("Location access is required to mark your gym.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding()

                    Button(action: {
                        logger.debug("Grant Location Access button clicked.")
                        requestLocationAccess()
                    }) {
                        Text("Grant Location Access")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .shadow(radius: 10)
            }
        }
    }

    private func checkLocationAuthorization() {
        let status = locationManager.authorizationStatus
        logger.debug("Checking location authorization: \(status.rawValue)")

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            logger.debug("Location authorization granted.")
            locationPermissionStatus = .granted
            showPermissionOverlay = false
            updateRegionToUserLocation()
        case .notDetermined:
            logger.debug("Location authorization not determined.")
            locationPermissionStatus = .notDetermined
            showPermissionOverlay = true
        case .denied, .restricted:
            logger.error("Location authorization denied or restricted.")
            locationPermissionStatus = .denied
            showPermissionOverlay = true
        @unknown default:
            logger.error("Unknown location authorization status.")
            locationPermissionStatus = .denied
            showPermissionOverlay = true
        }
    }

    private func requestLocationAccess() {
        logger.debug("Requesting location access...")
        locationManager.delegate = LocationDelegate { status in
            logger.debug("Location authorization status changed to: \(status.rawValue)")
            handleAuthorizationStatus(status)
        }
        locationManager.requestWhenInUseAuthorization()
    }

    private func handleAuthorizationStatus(_ status: CLAuthorizationStatus) {
        logger.debug("Handling location authorization status: \(status.rawValue)")
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            logger.debug("Location access granted.")
            locationPermissionStatus = .granted
            showPermissionOverlay = false
            updateRegionToUserLocation()
        default:
            logger.error("Location access denied.")
            locationPermissionStatus = .denied
            showPermissionOverlay = true
        }
    }

    private func updateRegionToUserLocation() {
        if let userLocation = locationManager.location?.coordinate {
            logger.debug("Updating region to user location: (\(userLocation.latitude), \(userLocation.longitude))")
            region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        } else {
            logger.error("Failed to retrieve user location.")
        }
    }
}

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.setRegion(region, animated: true)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)
    }
}

enum LocationPermissionStatus {
    case notDetermined, granted, denied
}

class LocationDelegate: NSObject, CLLocationManagerDelegate {
    private let onAuthorizationChange: (CLAuthorizationStatus) -> Void
    private let logger = Logger(subsystem: "com.example.GoGym", category: "LocationDelegate")

    init(onAuthorizationChange: @escaping (CLAuthorizationStatus) -> Void) {
        self.onAuthorizationChange = onAuthorizationChange
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        logger.debug("Location authorization status changed: \(status.rawValue)")
        onAuthorizationChange(status)
    }
}

