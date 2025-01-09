// NearbyGymsListView.swift
import SwiftUI

struct NearbyGymsListView: View {
    @ObservedObject var gymService: GymLocationService
    @EnvironmentObject private var errorHandler: AppErrorHandler
    @Binding var selectedGym: GymDetails?
    @Binding var isPresented: Bool
    
    @State private var nearbyGyms: [NearbyGym] = []
    @State private var isLoading = false
    
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
            .task {
                await loadNearbyGyms()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "mappin.slash.circle")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Gyms Found Nearby")
                .font(.headline)
            
            Button("Try Again") {
                Task {
                    await loadNearbyGyms()
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
    
    private func loadNearbyGyms() async {
        isLoading = true
        do {
            nearbyGyms = try await gymService.fetchNearbyGyms()
        } catch {
            errorHandler.handle(error)
        }
        isLoading = false
    }
    
    private func selectGym(_ gym: NearbyGym) {
            selectedGym = GymDetails(
                id: gym.id,
                name: gym.name,
                type: .fitness, // default; adjust as needed
                latitude: gym.coordinate.latitude,
                longitude: gym.coordinate.longitude,
                address: gym.address,
                geofenceRadius: 100,
                visits: []  // Initialize with empty visits array
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
