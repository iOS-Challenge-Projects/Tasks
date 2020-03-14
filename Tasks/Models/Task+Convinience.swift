//
//  Task+Convinience.swift
//  Tasks
//
//  Created by FGT MAC on 3/10/20.
//  Copyright © 2020 FGT MAC. All rights reserved.
//

import Foundation
import CoreData


//Since we cannot save an enum in coredata we
enum TaskPriority: String, CaseIterable {
    case low
    case normal
    case high
    case critical
}

extension Task{
    
    //1. This computed property allows any manage object to become a TaskRepresentation for sending to FireBase
    var taskRepresentation: TaskRepresentation? {
        guard let name = name, let priority = priority else { return nil }
        
        return TaskRepresentation(name: name, notes: notes, priority: priority, completed: completed, identifier: identifier?.uuidString)
    }
    
    //Creates a new manage object from rawdata ( CoreData )
    @discardableResult convenience init(name: String,
                     notes: String? = nil,
                     priority: TaskPriority = .normal,
                     completed: Bool = false,
                     identifier: UUID = UUID(),
                     context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        self.init(context: context)
        self.name = name
        self.notes = notes
        self.priority = priority.rawValue
        self.completed = completed
        self.identifier = identifier
    }
    
    //2.This creates a managed object from a TaskRepresentation from FireBase
    @discardableResult convenience init?(taskRepresentation: TaskRepresentation, context: NSManagedObjectContext = CoreDataStack.shared.mainContext){
        
        guard let priority = TaskPriority(rawValue: taskRepresentation.priority),
            let identifierString = taskRepresentation.identifier,
            let identifier = UUID(uuidString: identifierString)
            else { return nil }
        
        self.init(name: taskRepresentation.name,
                  notes: taskRepresentation.notes,
                  priority: priority,
                  completed: taskRepresentation.completed,
                  identifier: identifier,
                  context: context)
    }
}
