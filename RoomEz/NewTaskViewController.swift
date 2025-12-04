import UIKit
import FirebaseFirestore
import FirebaseAuth

protocol NewTaskDelegate: AnyObject {
    func didCreateTask(_ task: RoomTask)
    func didUpdateTask(_ task: RoomTask, at index: Int)
}

class NewTaskViewController: UIViewController,UIPickerViewDataSource,UIPickerViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var assigneePicker: UIPickerView!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var dueDateSwitch: UISwitch!
    @IBOutlet weak var descriptionView: UITextField!
    
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
        
        loadRoommates()
        setupEditingData()
    }
    
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
    }
    
    private func selectEditingAssignee() {
        guard let task = editingTask,
              let assignee = task.assignee,
              let index = roommates.firstIndex(of: assignee) else { return }
        
        assigneePicker.selectRow(index, inComponent: 0, animated: false)
    }
    
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
    
    @IBAction func dueDateSwitchChanged(_ sender: UISwitch) {
        dueDatePicker.isHidden = !sender.isOn
        if sender.isOn {
            dueDatePicker.minimumDate = Date()
        }
    }
    
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
        
        if let task = editingTask {
            let updated = RoomTask(
                id: task.id,
                title: titleText,
                details: details,
                dueDate: dueValue,
                assignee: assigneeValue,
                status: task.status,
                createdAt: task.createdAt
            )
            delegate?.didUpdateTask(updated, at: 0)
        } else {
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == titleField {
            descriptionView.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
}
