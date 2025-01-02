import SwiftUI
import MapKit
import CoreLocation
import Combine

// MARK: - View Models
final class GymLocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region: MKCoordinateRegion
    @Published var selectedGymLocation: CLLocationCoordinate2D?
    @Published var geofenceRadius: Double
    @Published var showLocationAlert = false
    @Published var showSaveConfirmation = false
    @Published var showHelp = false
    @Published var saveError: String?

    private let locationManager: CLLocationManager
    private var cancellables = Set<AnyCancellable>()

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
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        } else {
            showLocationAlert = true
        }
    }

    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            DispatchQueue.global().async {
                self.locationManager.requestWhenInUseAuthorization()
            }
        case .authorizedWhenInUse, .authorizedAlways:
            updateRegionToUserLocation()
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.showLocationAlert = true
            }
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.updateRegionToUserLocation(with: location.coordinate)
        }
    }

    private func updateRegionToUserLocation(with coordinate: CLLocationCoordinate2D? = nil) {
        let locationCoordinate = coordinate ?? locationManager.location?.coordinate
        guard let userLocation = locationCoordinate else { return }

        region = MKCoordinateRegion(
            center: userLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
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
                throw NSError(domain: "Save Error", code: 1, userInfo: nil)
            }
        } catch {
            saveError = "Failed to save the gym location. Please try again."
        }
    }
}

// MARK: - Main View
struct MarkGymLocationView: View {
    @StateObject private var viewModel = GymLocationViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                MapViewRepresentable(
                    region: $viewModel.region,
                    selectedLocation: $viewModel.selectedGymLocation,
                    geofenceRadius: viewModel.geofenceRadius
                )

                overlayViews
            }
            .alert("Location Services Disabled", isPresented: $viewModel.showLocationAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Marking and tracking of gym visits relies on location services. Please enable it for accurate tracking.")
            }
            .alert("Success", isPresented: $viewModel.showSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your gym location has been saved successfully!")
            }
            .alert("Error", isPresented: .constant(viewModel.saveError != nil)) {
                Button("OK", role: .cancel) { viewModel.saveError = nil }
            } message: {
                Text(viewModel.saveError ?? "Unknown error.")
            }
            .sheet(isPresented: $viewModel.showHelp) {
                HelpView()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Mark Gym Location")
                        .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.showHelp.toggle()
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var overlayViews: some View {
        VStack {
            Spacer()
            if viewModel.selectedGymLocation == nil {
                instructionOverlay
            } else {
                controlsOverlay
            }
        }
    }

    private var instructionOverlay: some View {
        Text("Tap or long press on the map to select your gym location.")
            .padding()
            .background(Material.regular)
            .cornerRadius(8)
            .shadow(radius: 5)
            .padding()
    }

    private var controlsOverlay: some View {
        VStack(spacing: 16) {
            Text("Adjust Geofence Radius: \(Int(viewModel.geofenceRadius)) meters")
                .font(.headline)

            HStack {
                Slider(
                    value: $viewModel.geofenceRadius,
                    in: 50...1000,
                    step: 10
                )

                TextField("Radius", value: $viewModel.geofenceRadius, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 80)
                    .keyboardType(.numberPad)
            }
            .padding()

            Button(action: viewModel.saveGeofence) {
                Text("Save Gym Location")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Material.regular)
        .cornerRadius(12)
        .shadow(radius: 10)
        .padding()
    }
}

// MARK: - Map View
struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedLocation: CLLocationCoordinate2D?
    let geofenceRadius: Double

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true

        let gesture = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress)
        )
        gesture.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(gesture)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)

        // Update annotations
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        if let location = selectedLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            mapView.addAnnotation(annotation)

            // Add drop animation
            UIView.animate(withDuration: 0.3) {
                annotation.coordinate = location
            }
        }

        // Update overlay
        mapView.removeOverlays(mapView.overlays)
        if let location = selectedLocation {
            let circle = MKCircle(center: location, radius: geofenceRadius)
            mapView.addOverlay(circle)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        @objc func handleLongPress(gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began,
                  let mapView = gesture.view as? MKMapView else { return }

            let location = gesture.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            parent.selectedLocation = coordinate
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let circle = overlay as? MKCircle else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKCircleRenderer(circle: circle)
            renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.2)
            renderer.strokeColor = UIColor.systemBlue
            renderer.lineWidth = 2
            return renderer
        }
    }
}

// MARK: - Help View
struct HelpView: View {
    var body: some View {
        List {
            Section {
                Text("1. Tap or long press on the map to select your gym location.")
                Text("2. Use the slider or input a value to adjust the geofence radius.")
                Text("3. Click 'Save Gym Location' to confirm.")
            } header: {
                Text("How to Mark Your Gym Location")
            }
        }
        .listStyle(.insetGrouped)
    }
}
