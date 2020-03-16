//
//  TaskCell.swift
//  Tasks
//
//  Created by FGT MAC on 3/11/20.
//  Copyright © 2020 FGT MAC. All rights reserved.
//

import UIKit

class TaskCell: UITableViewCell {
    
    //MARK: - Properties
    
    var task: Task? {
        didSet{
            updateViews()
        }
    }

    //MARK: - Outlets
    
    @IBOutlet weak var taskTitleLabel: UILabel!
    @IBOutlet weak var completedButton: UIButton!
    
    
    //MARK: - Actions
    @IBAction func toggleComplete(_ sender: UIButton) {
        task?.completed.toggle()
        
        guard let task = task else {return }
        
        completedButton.setImage(task.completed ? UIImage(systemName: "checkmark.circle.fill") : UIImage(systemName: "circle"), for: .normal)
        
        do{
            try CoreDataStack.shared.save()
        }catch{
            NSLog("Error while saving data \(error)")
        }
        
    }
    
    private func updateViews(){
        guard let task = task else { return }
        taskTitleLabel.text = task.name
        completedButton.setImage(task.completed ? UIImage(systemName: "checkmark.circle.fill") :  UIImage(systemName: "circle"), for: .normal)
        
    }
    
}
