import SwiftUI
import CoreLocation
import MapKit

struct NearbyGymsListView: View {
    @StateObject private var gymService: GymLocationService
    @EnvironmentObject private var errorHandler: AppErrorHandler
    @Binding var selectedGym: GymDetails?
    @Binding var isPresented: Bool
    @State private var nearbyGyms: [NearbyGym] = []
    @State private var isLoading = false
    @State private var hasRequestedLocation = false
    @State private var viewLoadTime = Date()
    @State private var lastKnownLocation: CLLocationCoordinate2D?
    
    init(selectedGym: Binding<GymDetails?>, isPresented: Binding<Bool>) {
        _selectedGym = selectedGym
        _isPresented = isPresented
        _gymService = StateObject(wrappedValue: GymLocationService(errorHandler: AppErrorHandler.shared))
    }
    
    private func logDebug(_ message: String) {
        guard GymLocationService.isDebugEnabled else { return }
        print("📱 NearbyGymsView: \(message)")
    }
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Finding gyms nearby...")
                } else if nearbyGyms.isEmpty {
                    emptyStateView
                } else {
                    gymsList
                }
            }
            .navigationTitle("Nearby Gyms")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                logDebug("View appeared")
                setupLocationAndSearch()
            }
            .onChange(of: gymService.authorizationStatus) { newStatus in
                logDebug("Authorization status changed to: \(newStatus.rawValue)")
                handleAuthorizationChange(status: newStatus)
            }
            .onReceive(gymService.$currentLocation) { newLocation in
                if let location = newLocation,
                   (lastKnownLocation?.latitude != location.latitude ||
                    lastKnownLocation?.longitude != location.longitude) {
                    logDebug("Location updated: \(location.latitude), \(location.longitude)")
                    lastKnownLocation = location
                    Task {
                        await loadNearbyGyms()
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash.circle")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            if gymService.authorizationStatus == .denied {
                Text("Location Access Required")
                    .font(.headline)
                Text("Please enable location services in Settings to find nearby gyms")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                Text("No Gyms Found Nearby")
                    .font(.headline)
                
                Button("Try Again") {
                    Task {
                        await loadNearbyGyms()
                    }
                }
            }
        }
    }
    
    private var gymsList: some View {
        List(nearbyGyms) { gym in
            VStack(alignment: .leading) {
                Text(gym.name)
                    .font(.headline)
                
                Text(gym.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let distance = gym.distance {
                    Text(formatDistance(distance))
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectGym(gym)
            }
        }
    }
    
    private func setupLocationAndSearch() {
        viewLoadTime = Date()
        logDebug("⏱️ View load time: \(viewLoadTime)")
        
        if !hasRequestedLocation {
            hasRequestedLocation = true
            logDebug("⏱️ Starting location updates")
            gymService.startLocationUpdates()
            gymService.requestLocationPermission()
            
            if let location = gymService.currentLocation {
                logDebug("⏱️ Initial location already available")
                Task {
                    await loadNearbyGyms()
                }
            } else {
                logDebug("⏱️ No initial location available - waiting for updates")
            }
        } else {
            logDebug("⏱️ Location already requested - skipping setup")
        }
    }
    
    private func handleAuthorizationChange(status: CLAuthorizationStatus) {
        logDebug("Handling authorization change: \(status.rawValue)")
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if let location = gymService.currentLocation {
                logDebug("Location available after authorization: \(location.latitude), \(location.longitude)")
                Task {
                    await loadNearbyGyms()
                }
            } else {
                logDebug("No location available after authorization change")
            }
        case .denied, .restricted:
            logDebug("Location access denied/restricted")
            nearbyGyms = []
            isLoading = false
        default:
            logDebug("Other authorization status: \(status.rawValue)")
            break
        }
    }
    
    private func loadNearbyGyms() async {
        guard !isLoading else {
            logDebug("Skipping loadNearbyGyms - already loading")
            return
        }
        
        logDebug("Starting to load nearby gyms")
        isLoading = true
        
        do {
            nearbyGyms = try await gymService.fetchNearbyGyms()
            logDebug("Successfully loaded \(nearbyGyms.count) gyms")
        } catch {
            logDebug("Failed to load gyms: \(error.localizedDescription)")
            errorHandler.handle(error)
            nearbyGyms = []
        }
        
        isLoading = false
    }
    
    private func selectGym(_ gym: NearbyGym) {
        logDebug("Selecting gym: \(gym.name)")
        selectedGym = GymDetails(
            id: gym.id,
            name: gym.name,
            type: gym.type ?? .fitness,
            latitude: gym.coordinate.latitude,
            longitude: gym.coordinate.longitude,
            address: gym.address,
            geofenceRadius: GymVisitTrackingService.Config.defaultGeofenceRadius,
            visits: []
        )
        isPresented = false
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return String(format: "%.0f m away", distance)
        } else {
            return String(format: "%.1f km away", distance / 1000)
        }
    }
}
