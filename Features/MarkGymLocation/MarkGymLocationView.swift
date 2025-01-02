import SwiftUI

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

                VStack {
                    Spacer()
                    if viewModel.selectedGymLocation == nil {
                        Text("Tap or long press on the map to select your gym location.")
                            .padding()
                            .background(Material.regular)
                            .cornerRadius(8)
                            .shadow(radius: 5)
                            .padding()
                    } else {
                        controlsOverlay
                    }
                }
            }
            .alert("Location Services Disabled", isPresented: $viewModel.showLocationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enable location services for accurate tracking.")
            }
            .alert("Error", isPresented: .constant(viewModel.saveError != nil)) {
                Button("OK", role: .cancel) { viewModel.saveError = nil }
            } message: {
                Text(viewModel.saveError ?? "Unknown error")
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Mark Gym Location")
                        .font(.headline)
                }
            }
        }
    }

    private var controlsOverlay: some View {
        VStack(spacing: 16) {
            Text("Adjust Geofence Radius: \(Int(viewModel.geofenceRadius)) meters")
                .font(.headline)

            Slider(value: $viewModel.geofenceRadius, in: 50...1000, step: 10)
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
