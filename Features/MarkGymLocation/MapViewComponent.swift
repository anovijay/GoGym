//
//  MapViewComponent.swift
//  GoGym
//
//  Created by Anoop Vijayan on 02.01.25.
//

import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedLocation: CLLocationCoordinate2D?
    let geofenceRadius: Double

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        context.coordinator.interactionManager = MapInteractionManager(mapView: mapView)
        context.coordinator.interactionManager?.onLocationSelected = { location in
            selectedLocation = location
        }
        context.coordinator.interactionManager?.onRegionUpdated = { updatedRegion in
            region = updatedRegion
        }
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        context.coordinator.interactionManager?.addGeofenceOverlay(center: selectedLocation ?? region.center, radius: geofenceRadius)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: MapViewRepresentable
        var interactionManager: MapInteractionManager?

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
    }
}
