//  NewTaskViewController.swift
//  RoomEz
//  Created by Jieun Lee on 11/09/25.

import UIKit

protocol NewTaskDelegate: AnyObject {
    func didCreateTask(_ task: RoomTask)
    func didUpdateTask(_ task: RoomTask, at index: Int)
}

class NewTaskViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var assigneePicker: UIPickerView!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var dueDateSwitch: UISwitch!
    @IBOutlet weak var descriptionView: UITextField!
    
    weak var delegate: NewTaskDelegate?
    
    // Editing support
    var editingTask: RoomTask?
    var editingIndex: Int?
    
    // Placeholder roommate and category data
    let roommates = ["Unassigned", "Lucy", "Ananya", "Jieun", "Shriya", "Kirti"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = editingTask == nil ? "New Task" : "Edit Task"
        
        assigneePicker.dataSource = self
        assigneePicker.delegate = self
        
        
        dueDatePicker.datePickerMode = .dateAndTime
        dueDatePicker.preferredDatePickerStyle = .compact
        
        setupUI()
        populateIfEditing()
    }
    
    // MARK: - Setup
    private func setupUI() {
        descriptionView.delegate = self
        dueDatePicker.isHidden = !dueDateSwitch.isOn
    }
    
    private func populateIfEditing() {
        guard let t = editingTask else { return }
        titleField.text = t.title
        if let a = t.assignee, let idx = roommates.firstIndex(of: a) {
            assigneePicker.selectRow(idx, inComponent: 0, animated: false)
        } else {
            assigneePicker.selectRow(0, inComponent: 0, animated: false)
        }
        
        if let d = t.dueDate {
            dueDateSwitch.isOn = true
            dueDatePicker.isHidden = false
            dueDatePicker.date = d
        } else {
            dueDateSwitch.isOn = false
            dueDatePicker.isHidden = true
        }
    }
    
    // MARK: - Picker
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return roommates.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return roommates[row]
    }
    
    // MARK: - Actions
    @IBAction func dueDateSwitchChanged(_ sender: UISwitch) {
        dueDatePicker.isHidden = !sender.isOn
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        let titleText = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !titleText.isEmpty else {
            let alert = UIAlertController(
                title: "Missing Title",
                message: "Please enter a task title before saving.",
                preferredStyle: .alert
            )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            return
        }
        
        let assigneeSelection = roommates[assigneePicker.selectedRow(inComponent: 0)]
        let assigneeValue = (assigneeSelection == "Unassigned") ? nil : assigneeSelection
        let dueValue = dueDateSwitch.isOn ? dueDatePicker.date : nil
        let details = (descriptionView.text == "Add details...") ? nil : descriptionView.text
    
        if let editingTask, let idx = editingIndex {
            // Update existing task
            let updatedTask = RoomTask(
                id: editingTask.id,
                title: titleText,
                details: details,
                dueDate: dueValue,
                assignee: assigneeValue,
                status: editingTask.status,
                createdAt: editingTask.createdAt
            )
            delegate?.didUpdateTask(updatedTask, at: idx)
        } else {
            // Create new task
            let newTask = RoomTask(
                title: titleText,
                details: details,
                dueDate: dueValue,
                assignee: assigneeValue,
                status: .todo,
                createdAt: Date()
            )
            delegate?.didCreateTask(newTask)
        }
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - UITextViewDelegate for placeholder text
extension NewTaskViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Add details..." {
            textView.text = ""
            textView.textColor = .label
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Add details..."
            textView.textColor = .placeholderText
        }
    }
}

