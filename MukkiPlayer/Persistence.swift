//
//  Persistence.swift
//  MukkiPlayer
//
//  Created by Tobias Schelling on 02.01.26.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        // Create 9 empty tiles for preview
        for i in 0..<9 {
            let tile = TileConfig(context: viewContext)
            tile.id = UUID()
            tile.position = Int16(i)
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MukkiPlayer")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Initialize tiles if needed
        initializeTilesIfNeeded()
    }
    
    private func initializeTilesIfNeeded() {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<TileConfig> = TileConfig.fetchRequest()
        
        do {
            let count = try context.count(for: fetchRequest)
            if count == 0 {
                // Create 9 tiles
                for i in 0..<9 {
                    let tile = TileConfig(context: context)
                    tile.id = UUID()
                    tile.position = Int16(i)
                }
                try context.save()
            }
        } catch {
            print("Error initializing tiles: \(error)")
        }
    }
    
    func getTile(at position: Int) -> TileConfig? {
        let context = container.viewContext
        let fetchRequest: NSFetchRequest<TileConfig> = TileConfig.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "position == %d", position)
        fetchRequest.fetchLimit = 1
        
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("Error fetching tile: \(error)")
            return nil
        }
    }
    
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
}
