//
//  ScanSession+CoreDataProperties.swift
//  AI Cleaner
//
//  Core Data entity properties for ScanSession
//

import Foundation
import CoreData

extension ScanSession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ScanSession> {
        return NSFetchRequest<ScanSession>(entityName: "ScanSession")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var startedAt: Date?
    @NSManaged public var finishedAt: Date?
    @NSManaged public var processedCount: Int32
    @NSManaged public var deletedCount: Int32
    @NSManaged public var freedBytes: Int64

}

extension ScanSession : Identifiable {

}
