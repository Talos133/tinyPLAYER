import SwiftUI
import CoreData

@main
struct tinyPLAYERApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        // The actual window is owned by AppDelegate via FloatingPanel (NSPanel).
        // A Settings scene is required to satisfy the SwiftUI App protocol on macOS.
        Settings { EmptyView() }
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
