import SwiftUI
import MapKit
import Foundation

struct MarkGymLocationView: View {
    // MARK: - Environment & State Objects
    @StateObject private var gymService = GymLocationService()
    @EnvironmentObject private var errorHandler: AppErrorHandler
    @Environment(\.dismiss) private var dismiss
    // MARK: - Initialization
        init() {
            _gymService = StateObject(wrappedValue: GymLocationService(errorHandler: AppErrorHandler.shared))
        }
        
    // MARK: - State Variables
    // Search and listing states
    @State private var searchText = ""
    @State private var nearbyGyms: [NearbyGym] = []
    @State private var isLoading = false
    @State private var currentPage = 1
    @State private var hasMoreResults = true
    
    // UI states
    @State private var showSuccessMessage = false
    @State private var isCustomLocationMode = false
    
    // Custom location states
    @State private var showingGymDetailsSheet = false
    @State private var gymName = ""
    @State private var selectedGymType: GymType = .fitness
    @State private var geofenceRadius: Double = 100
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    // MARK: - Main View
    var body: some View {
            NavigationView {
                Group {
                    if isCustomLocationMode {
                        customLocationView
                    } else {
                        nearbyGymsView
                    }
                }
                .navigationTitle(isCustomLocationMode ? "Mark Gym Location" : "Select Gym")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(leading: backButton)
            }
            .alert("Success", isPresented: $showSuccessMessage) {
                Button("OK") {
                    showSuccessMessage = false
                    dismiss() // Explicitly dismiss only on success
                }
            }
        }
    
    // MARK: - Nearby Gyms View
    private var nearbyGymsView: some View {
            VStack(spacing: 0) {
                searchBar
                    .padding()
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        customLocationButton
                        
                        if isLoading && nearbyGyms.isEmpty {
                            loadingView
                        } else if nearbyGyms.isEmpty {
                            emptyStateView
                        } else {
                            gymsList
                        }
                    }
                }
            .navigationTitle("Select Gym")
            .onAppear { setupLocationAndSearch() }
            .alert("Success", isPresented: $showSuccessMessage) {
                Button("OK") { dismiss() }
            } message: {
                Text("Gym location has been saved successfully!")
            }
        }
    }
    
    // MARK: - Custom Location View
    private var customLocationView: some View {
            ZStack {
                Map(coordinateRegion: $region, showsUserLocation: true)
                
                // Center Pin
                VStack(spacing: 0) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                        .background(Color.white.clipShape(Circle()))
                        .shadow(radius: 2)
                    
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .offset(y: -5)
                }
                
                // Add Button
                VStack {
                    Spacer()
                    Button("Save Custom Location") {
                        showingGymDetailsSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            .sheet(isPresented: $showingGymDetailsSheet) {
                gymDetailsSheet
            }
            .onAppear {
                if let location = gymService.currentLocation {
                    region.center = location
            }
        }
    }
    private var backButton: some View {
            Button("Back") {
                isCustomLocationMode = false
            }
        }
    
    // MARK: - Components
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search for gyms", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: searchText) { _ in
                    Task {
                        resetSearch()
                        await performSearch()
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    Task {
                        resetSearch()
                        await performSearch()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Finding gyms nearby...")
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash.circle")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Gyms Found Nearby")
                .font(.headline)
            
            if searchText.isEmpty {
                Text("Try moving to a different location or add a custom gym")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("Try a different search term")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private var customLocationButton: some View {
        Button(action: {
            isCustomLocationMode = true
        }) {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                Text("Mark Custom Location")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(10)
        }
        .padding(.horizontal)
    }
    
    private var gymsList: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(nearbyGyms) { gym in
                GymListItem(gym: gym) {
                    saveSelectedGym(gym)
                }
                .onAppear {
                    if gym == nearbyGyms.last && hasMoreResults {
                        Task {
                            await loadMore()
                        }
                    }
                }
                Divider()
            }
            
            if isLoading && !nearbyGyms.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding(.horizontal)
    }
    
    private var gymDetailsSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Gym Details")) {
                    TextField("Gym Name", text: $gymName)
                    Picker("Gym Type", selection: $selectedGymType) {
                        ForEach(GymType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Geofence Settings")) {
                    VStack(alignment: .leading) {
                        Text("Radius: \(Int(geofenceRadius))m")
                        Slider(value: $geofenceRadius, in: 50...500, step: 10)
                    }
                }
            }
            .navigationTitle("Add New Gym")
            .navigationBarItems(
                leading: Button("Cancel") { showingGymDetailsSheet = false },
                trailing: Button("Save") { saveCustomGym() }
                    .disabled(gymName.isEmpty)
            )
        }
    }
    
    // MARK: - Helper Methods
    private func setupLocationAndSearch() {
        gymService.requestLocationPermission()
        Task {
            await performSearch()
        }
    }
    
    private func resetSearch() {
        currentPage = 1
        hasMoreResults = true
        nearbyGyms = []
    }
    
    
    
    private func saveSelectedGym(_ gym: NearbyGym) {
            let gymDetails = GymDetails(
                id: gym.id,
                name: gym.name,
                type: gym.type ?? .fitness,
                latitude: gym.coordinate.latitude,
                longitude: gym.coordinate.longitude,
                address: gym.address,
                geofenceRadius: 100,
                visits: []  // Initialize with empty visits array
            )
            gymService.saveGymLocation(gymDetails)
            showSuccessMessage = true
        }

    private func performSearch() async {
            isLoading = true
            do {
                let newGyms = try await gymService.fetchNearbyGyms(searchText: searchText, page: currentPage)
                await MainActor.run {
                    nearbyGyms = newGyms
                    hasMoreResults = !newGyms.isEmpty
                }
            } catch {
                await MainActor.run {
                    errorHandler.handle(error)
                }
            }
            await MainActor.run {
                isLoading = false
            }
        }
        
    private func loadMore() async {
            guard !isLoading else { return }
            
            await MainActor.run {
                currentPage += 1
                isLoading = true
            }
            
            do {
                let newGyms = try await gymService.fetchNearbyGyms(searchText: searchText, page: currentPage)
                await MainActor.run {
                    nearbyGyms.append(contentsOf: newGyms)
                    hasMoreResults = !newGyms.isEmpty
                }
            } catch {
                await MainActor.run {
                    errorHandler.handle(error)
                    currentPage -= 1
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    
    private func saveCustomGym() {
            let newGym = GymDetails(
                id: UUID(),
                name: gymName,
                type: selectedGymType,
                latitude: region.center.latitude,
                longitude: region.center.longitude,
                address: "Custom Location",
                geofenceRadius: geofenceRadius,
                visits: []  // Initialize with empty visits array
            )
            gymService.saveGymLocation(newGym)
            showingGymDetailsSheet = false
            showSuccessMessage = true
            isCustomLocationMode = false
    }
}

// MARK: - GymListItem Component
struct GymListItem: View {
    let gym: NearbyGym
    let onSelect: () -> Void
    @State private var showingConfirmation = false
    
    var body: some View {
        Button(action: {
            showingConfirmation = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
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
                
                if let type = gym.type {
                    Text(type.rawValue)
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Add Gym", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Add") {
                onSelect()
            }
        } message: {
            Text("Would you like to add \(gym.name) to your profile?")
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return String(format: "%.0f m away", distance)
        } else {
            return String(format: "%.1f km away", distance / 1000)
        }
    }
}
