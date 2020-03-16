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

    //A more efficient way of fetching data to avoid performace issues later
    lazy var fetchResultesController: NSFetchedResultsController<Task> = {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        //While fetching the data we will sort it in the priority they're in
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: true), NSSortDescriptor(key: "name", ascending: true)]
        let context = CoreDataStack.shared.mainContext
        
        //Create the fetch request controller
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: "priority", cacheName: nil)
        
        frc.delegate = self
        try? frc.performFetch()
        return frc
    }()
    
    //Initialize TaskController to get data sync
    let taskController = TaskController()
    
    //MARK: - Actions
    //Let user fetch data whenever they want by pulling down the tableView
    
    @IBAction func refresh(_ sender: Any){
        
        //When pulling down it will start fetching and then when done it runs
        //the code inside the closure in this case end refreshing
        //so the loading animation should end
        
        taskController.fetchTaskFromServer { _ in
            
            DispatchQueue.main.async {
                 self.refreshControl?.endRefreshing()
            }
           
 
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return fetchResultesController.sections?.count ?? 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       
        return fetchResultesController.sections?[section].numberOfObjects ?? 0
    }
    
    //Use to set heigh and prevent warning
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44.0
    }

 
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as? TaskCell else { return UITableViewCell() }

        // Configure the cell...
        //Object is like row but because it can be use with collection views is call object
        cell.task = fetchResultesController.object(at: indexPath)
        
        return cell
    }
 
    //THis will name each of the sections
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionInfo = fetchResultesController.sections?[section] else {
            return nil
        }
        return sectionInfo.name.capitalized
    }

 
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let task = fetchResultesController.object(at: indexPath)
            
            //First delete from firebase and only if succeeds the
            //completion will run to delete from CoreData
            //If there is an error deleting from FB then it also
            //wont be delete it from CD to keep in sync
            taskController.deleteTaskFromServer(task: task) { (error) in
                if let error = error {
                    NSLog("Error deleting task from firebase: \(error)")
                    return
                }
                
                //Must be done on main queu
                DispatchQueue.main.async {
                    
                    //Here we delete the specific task/entry
                    CoreDataStack.shared.mainContext.delete(task)
                    
                    //Save changes
                    do{
                        try CoreDataStack.shared.save()
                    }catch{
                        //if for some reason it could not be deleted reset it to original state
                        CoreDataStack.shared.mainContext.reset()
                        NSLog("Error saving managed Object: \(error)")
                    }
                }
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
                    detailVC.task = fetchResultesController.object(at: indexPath)
                    detailVC.taskController = taskController
                }
            }
        }else if segue.identifier == "NewTaskModelSegue"{
            
            //Since there is a navigationController in between this viewControllers
            //We must do as follow to downcast both
            if let navC = segue.destination as? UINavigationController, let detailVC = navC.viewControllers[0] as? TaskDetailViewController {
                
                detailVC.taskController = taskController
            }
        }
    }
}

//MARK: - TasksTableViewController


extension TasksTableViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //When a change is detected we begin updates
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //when we finish with changes we end updates
        tableView.endUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        //Add or remove entire sections from the view
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
         case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        //moving inserting or deleting multiple rows
        
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .update:
            guard let indexPath = indexPath else { return }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        case .move:
            guard let oldIndexPath = indexPath, let newIndexPath = newIndexPath else { return }
            tableView.deleteRows(at: [oldIndexPath], with: .automatic)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        @unknown default:
            break
        }
    }
}
