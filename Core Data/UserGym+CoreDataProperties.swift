//
//  UserGym+CoreDataProperties.swift
//  GoGym
//
//  Created by Anoop Vijayan on 08.01.25.
//
//

import Foundation
import CoreData


extension UserGym {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserGym> {
        return NSFetchRequest<UserGym>(entityName: "UserGym")
    }

    @NSManaged public var toUser: User?
    @NSManaged public var toGym: Gym?

}

extension UserGym : Identifiable {

}
