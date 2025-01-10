//
//  GymSearchModels.swift
//  GoGym
//
//  Created by Anoop Vijayan on 10.01.25.
//

import Foundation
import CoreLocation
import MapKit

extension NearbyGym {
    static func from(_ mapItem: MKMapItem, distance: CLLocationDistance) -> NearbyGym {
        NearbyGym(
            id: UUID(),
            name: mapItem.name ?? "Unknown Gym",
            coordinate: mapItem.placemark.coordinate,
            address: formatAddress(from: mapItem.placemark),
            distance: distance,
            type: determineGymType(from: mapItem)
        )
    }
    
    private static func formatAddress(from placemark: MKPlacemark) -> String {
        [
            placemark.subThoroughfare,
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea
        ]
        .compactMap { $0 }
        .joined(separator: " ")
    }
    
    private static func determineGymType(from item: MKMapItem) -> GymType {
        let lowercasedName = item.name?.lowercased() ?? ""
        if lowercasedName.contains("crossfit") {
            return .crossfit
        } else if lowercasedName.contains("yoga") {
            return .yoga
        } else if lowercasedName.contains("martial") || lowercasedName.contains("karate") || lowercasedName.contains("jiu") {
            return .martialArts
        } else {
            return .fitness
        }
    }
}
