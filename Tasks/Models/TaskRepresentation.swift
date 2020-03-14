//
//  TaskRepresentation.swift
//  Tasks
//
//  Created by FGT MAC on 3/14/20.
//  Copyright © 2020 FGT MAC. All rights reserved.
//

import Foundation

//DataModel for FireBase 
struct TaskRepresentation: Codable {
    var name: String
    var notes: String?
    var priority: String
    var identifier: String?
    var completed: Bool?
}
