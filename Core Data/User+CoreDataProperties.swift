//
//  User+CoreDataProperties.swift
//  GoGym
//
//  Created by Anoop Vijayan on 08.01.25.
//
//

import Foundation
import CoreData


extension User {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User")
    }

    @NSManaged public var userId: UUID?
    @NSManaged public var name: String?
    @NSManaged public var emailId: String?
    @NSManaged public var isLoggedIn: Bool
    @NSManaged public var dateOfBirth: Date?
    @NSManaged public var createdOn: Date?
    @NSManaged public var toUserGym: NSSet?

}

// MARK: Generated accessors for toUserGym
extension User {

    @objc(addToUserGymObject:)
    @NSManaged public func addToToUserGym(_ value: UserGym)

    @objc(removeToUserGymObject:)
    @NSManaged public func removeFromToUserGym(_ value: UserGym)

    @objc(addToUserGym:)
    @NSManaged public func addToToUserGym(_ values: NSSet)

    @objc(removeToUserGym:)
    @NSManaged public func removeFromToUserGym(_ values: NSSet)

}

extension User : Identifiable {

}
