import SwiftUI

struct HomeView: View {
    @ObservedObject var authState: AuthStateManager
    @EnvironmentObject private var errorHandler: AppErrorHandler
    @State private var savedGyms: [GymDetails] = []
    @State private var errorMessage: String?
    @State private var showingGymSheet = false
    @State private var gymToDelete: GymDetails?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    HomeHeroSection(
                        visitCount: savedGyms.reduce(0) { $0 + $1.visitsThisWeek },
                        lastVisit: savedGyms.compactMap { $0.visits.last }.max()
                    )
                    
                    if savedGyms.isEmpty {
                        EmptyStateView(onAddGym: {
                            showingGymSheet = true
                        })
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(savedGyms) { gym in
                                GymCard(gym: gym) {
                                    gymToDelete = gym
                                    showingDeleteAlert = true
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Your Gyms")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingGymSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingGymSheet) {
                MarkGymLocationView(isPresented: $showingGymSheet)
            }
            .alert("Remove Gym", isPresented: $showingDeleteAlert, presenting: gymToDelete) { gym in
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive) {
                    deleteGym(gym)
                }
            } message: { gym in
                Text("Are you sure you want to remove \(gym.name)?")
            }
            .refreshable {
                loadGyms()
            }
            .onAppear {
                loadGyms()
                NotificationCenter.default.addObserver(
                    forName: .gymLocationUpdated,
                    object: nil,
                    queue: .main
                ) { _ in
                    loadGyms()
                }
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(
                    self,
                    name: .gymLocationUpdated,
                    object: nil
                )
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
