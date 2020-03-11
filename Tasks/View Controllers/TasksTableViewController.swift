//
//  TasksTableViewController.swift
//  Tasks
//
//  Created by FGT MAC on 3/9/20.
//  Copyright © 2020 FGT MAC. All rights reserved.
//

import UIKit
import CoreData

class TasksTableViewController: UITableViewController {

    var tasks: [Task]{
        //Fetch request to comunicate wit the DB
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        
        do{
            return try CoreDataStack.shared.mainContext.fetch(fetchRequest)
        }catch{
            NSLog("Error fetching tasks: \(error)")
            return []
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //Realod data
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        return tasks.count
    }

 
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)

        // Configure the cell...
        cell.textLabel?.text = tasks[indexPath.row].name
        
        return cell
    }
 

 
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let task = tasks[indexPath.row]
            
            //Here we delete the specific task/entry
            CoreDataStack.shared.mainContext.delete(task)
            
            //Save changes
            do{
                try CoreDataStack.shared.mainContext.save()
                //if the deletion from CoreData was successfully removed and saved then remove it from table view
                tableView.deleteRows(at: [indexPath], with: .fade)
            }catch{
                //if for some reason it could not be deleted reset it to original state
                CoreDataStack.shared.mainContext.reset()
                NSLog("Error saving managed Object: \(error)")
            }
            
            
        }
    }
 

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "ShowTaskDetailSegue" {
            //Downcast destination
            if let detailVC = segue.destination as? TaskDetailViewController {
                //get index
                if let indexPath = tableView.indexPathForSelectedRow{
                    //pass selected row to detail view
                    detailVC.task = tasks[indexPath.row]
                }
            }
        }else if segue.identifier == "NewTaskModelSegue"{
            
        }
    }
 

}
