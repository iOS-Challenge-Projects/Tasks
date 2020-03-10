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
        return container
    }()
    
    var mainContext: NSManagedObjectContext {
        return container.viewContext
    }
}
