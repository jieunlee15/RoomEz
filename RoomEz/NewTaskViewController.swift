import UIKit

protocol NewTaskDelegate: AnyObject {
    func didCreateTask(_ task: RoomTask)
    func didUpdateTask(_ task: RoomTask, at index: Int)
}

class NewTaskViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    // MARK: - Outlets (must be connected in storyboard)
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var assigneePicker: UIPickerView!
    @IBOutlet weak var dueDatePicker: UIDatePicker!
    @IBOutlet weak var dueDateSwitch: UISwitch!
    @IBOutlet weak var descriptionField: UITextField!
    
    weak var delegate: NewTaskDelegate?

    // Editing support
    var editingTask: RoomTask?
    var editingIndex: Int?

    // Alpha: placeholder roommates (later: load from your group)
    let roommates = ["Unassigned", "Lucy", "Ananya", "Jieun", "Shriya", "Kirti"]

    override func viewDidLoad() {
        super.viewDidLoad()

        assigneePicker.dataSource = self
        assigneePicker.delegate = self

        dueDatePicker.datePickerMode = .dateAndTime
        dueDatePicker.preferredDatePickerStyle = .compact

        // Prefill if editing
        if let t = editingTask {
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
        } else {
            // Defaults for new task
            assigneePicker.selectRow(0, inComponent: 0, animated: false)
            dueDateSwitch.isOn = false
            dueDatePicker.isHidden = true
        }
    }

    // MARK: - Picker
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        roommates.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        roommates[row]
    }

    // MARK: - Actions
    @IBAction func dueDateSwitchChanged(_ sender: UISwitch) {
        dueDatePicker.isHidden = !sender.isOn
    }

    @IBAction func saveTapped(_ sender: Any) {
        let titleText = titleField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !titleText.isEmpty else {
            let alert = UIAlertController(title: "Oops", message: "Please enter a title", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let assigneeSelection = roommates[assigneePicker.selectedRow(inComponent: 0)]
        let assigneeValue = (assigneeSelection == "Unassigned") ? nil : assigneeSelection
        let dueValue = dueDateSwitch.isOn ? dueDatePicker.date : nil

        if var task = editingTask, let idx = editingIndex {
            // Update existing
            task.title = titleText
            task.assignee = assigneeValue
            task.dueDate = dueValue
            delegate?.didUpdateTask(task, at: idx)
        } else {
            // Create new
            let newTask = RoomTask(title: titleText,
                                   details: nil,
                                   dueDate: dueValue,
                                   assignee: assigneeValue,
                                   isCompleted: false,
                                   createdAt: Date())
            delegate?.didCreateTask(newTask)
        }

        dismiss(animated: true)
    }
}
