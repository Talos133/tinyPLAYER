import SwiftUI
import CoreData

@main
struct tinyPLAYERApp: App {

    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            Text("tinyPLAYER")
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

// MARK: - Persistence Controller

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "tinyPLAYER")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
