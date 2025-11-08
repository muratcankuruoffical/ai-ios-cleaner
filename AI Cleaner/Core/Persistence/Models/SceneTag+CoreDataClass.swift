//
//  SceneTag+CoreDataClass.swift
//  AI Cleaner
//
//  Core Data entity class for SceneTag
//

import Foundation
import CoreData

@objc(SceneTag)
public class SceneTag: NSManagedObject {

    // MARK: - Factory Methods

    @discardableResult
    static func createOrUpdate(
        context: NSManagedObjectContext,
        assetId: String,
        label: String,
        confidence: Float
    ) -> SceneTag {
        // Check if tag already exists for this asset and label
        let fetchRequest: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "assetId == %@ AND label == %@", assetId, label)

        if let existingTag = try? context.fetch(fetchRequest).first {
            // Update existing tag
            existingTag.confidence = confidence
            existingTag.updatedAt = Date()
            return existingTag
        } else {
            // Create new tag
            let tag = SceneTag(context: context)
            tag.id = UUID()
            tag.assetId = assetId
            tag.label = label
            tag.confidence = confidence
            tag.updatedAt = Date()
            return tag
        }
    }

    // MARK: - Query Methods

    static func fetchTags(
        forAssetId assetId: String,
        context: NSManagedObjectContext
    ) -> [SceneTag] {
        let fetchRequest: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "assetId == %@", assetId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "confidence", ascending: false)]

        return (try? context.fetch(fetchRequest)) ?? []
    }

    static func searchAssets(
        byLabel label: String,
        minConfidence: Float = 0.5,
        context: NSManagedObjectContext
    ) -> [String] {
        let fetchRequest: NSFetchRequest<SceneTag> = SceneTag.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "label CONTAINS[cd] %@ AND confidence >= %f",
            label,
            minConfidence
        )
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "confidence", ascending: false)]

        let tags = (try? context.fetch(fetchRequest)) ?? []

        print("🔍 [SceneTag] Searching for label '\(label)' with confidence >= \(minConfidence)")
        print("   Found \(tags.count) tags")

        if !tags.isEmpty {
            // Show top 3 matches for debugging
            for tag in tags.prefix(3) {
                print("   - Asset: \(tag.assetId ?? "nil"), Label: \(tag.label ?? "nil"), Confidence: \(tag.confidence)")
            }
        }

        let assetIds = tags.map { $0.assetId ?? "" }.filter { !$0.isEmpty }
        let uniqueAssetIds = Array(Set(assetIds))
        print("   Unique assets: \(uniqueAssetIds.count)")

        return uniqueAssetIds
    }

    static func deleteAllTags(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = SceneTag.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            try context.save()
            print("✅ [SceneTag] All scene tags deleted")
        } catch {
            print("❌ [SceneTag] Failed to delete tags: \(error.localizedDescription)")
        }
    }
}
