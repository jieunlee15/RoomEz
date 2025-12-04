import UIKit
import FirebaseFirestore
import FirebaseAuth
protocol NewTaskDelegate: AnyObject {
    func didCreateTask(_ task: RoomTask)
    func didUpdateTask(_ task: RoomTask, at index: Int)
}
class NewTaskViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var assigneePicker: UIPickerView!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var dueDateSwitch: UISwitch!
    @IBOutlet weak var descriptionView: UITextField!
    
    weak var delegate: NewTaskDelegate?
    var editingTask: RoomTask?
    
    // Firestore
    private let db = Firestore.firestore()
    private var roomCode: String?
    
    // Dynamic roommates list
    var roommates: [String] = ["Unassigned"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("💡 NewTaskViewController loaded. Current room code: \(String(describing: roomCode))")
        
        title = editingTask == nil ? "New Task" : "Edit Task"
        
        assigneePicker.dataSource = self
        assigneePicker.delegate = self
        
        dueDatePicker.datePickerMode = .dateAndTime
        dueDatePicker.preferredDatePickerStyle = .compact
        
        descriptionView.delegate = self
        dueDatePicker.isHidden = !dueDateSwitch.isOn
        
        loadRoommates()
        setupEditingData()
    }
    
    // MARK: - Load Roommates from Firestore
    private func loadRoommates() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("roommateGroups")
            .whereField("members", arrayContains: uid)
            .getDocuments { [weak self] snap, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching roommate groups: \(error)")
                    return
                }
                guard let doc = snap?.documents.first else { return }
                self.roomCode = doc.documentID
                guard let membersUIDs = doc.data()["members"] as? [String] else { return }
                // Reset roommates list with "Unassigned"
                self.roommates = ["Unassigned"]
                // Fetch all first names
                let group = DispatchGroup()
                for memberUID in membersUIDs {
                    group.enter()
                    self.db.collection("users").document(memberUID).getDocument { snap, error in
                        defer { group.leave() }
                        if let firstName = snap?.data()?["firstName"] as? String {
                            self.roommates.append(firstName)
                        } else {
                            print("Warning: No firstName for UID \(memberUID)")
                        }
                    }
                }
                // Only reload picker when all first names are fetched
                group.notify(queue: .main) {
                    self.assigneePicker.reloadAllComponents()
                    self.selectEditingAssignee()
                }
            }
    }
    
    private func setupEditingData() {
        guard let t = editingTask else { return }
        titleField.text = t.title
        dueDateSwitch.isOn = t.dueDate != nil
        dueDatePicker.isHidden = t.dueDate == nil
        if let d = t.dueDate { dueDatePicker.date = d }
        descriptionView.text = t.details
    }
    
    private func selectEditingAssignee() {
        guard let t = editingTask, let assignee = t.assignee,
              let index = roommates.firstIndex(of: assignee) else { return }
        assigneePicker.selectRow(index, inComponent: 0, animated: false)
    }
    
    // MARK: - Picker
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { roommates.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? { roommates[row] }
    
    @IBAction func dueDateSwitchChanged(_ sender: UISwitch) {
        dueDatePicker.isHidden = !sender.isOn
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        // 1️⃣ Get and validate the task title
        let titleText = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !titleText.isEmpty else {
            let alert = UIAlertController(title: "Missing Title", message: "Enter a task title.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let assigneeSelection = roommates[assigneePicker.selectedRow(inComponent: 0)]
        let assigneeValue = assigneeSelection == "Unassigned" ? nil : assigneeSelection
        let dueValue = dueDateSwitch.isOn ? dueDatePicker.date : nil
        let details = descriptionView.text?.isEmpty ?? true ? nil : descriptionView.text
        
        if let task = editingTask {
            let updatedTask = RoomTask(
                id: task.id,
                title: titleText,
                details: details,
                dueDate: dueValue,
                assignee: assigneeValue,
                status: task.status,
                createdAt: task.createdAt
            )
            delegate?.didUpdateTask(updatedTask, at: 0)
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
}
        // MARK: - UITextViewDelegate
extension NewTaskViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Add details..." {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = "Add details..."
            textView.textColor = .placeholderText
        }
    }
}
