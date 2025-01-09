// GymLocationModels.swift
import Foundation
import CoreLocation
import MapKit

// MARK: - Notifications
extension Notification.Name {
    static let gymLocationUpdated = Notification.Name("gymLocationUpdated")
}

// MARK: - Models
enum GymType: String, CaseIterable, Codable {
    case fitness = "Fitness Center"
    case crossfit = "CrossFit"
    case yoga = "Yoga Studio"
    case martialArts = "Martial Arts"
    case other = "Other"
}

enum LocationError: Error {
    case locationNotAvailable
    case searchFailed
    case permissionDenied
    
    var localizedDescription: String {
        switch self {
        case .locationNotAvailable:
            return "Location not available. Please enable location services."
        case .searchFailed:
            return "Failed to search for nearby gyms."
        case .permissionDenied:
            return "Location access is required to find nearby gyms. Please enable location services in Settings."
        }
    }
}

struct GymAnnotation: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let title: String
}

struct NearbyGym: Identifiable, Equatable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    let address: String
    let distance: Double?
    let type: GymType?
    
    // Implement Equatable
    static func == (lhs: NearbyGym, rhs: NearbyGym) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.address == rhs.address &&
        lhs.distance == rhs.distance &&
        lhs.type == rhs.type
    }
}

// GymLocationModels.swift updates

struct GymDetails: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let type: GymType
    let latitude: Double
    let longitude: Double
    let address: String
    let geofenceRadius: Double
    var visits: [Date]  // Add this to track visits
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var annotation: GymAnnotation {
        GymAnnotation(id: id, coordinate: coordinate, title: name)
    }
    
    var visitsThisWeek: Int {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return visits.filter { $0 >= oneWeekAgo }.count
    }
}
