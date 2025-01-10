//
//  GymStorageService.swift
//  GoGym
//
//  Created by Anoop Vijayan on 10.01.25.
//

import Foundation
import CoreLocation

class GymStorageService {
    // MARK: - Private Properties
    private let errorHandler: ErrorHandling
    private let storageKey = "savedGyms"
    
    // MARK: - Initialization
    init(errorHandler: ErrorHandling) {
        self.errorHandler = errorHandler
    }
    
    // MARK: - Public Methods
    func saveGym(_ gym: GymDetails) {
        let savedGyms = loadSavedGyms()
        guard !isDuplicate(gym, among: savedGyms) else {
            errorHandler.handle("A gym already exists at this location")
            return
        }
        
        var updatedGyms = savedGyms
        updatedGyms.append(gym)
        
        do {
            let data = try JSONEncoder().encode(updatedGyms)
            UserDefaults.standard.set(data, forKey: storageKey)
            NotificationCenter.default.post(name: .gymLocationUpdated, object: nil)
        } catch {
            errorHandler.handle("Failed to save gym location: \(error.localizedDescription)")
        }
    }
    
    func deleteGym(_ gym: GymDetails) {
        var savedGyms = loadSavedGyms()
        savedGyms.removeAll { $0.id == gym.id }
        
        do {
            let data = try JSONEncoder().encode(savedGyms)
            UserDefaults.standard.set(data, forKey: storageKey)
            NotificationCenter.default.post(name: .gymLocationUpdated, object: nil)
        } catch {
            errorHandler.handle("Failed to delete gym location: \(error.localizedDescription)")
        }
    }
    
    func loadSavedGyms() -> [GymDetails] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([GymDetails].self, from: data)
        } catch {
            errorHandler.handle("Failed to load saved gyms: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Private Methods
    private func isDuplicate(_ gym: GymDetails, among savedGyms: [GymDetails]) -> Bool {
        savedGyms.contains { existingGym in
            let existingLocation = CLLocation(latitude: existingGym.latitude, longitude: existingGym.longitude)
            let newLocation = CLLocation(latitude: gym.latitude, longitude: gym.longitude)
            return existingLocation.distance(from: newLocation) <= 50
        }
    }
}
