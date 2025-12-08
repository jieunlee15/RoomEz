import UIKit
import FirebaseFirestore
import FirebaseAuth

protocol NewTaskDelegate: AnyObject {
    func didCreateTask(_ task: RoomTask)
    func didUpdateTask(_ task: RoomTask, at index: Int)
}

class NewTaskViewController: UIViewController,
                             UIPickerViewDataSource,
                             UIPickerViewDelegate,
                             UITextFieldDelegate {
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var assigneePicker: UIPickerView!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var dueDateSwitch: UISwitch!
    @IBOutlet weak var descriptionView: UITextField!
    @IBOutlet weak var frequency: UISegmentedControl!
    @IBOutlet weak var prioritySegment: UISegmentedControl!
    
    weak var delegate: NewTaskDelegate?
    var editingTask: RoomTask?
    
    private let db = Firestore.firestore()
    private var roomCode: String?
    
    var roommates: [String] = ["Unassigned"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = editingTask == nil ? "New Task" : "Edit Task"
        
        assigneePicker.dataSource = self
        assigneePicker.delegate = self
        
        dueDatePicker.datePickerMode = .dateAndTime
        dueDatePicker.preferredDatePickerStyle = .compact
        dueDatePicker.minimumDate = Date()
        
        descriptionView.delegate = self
        descriptionView.placeholder = "Add details..."
        
        dueDatePicker.isHidden = !dueDateSwitch.isOn
        
        // Defaults when creating a new task (in case storyboard isn’t set)
        if editingTask == nil {
            frequency.selectedSegmentIndex = 0      // "None"
            prioritySegment.selectedSegmentIndex = 1 // "Medium"
        }
        
        loadRoommates()
        setupEditingData()
    }
    
    // MARK: - Helpers for frequency & priority
    
    private func selectedFrequency() -> TaskFrequency {
        switch frequency.selectedSegmentIndex {
        case 1: return .daily
        case 2: return .weekly
        case 3: return .monthly
        default: return .none
        }
    }
    
    private func selectedPriority() -> TaskPriority {
        switch prioritySegment.selectedSegmentIndex {
        case 0: return .low
        case 2: return .high
        default: return .medium
        }
    }
    
    // MARK: - Load roommates
    
    private func loadRoommates() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("roommateGroups")
            .whereField("members", arrayContains: uid)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let doc = snapshot?.documents.first else { return }
                
                self.roomCode = doc.documentID
                guard let memberUIDs = doc.data()["members"] as? [String] else { return }
                
                self.roommates = ["Unassigned"]
                
                let group = DispatchGroup()
                
                for memberUID in memberUIDs {
                    group.enter()
                    self.db.collection("users").document(memberUID).getDocument { snap, _ in
                        if let first = snap?.data()?["firstName"] as? String {
                            self.roommates.append(first)
                        }
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    self.assigneePicker.reloadAllComponents()
                    self.selectEditingAssignee()
                }
            }
    }
    
    // MARK: - Editing state
    
    private func setupEditingData() {
        guard let task = editingTask else { return }
        
        titleField.text = task.title
        
        if let due = task.dueDate {
            dueDateSwitch.isOn = true
            dueDatePicker.isHidden = false
            dueDatePicker.date = due
        } else {
            dueDateSwitch.isOn = false
            dueDatePicker.isHidden = true
        }
        
        dueDatePicker.minimumDate = Date()
        
        if let details = task.details, !details.trimmingCharacters(in: .whitespaces).isEmpty {
            descriptionView.text = details
        } else {
            descriptionView.text = nil
            descriptionView.placeholder = "Add details..."
        }
        
        // Pre-select frequency segment based on task.frequency
        switch task.frequency {
        case .none:
            frequency.selectedSegmentIndex = 0
        case .daily:
            frequency.selectedSegmentIndex = 1
        case .weekly:
            frequency.selectedSegmentIndex = 2
        case .monthly:
            frequency.selectedSegmentIndex = 3
        }
        
        // Pre-select priority segment based on task.priority
        switch task.priority {
        case .low:
            prioritySegment.selectedSegmentIndex = 0
        case .medium:
            prioritySegment.selectedSegmentIndex = 1
        case .high:
            prioritySegment.selectedSegmentIndex = 2
        }
    }
    
    private func selectEditingAssignee() {
        guard let task = editingTask,
              let assignee = task.assignee,
              let index = roommates.firstIndex(of: assignee) else { return }
        
        assigneePicker.selectRow(index, inComponent: 0, animated: false)
    }
    
    // MARK: - Picker
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
    
    func pickerView(_ pickerView: UIPickerView,
                    numberOfRowsInComponent component: Int) -> Int {
        return roommates.count
    }
    
    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        return roommates[row]
    }
    
    // MARK: - Due date switch
    
    @IBAction func dueDateSwitchChanged(_ sender: UISwitch) {
        dueDatePicker.isHidden = !sender.isOn
        if sender.isOn {
            dueDatePicker.minimumDate = Date()
        }
    }
    
    // MARK: - Save
    
    @IBAction func saveTapped(_ sender: Any) {
        let titleText = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
        if titleText.isEmpty {
            let alert = UIAlertController(title: "Missing Title",
                                          message: "Enter a task title.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let selectedAssignee = roommates[assigneePicker.selectedRow(inComponent: 0)]
        let assigneeValue = selectedAssignee == "Unassigned" ? nil : selectedAssignee
        
        var dueValue: Date? = nil
        if dueDateSwitch.isOn {
            let picked = dueDatePicker.date
            if picked < Date() {
                let alert = UIAlertController(title: "Invalid Due Date",
                                              message: "The due date must be in the future.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
            dueValue = picked
        }
        
        let rawDetails = descriptionView.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let details = rawDetails.isEmpty ? nil : rawDetails
        
        let freq = selectedFrequency()
        let priority = selectedPriority()
        
        if let task = editingTask {
            // Updating an existing task
            let updated = RoomTask(
                id: task.id,
                title: titleText,
                details: details,
                dueDate: dueValue,
                assignee: assigneeValue,
                status: task.status,
                priority: priority,
                createdAt: task.createdAt,
                updatedAt: Date(),
                completionPercent: task.completionPercent,
                reminderSet: task.reminderSet,
                frequency: freq
            )
            // TODO: you probably want the real index, not 0
            delegate?.didUpdateTask(updated, at: 0)
        } else {
            // Creating a new task
            let newTask = RoomTask(
                title: titleText,
                details: details,
                dueDate: dueValue,
                assignee: assigneeValue,
                status: .todo,
                priority: priority,
                createdAt: Date(),
                updatedAt: nil,
                completionPercent: 0.0,
                reminderSet: false,
                frequency: freq
            )
            delegate?.didCreateTask(newTask)
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Text field return
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == titleField {
            descriptionView.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
