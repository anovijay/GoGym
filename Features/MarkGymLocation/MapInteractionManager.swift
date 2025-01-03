//
//  MapInteractionManager.swift
//  GoGym
//
//  Created by [Your Name] on [Date].
//

import MapKit
import UIKit

class MapInteractionManager: NSObject, MKMapViewDelegate {
    // Callbacks for interaction results
    var onLocationSelected: ((CLLocationCoordinate2D) -> Void)?
    var onRegionUpdated: ((MKCoordinateRegion) -> Void)?

    private var mapView: MKMapView?
    
    init(mapView: MKMapView) {
        super.init()
        self.mapView = mapView
        self.mapView?.delegate = self
        setupGestureRecognizers()
    }
    
    // MARK: - Gesture Handling
    private func setupGestureRecognizers() {
        guard let mapView = mapView else { return }
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        mapView.addGestureRecognizer(longPressGesture)
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let mapView = mapView else { return }
        let locationInView = gesture.location(in: mapView)
        let coordinate = mapView.convert(locationInView, toCoordinateFrom: mapView)
        onLocationSelected?(coordinate)
    }
    
    // MARK: - Overlay Management
    func addGeofenceOverlay(center: CLLocationCoordinate2D, radius: Double) {
        guard let mapView = mapView else { return }
        mapView.removeOverlays(mapView.overlays) // Clear existing overlays
        let circle = MKCircle(center: center, radius: radius)
        mapView.addOverlay(circle)
    }

    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circleOverlay = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circleOverlay)
            renderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 2
            return renderer
        }
        return MKOverlayRenderer()
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let updatedRegion = mapView.region
        onRegionUpdated?(updatedRegion)
    }
}
