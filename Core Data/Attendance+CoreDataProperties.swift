//
//  Attendance+CoreDataProperties.swift
//  GoGym
//
//  Created by Anoop Vijayan on 08.01.25.
//
//

import Foundation
import CoreData


extension Attendance {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Attendance> {
        return NSFetchRequest<Attendance>(entityName: "Attendance")
    }

    @NSManaged public var visitId: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var entryTime: String?
    @NSManaged public var exitTime: String?
    @NSManaged public var toUser: User?
    @NSManaged public var toGym: Gym?

}

extension Attendance : Identifiable {

}
