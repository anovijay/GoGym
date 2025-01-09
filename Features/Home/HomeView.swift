import SwiftUI

struct HomeView: View {
    @ObservedObject var authState: AuthStateManager
    @EnvironmentObject private var errorHandler: AppErrorHandler
    @State private var savedGyms: [GymDetails] = []
    @State private var errorMessage: String?
    @State private var gymToDelete: GymDetails?
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Welcome section
                Text("Welcome, \(authState.displayName ?? "User")!")
                    .font(.largeTitle)
                    .padding()

                // Error Message
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                }

                // Saved Gyms List
                if savedGyms.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("No gyms have been added to your profile")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                } else {
                    List(savedGyms, id: \.id) { gym in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(gym.name)
                                .font(.headline)
                                .foregroundColor(.blue)

                            Text(gym.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                Text("Geofence Radius: \(Int(gym.geofenceRadius))m")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                
                                Spacer()
                                
                                Text("\(gym.visitsThisWeek) visits this week")
                                    .font(.caption)
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding(.vertical, 5)
                        .contentShape(Rectangle())
                        .onLongPressGesture {
                            gymToDelete = gym
                            showingDeleteAlert = true
                        }
                    }
                    .listStyle(PlainListStyle())
                }

                Spacer()
            }
            .alert("Remove Gym", isPresented: $showingDeleteAlert, presenting: gymToDelete) { gym in
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    deleteGym(gym)
                }
            } message: { gym in
                Text("Are you sure you want to remove \(gym.name) from your profile?")
            }
            .onAppear {
                loadGyms()
                NotificationCenter.default.addObserver(forName: .gymLocationUpdated, object: nil, queue: .main) { _ in
                    loadGyms()
                }
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self, name: .gymLocationUpdated, object: nil)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("GoGym")
                        .font(.headline)
                }
            }
        }
    }

    private func loadGyms() {
            let service = GymLocationService(errorHandler: errorHandler)
            savedGyms = service.loadSavedGyms()
        }
        
        private func deleteGym(_ gym: GymDetails) {
            let service = GymLocationService(errorHandler: errorHandler)
            service.deleteGymLocation(gym)
            loadGyms()
        }
}
