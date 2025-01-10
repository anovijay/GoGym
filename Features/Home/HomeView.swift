// HomeView.swift
import SwiftUI

struct HomeView: View {
    @ObservedObject var authState: AuthStateManager
    @EnvironmentObject private var errorHandler: AppErrorHandler
    @StateObject private var visitTracker = GymVisitTrackingService()
    
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
            .onAppear {
                loadGyms()
                visitTracker.requestPermissions()
                savedGyms.forEach { visitTracker.startMonitoring($0) }
            }
            .onReceive(NotificationCenter.default.publisher(for: .gymLocationUpdated)) { _ in
                        loadGyms()  // This will reload gyms when notification is received
                    }
            .onReceive(NotificationCenter.default.publisher(for: .gymVisitStarted)) { notification in
                if let visit = notification.userInfo?["visit"] as? GymVisit {
                    VisitStorageManager.saveVisit(visit)
                    loadGyms()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .gymVisitEnded)) { notification in
                if let visit = notification.userInfo?["visit"] as? GymVisit {
                    VisitStorageManager.updateVisit(visit)
                    loadGyms()
                }
            }
            .refreshable {
                loadGyms()
            }
            .onAppear {
                        loadGyms()
                        visitTracker.requestPermissions()
                        savedGyms.forEach { visitTracker.startMonitoring($0) }
                    }
                    // Add these handlers
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                        visitTracker.restartMonitoring()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                        // Ensure we have background location permission
                        visitTracker.requestPermissions()
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
        visitTracker.stopMonitoring(gym)
        loadGyms()
    }
}
