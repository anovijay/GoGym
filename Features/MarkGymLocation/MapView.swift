//
//  MapView.swift
//  GoGym
//
//  Created by Anoop Vijayan on 02.01.25.
//
import SwiftUI
import MapKit
import CoreLocation
import os

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedGymLocation: CLLocationCoordinate2D?
    @Binding var geofenceRadius: Double

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress))
        mapView.addGestureRecognizer(longPressGesture)
        mapView.setRegion(region, animated: true)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)

        // Remove existing overlays
        uiView.removeOverlays(uiView.overlays)

        // Add a circle overlay for the geofence
        if let location = selectedGymLocation {
            let circle = MKCircle(center: location, radius: geofenceRadius)
            uiView.addOverlay(circle)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, selectedGymLocation: $selectedGymLocation)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        @Binding var selectedGymLocation: CLLocationCoordinate2D?

        init(_ parent: MapView, selectedGymLocation: Binding<CLLocationCoordinate2D?>) {
            self.parent = parent
            self._selectedGymLocation = selectedGymLocation
        }

        @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
            guard gestureRecognizer.state == .began else { return }
            let locationInView = gestureRecognizer.location(in: gestureRecognizer.view)
            let mapView = gestureRecognizer.view as! MKMapView
            let coordinate = mapView.convert(locationInView, toCoordinateFrom: mapView)

            // Set the selected location
            selectedGymLocation = coordinate
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let circleOverlay = overlay as? MKCircle {
                let circleRenderer = MKCircleRenderer(circle: circleOverlay)
                circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
                circleRenderer.strokeColor = UIColor.blue
                circleRenderer.lineWidth = 1
                return circleRenderer
            }
            return MKOverlayRenderer()
        }
    }
}
