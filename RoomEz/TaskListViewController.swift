//
//  TaskListViewController.swift
//  RoomEz
//
//  Created by Kirti Ganesh on 10/20/25.
//

import UIKit



class TaskListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // hook this to the table view in storyboard
    @IBOutlet weak var tableView: UITableView!

    // just storing tasks in memory for alpha (will reset on relaunch)
    var tasks: [Task] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tasks"
        tableView.dataSource = self
        tableView.delegate = self
    }

    // hooked to the (+) bar button
    @IBAction func addTaskTapped(_ sender: Any) {
        let alert = UIAlertController(title: "New Task", message: nil, preferredStyle: .alert)

        // fields the prof expects: title, assignee, due date
        alert.addTextField { $0.placeholder = "Title (e.g., Take out trash)" }
        alert.addTextField { $0.placeholder = "Assigned to (optional)" }
        alert.addTextField { $0.placeholder = "Due date (YYYY-MM-DD)" }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }

            // grab values (try not to crash if user leaves stuff blank)
            let rawTitle = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if rawTitle.isEmpty {
                self.toast("Please add a title")
                return
            }

            let rawAssignee = alert.textFields?[1].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let assignee = rawAssignee.isEmpty ? Fairness.nextAssignee() : rawAssignee

            let rawDate = alert.textFields?[2].text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            let due = df.date(from: rawDate) ?? Date() // if bad format, just use today

            // make the task and stick it at the top
            let t = Task(title: rawTitle, assignedTo: assignee, dueDate: due, completed: false)
            self.tasks.insert(t, at: 0)
            self.tableView.reloadData()
            self.toast("Task added")
        }))

        present(alert, animated: true)
    }

    // MARK: - Table stuff

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // in storyboard: set the prototype cell Style = Subtitle, Identifier = "TaskCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        let t = tasks[indexPath.row]

        cell.textLabel?.text = t.title

        // show who + due date under the title
        let df = DateFormatter()
        df.dateStyle = .short
        let who = t.assignedTo ?? "Unassigned"
        cell.detailTextLabel?.text = "\(who) • Due \(df.string(from: t.dueDate))"

        // checkmark when done
        cell.accessoryType = t.completed ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        tasks[indexPath.row].completed.toggle()

        // update just that row so it feels snappy
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = tasks[indexPath.row].completed ? .checkmark : .none
        }
        toast(tasks[indexPath.row].completed ? "Marked complete" : "Reopened task")
    }

    // swipe → edit title (keeps alpha simple but looks nice)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let edit = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, finish in
            guard let self = self else { finish(true); return }
            let current = self.tasks[indexPath.row]

            let a = UIAlertController(title: "Edit Task", message: nil, preferredStyle: .alert)
            a.addTextField { $0.text = current.title }
            a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            a.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
                var updated = current
                updated.title = a.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? current.title
                self.tasks[indexPath.row] = updated
                tableView.reloadRows(at: [indexPath], with: .automatic)
                self.toast("Task updated")
            }))
            self.present(a, animated: true)
            finish(true)
        }
        return UISwipeActionsConfiguration(actions: [edit])
    }

    // tiny “toast” using an alert that closes itself
    private func toast(_ message: String) {
        let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(a, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            a.dismiss(animated: true)
        }
    }
}

