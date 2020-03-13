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
    convenience init(name: String,
                     notes: String? = nil,
                     priority: TaskPriority = .normal,
                     completed: Bool = false,
                     context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        self.init(context: context)
        self.name = name
        self.notes = notes
        self.priority = priority.rawValue
        self.completed = completed
    }
}
