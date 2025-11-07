//
//  ActivityLog+CoreDataProperties.swift
//  AI Cleaner
//
//  Core Data entity properties for ActivityLog
//

import Foundation
import CoreData

extension ActivityLog {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ActivityLog> {
        return NSFetchRequest<ActivityLog>(entityName: "ActivityLog")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var itemCount: Int32
    @NSManaged public var freedBytes: Int64
    @NSManaged public var category: String?

}

extension ActivityLog: Identifiable {

}
