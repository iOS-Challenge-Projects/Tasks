//
//  ViewController.swift
//  Tasks
//
//  Created by FGT MAC on 3/9/20.
//  Copyright © 2020 FGT MAC. All rights reserved.
//

import UIKit

class TaskDetailViewController: UIViewController {
    
    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var notesTextView: UITextView!
    
    //MARK: - Properties
    
    
    //This is a managed object from the Core Data Model
    var task: Task?

    
    //MARK: - View LifeCyle
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Clear field
        notesTextView.text = ""
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //If there is a "task" display data
        if let task = task {
            title = task.name
            nameTextField.text = task.name
            notesTextView.text = task.notes
        }else{
            //If no task was passed in, assume the user wants to create one
            //so add a button to the navbar to "save" the new task
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(save))
        }
        
    }
    
    //Here we save the changes when we go back to main screen / viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        
        //if there is a task = editing state
        if let task = task {
            guard let name = nameTextField.text, !name.isEmpty else { return }
             
             let notes = notesTextView.text
            
            task.name = name
            task.notes = notes
            
           saveTask()
        
        }
    }
    
    //Use @objc due to the way we call the func in the action navButton above
    @objc func save(){
        guard let name = nameTextField.text, !name.isEmpty else { return }
        
        let notes = notesTextView.text
       
        let _ = Task(name: name, notes: notes)
        
        saveTask()
        
        //Dismiss modal
        navigationController?.dismiss(animated: true, completion: nil)
    
    }
    
    
    private func saveTask(){
        do{
            try CoreDataStack.shared.mainContext.save()
        }catch{
            NSLog("Error while saving data \(error)")
        }
    }
}

