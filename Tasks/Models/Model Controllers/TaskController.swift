//
//  TaskController.swift
//  Tasks
//
//  Created by FGT MAC on 3/14/20.
//  Copyright © 2020 FGT MAC. All rights reserved.
//

import Foundation
import CoreData

class TaskController {
    
    //MARK: - Properties
    //Firebase server base URL
    let baseURL = URL(string: "https://tasks-3f211.firebaseio.com/")!
    
    //Type Alias defines an alternate type to make it simpler to use
    // instead of calling "(Error?) -> Void" we call CompletionHandler
    //is like a var for types
    typealias CompletionHandler = (Error?) -> Void
    
    init(){
        fetchTaskFromServer()
    }
    
    //MARK: - fetchTaskFromServer
    
    //create a fetchTaskFromServer
    //{_ in} means a empty closure
    func fetchTaskFromServer(completion: @escaping CompletionHandler = {_ in}){
        let requestURL = baseURL.appendingPathExtension("json")
        
        URLSession.shared.dataTask(with: requestURL){(data, _, error) in
            if let error = error {
                NSLog("Error Fetching tasks from firebase: \(error)")
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(NSError())
                return
            }
            
            
            do{
                //Create an array of values from firebase because of the way firebase
                //returns the data needs to be formated
                let taskRepresentations = try Array(JSONDecoder().decode([String: TaskRepresentation].self, from: data).values)
                
                //Convert into NSManageObjects and store it in CoreData
                try self.updateTasks(with: taskRepresentations)
            }catch{
                NSLog("Error Fetching tasks from firebase: \(error)")
            }
        }
    }
    
    //MARK: - Private
    
    private func updateTasks(with representations: [TaskRepresentation]) throws {
       
        //Check if all task has UUID's
        let taskWithID = representations.filter { $0.identifier != nil }
        //Get the UUID's compactMap is like map but remove any nils
        let identidiesToFetch = taskWithID.compactMap { UUID(uuidString: $0.identifier!)}
        //Create collection which has the UUID as the key and values are taskRepresentationObjects
        let representationByID = Dictionary(uniqueKeysWithValues: zip(identidiesToFetch, taskWithID))
        var taskToCreate = representationByID
        
        //1.Fetch all tasks from coredata
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        //Here we are filtering, we compare CD with FB to see if is in sync
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identidiesToFetch)
        
        do{
            let existingTasks = try CoreDataStack.shared.mainContext.fetch(fetchRequest)
            
             //2.Match the managedTask with the FireBase tasks
            //iterate over the CD tasks
            for task in existingTasks {
                guard let id = task.identifier, let representation = representationByID[id] else { continue }
                self.update(task: task, with: representation)
                //remove all the task that match on both side so only whats new is left to sync and prevent duplicates
                taskToCreate.removeValue(forKey: id)
                
                //4.For none match / new tasks from FB create a CD manage object
                for representation in taskToCreate.values {
                    Task(taskRepresentation: representation)
                }
                
            }
            
        } catch {
            NSLog("Error fetching data: \(error)")
        }
        
        //5. Save all this in CoreData
        
    }
    
    //MARK: - Private
    
    //3.When match decide who wins and update to be in sync (FB always wins)
    private func update(task: Task, with representation: TaskRepresentation){
        task.name = representation.name
        task.notes = representation.notes
        task.completed = representation.completed
        task.priority = representation.priority
        
    }
}
