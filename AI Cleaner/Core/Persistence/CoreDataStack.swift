//
//  CoreDataStack.swift
//  AI Cleaner
//
//  Core Data persistence layer
//

import Foundation
import CoreData

final class CoreDataStack {
    static let shared = CoreDataStack()

    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "AICleanerModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return container
    }()

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    func save(context: NSManagedObjectContext? = nil) {
        let ctx = context ?? viewContext
        guard ctx.hasChanges else {
            print("💾 [CoreDataStack] No changes to save")
            return
        }

        print("💾 [CoreDataStack] Saving context with changes...")
        do {
            try ctx.save()
            print("✅ [CoreDataStack] Context saved successfully")
        } catch {
            print("❌ [CoreDataStack] Save failed: \(error.localizedDescription)")
            // Save failed - data loss possible
        }
    }
}
