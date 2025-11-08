//
//  SceneTag+CoreDataProperties.swift
//  AI Cleaner
//
//  Core Data properties for SceneTag entity
//

import Foundation
import CoreData

extension SceneTag {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SceneTag> {
        return NSFetchRequest<SceneTag>(entityName: "SceneTag")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var assetId: String?
    @NSManaged public var label: String?
    @NSManaged public var confidence: Float
    @NSManaged public var updatedAt: Date?
}

extension SceneTag : Identifiable {

}
