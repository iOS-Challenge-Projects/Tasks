//
//  CoreDataStack.swift
//  Tasks
//
//  Created by FGT MAC on 3/9/20.
//  Copyright © 2020 FGT MAC. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    
    //This is a singleton which is a shared single session/instance of the class CoreDataStack
    static let shared = CoreDataStack()
    
    //Lazy means that the code will not run unlesss we need it or invoke it
    lazy var container: NSPersistentContainer = {
        
        //The name must match the data model name
        let container = NSPersistentContainer(name: "Tasks")
        
        container.loadPersistentStores { (_, error) in
            if let error = error {
                fatalError("Failed to load persistant stores: \(error)")
            }
        }
        
        //1.When the background context save to disk will merge it and let the view know to display changes
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    var mainContext: NSManagedObjectContext {
        return container.viewContext
    }
    
    //2. This will be how we save evrything in the app
    func save(context: NSManagedObjectContext = CoreDataStack.shared.mainContext) throws {
        var error: Error?
        
        //performAndWait = do the work and wait till is done (in the background thread)
        context.performAndWait {
            do{
                try context.save()
            }catch let saveError{
                error = saveError
            }
        }
        if let error = error { throw error }
    }
}
