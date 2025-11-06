//
//  AssetFingerprint+CoreDataProperties.swift
//  AI Cleaner
//
//  Core Data entity properties for AssetFingerprint
//

import Foundation
import CoreData

extension AssetFingerprint {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AssetFingerprint> {
        return NSFetchRequest<AssetFingerprint>(entityName: "AssetFingerprint")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var assetLocalId: String?
    @NSManaged public var vectorData: Data?
    @NSManaged public var vectorElementCount: Int32  // NEW: Store actual element count
    @NSManaged public var blurScore: Float
    @NSManaged public var brightnessScore: Float
    @NSManaged public var isScreenshot: Bool
    @NSManaged public var updatedAt: Date?

}

extension AssetFingerprint : Identifiable {

}
