//
//  Gym+CoreDataProperties.swift
//  GoGym
//
//  Created by Anoop Vijayan on 08.01.25.
//
//

import Foundation
import CoreData


extension Gym {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Gym> {
        return NSFetchRequest<Gym>(entityName: "Gym")
    }

    @NSManaged public var gymId: UUID?
    @NSManaged public var gymName: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var gymType: String?
    @NSManaged public var toUserGym: NSSet?
    @NSManaged public var toAttendance: Gym?

}

// MARK: Generated accessors for toUserGym
extension Gym {

    @objc(addToUserGymObject:)
    @NSManaged public func addToToUserGym(_ value: UserGym)

    @objc(removeToUserGymObject:)
    @NSManaged public func removeFromToUserGym(_ value: UserGym)

    @objc(addToUserGym:)
    @NSManaged public func addToToUserGym(_ values: NSSet)

    @objc(removeToUserGym:)
    @NSManaged public func removeFromToUserGym(_ values: NSSet)

}

extension Gym : Identifiable {

}
