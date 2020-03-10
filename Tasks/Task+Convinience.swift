//
//  Task+Convinience.swift
//  Tasks
//
//  Created by FGT MAC on 3/10/20.
//  Copyright © 2020 FGT MAC. All rights reserved.
//

import Foundation
import CoreData

extension Task{
    convenience init(name: String, notes: String? = nil, context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        self.init(context: context)
        self.name = name
        self.notes = notes
    }
}
