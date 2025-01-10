// GymVisitModels.swift
import Foundation

struct GymVisit: Codable, Identifiable, Equatable {
    let id: UUID
    let gymId: UUID
    let startTime: Date
    var endTime: Date?
    
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    var isActive: Bool {
        return endTime == nil
    }
}

class VisitStorageManager {
    private static let visitsKey = "gym_visits"
    
    static func saveVisit(_ visit: GymVisit) {
        var visits = loadVisits()
        visits.append(visit)
        save(visits)
    }
    
    static func updateVisit(_ visit: GymVisit) {
        var visits = loadVisits()
        if let index = visits.firstIndex(where: { $0.id == visit.id }) {
            visits[index] = visit
            save(visits)
        }
    }
    
    static func loadVisits() -> [GymVisit] {
        guard let data = UserDefaults.standard.data(forKey: visitsKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([GymVisit].self, from: data)
        } catch {
            print("Error loading visits: \(error)")
            return []
        }
    }
    
    static func loadVisits(for gymId: UUID) -> [GymVisit] {
        return loadVisits().filter { $0.gymId == gymId }
    }
    
    private static func save(_ visits: [GymVisit]) {
        do {
            let data = try JSONEncoder().encode(visits)
            UserDefaults.standard.set(data, forKey: visitsKey)
        } catch {
            print("Error saving visits: \(error)")
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let gymVisitStarted = Notification.Name("gymVisitStarted")
    static let gymVisitEnded = Notification.Name("gymVisitEnded")
}
