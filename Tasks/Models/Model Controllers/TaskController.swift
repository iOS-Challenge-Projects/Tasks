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
    func fetchTaskFromServer(completion: @escaping CompletionHandler = { _ in }) {
        
        
        let requestURL = baseURL.appendingPathExtension("json")
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            
            if let error = error {
                NSLog("Error Fetching tasks from firebase: \(error)")
                completion(error)
                return
            }
            
            
            guard let data = data else {
                NSLog("No data found in firebase")
                completion(NSError())
                return
            }
            
            
            do{
                //Create an array of values from firebase because of the way firebase
                //returns the data needs to be formated
                let taskRepresentations = Array(try JSONDecoder().decode([String: TaskRepresentation].self, from: data).values)
                
                //Convert into NSManageObjects and store it in CoreData
                try self.updateTasks(with: taskRepresentations)
//                 for representation in taskRepresentations {
//                     Task(taskRepresentation: representation)
//                 }
                completion(nil)

            }catch{
                NSLog("Error Decoding task rep from firebase: \(error)")
                completion(NSError())
            }
            
        }.resume()
    }
    
    //When creating a new task we send it to FB here (and we already created the method to save to CD
    func sendTasksToServer(task: Task, completion: @escaping CompletionHandler = { _ in }) {
        //if the task does not have a UUID already create one
        let uuid = task.identifier ?? UUID()
        
        //append the uui and "json" to the end of the URL as require by firebase
        let requestURL = baseURL.appendingPathComponent(uuid.uuidString).appendingPathComponent("json")
        
        var request = URLRequest(url: requestURL)
        
        //We use put which will update existing entries but if a match is not found then we create a new one
        request.httpMethod = "PUT"
        
        do {
            guard var representation = task.taskRepresentation else {
                completion(NSError())
                return
            }
            //ensure the manage object and FB has the same uuid
            representation.identifier = uuid.uuidString
            task.identifier = uuid
            //instead of using the mainContext save method we use our own
            //if we dont pass an argument then it defaults to the mainContext
            //try CoreDataStack.shared.mainContext.save()
            try CoreDataStack.shared.save()
            
            request.httpBody = try JSONEncoder().encode(representation)
        } catch {
            NSLog("Error encoding task to FB: \(error)")
            completion(error)
            return
        }
        
        URLSession.shared.dataTask(with: request) {data, _, error in
            if let error = error {
                NSLog("Error PUTing task to server: \(error)")
                completion(error)
                return
            }
            //if everything worked just pass nil to completion
            completion(nil)
            
        }.resume()
    }
    
    
    func deleteTaskFromServer(task: Task, completion: @escaping CompletionHandler =  {_ in })  {
        guard let uuid = task.identifier else {
            completion(NSError())
            return
        }
        
        let requestURL = baseURL.appendingPathComponent(uuid.uuidString).appendingPathComponent("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request){data, response, error in
            
            print(response!)
            
            completion(error)
            
        }.resume()
    }
    
    //MARK: - Private
    
    private func updateTasks(with representations: [TaskRepresentation]) throws {
        
        //Check if all task has UUID's
        let taskWithID = representations.filter { $0.identifier != nil }
        //Get the UUID's compactMap is like map but remove any nils
        let identitiesToFetch = taskWithID.compactMap { UUID(uuidString: $0.identifier!) }
        //Create collection which has the UUID as the key and values are taskRepresentationObjects
        let representationByID = Dictionary(uniqueKeysWithValues: zip(identitiesToFetch, taskWithID))
        var taskToCreate = representationByID
        
        //1.Fetch all tasks from coredata
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        //Here we are filtering, we compare CD with FB to see if is in sync
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identitiesToFetch)
        
        //1. Create Singleton to get a new background context
        let newBGContext = CoreDataStack.shared.container.newBackgroundContext()
        
        //2.wrap the entire "do" block in a performAndWait
        newBGContext.performAndWait {
            
            
            do{
                let existingTasks = try newBGContext.fetch(fetchRequest)
                //2.Match the managedTask with the FireBase tasks
                //iterate over the CD tasks
                for task in existingTasks {
                    
                    guard let id = task.identifier, let representation = representationByID[id] else { continue }
                    self.update(task: task, with: representation)
                    //remove all the task that match on both side so only whats new is left to sync and prevent duplicates
                    taskToCreate.removeValue(forKey: id)
                    
                }
                
                //4.For none match / new tasks from FB create a CD manage object
                for representation in taskToCreate.values {
                    Task(taskRepresentation: representation, context: newBGContext)
                }
                
            } catch {
                NSLog("Error fetching data: \(error)")
            }
            
            
        }
        
        //5. Save all this in CoreData with the BGContext created above
        try CoreDataStack.shared.save(context: newBGContext)
    }
    
    //MARK: - Private
    
    //3.When match decide who wins and update to be in sync (FB always wins)
    private func update(task: Task, with representation: TaskRepresentation){
        task.name = representation.name
        task.notes = representation.notes
        task.priority = representation.priority
        task.completed = representation.completed ?? false
        
        
    }
}
