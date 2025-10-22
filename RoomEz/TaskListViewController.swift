//
//  TaskListViewController.swift
//  RoomEz
//

import UIKit

class TaskListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    // Sample in-memory data for alpha
    var tasks: [RoomTask] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tasks"
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false                      // we’ll toggle via the button
        tableView.rowHeight = 110       // <- fixed height for now
        tableView.estimatedRowHeight = 110

    }

    // MARK: - Add task
    @IBAction func addTaskTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "New Task", message: "Enter task title", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "e.g., Take out trash" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { _ in
            guard let title = alert.textFields?.first?.text, !title.isEmpty else { return }
            let newTask = RoomTask(title: title, details: nil, dueDate: nil, assignee: nil, isCompleted: false, createdAt: Date())
            self.tasks.insert(newTask, at: 0)
            self.tableView.reloadData()
            self.showBanner(message: "🧹 New Task Added!")
        }))
        present(alert, animated: true)
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath) as! TaskCell
        let task = tasks[indexPath.row]
        cell.configure(with: task)

        // Wire the button tap to toggle this row’s task
        cell.onStatusTapped = { [weak self, weak tableView, weak cell] in
            guard
                let self = self,
                let tableView = tableView,
                let cell = cell,
                let tappedIndexPath = tableView.indexPath(for: cell)
            else { return }

            var t = self.tasks[tappedIndexPath.row]
            t.isCompleted.toggle()
            self.tasks[tappedIndexPath.row] = t
            tableView.reloadRows(at: [tappedIndexPath], with: .automatic)
            self.showBanner(message: t.isCompleted ? "✅ Task Completed!" : "⏳ Task Reopened")
        }

        return cell
    }

    // (Optional) If you previously had didSelectRowAt toggling, remove it or leave it empty since allowsSelection=false
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { }

    // MARK: - Banner (matches your Announcements style)
    func showBanner(message: String) {
        let bannerHeight: CGFloat = 60
        let banner = UIView()
        banner.backgroundColor = .systemBlue
        banner.layer.cornerRadius = 12
        banner.layer.shadowOpacity = 0.3
        banner.layer.shadowOffset = CGSize(width: 0, height: 2)
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)

        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        banner.addSubview(label)

        let top = banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -bannerHeight)
        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            banner.heightAnchor.constraint(equalToConstant: bannerHeight),
            top,
            label.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: banner.topAnchor),
            label.bottomAnchor.constraint(equalTo: banner.bottomAnchor)
        ])
        view.layoutIfNeeded()

        top.constant = 16
        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.4, options: [], animations: {
            self.view.layoutIfNeeded()
        })

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            UIView.animate(withDuration: 0.25, animations: {
                banner.transform = CGAffineTransform(translationX: 0, y: -bannerHeight - 20)
                banner.alpha = 0
            }, completion: { _ in banner.removeFromSuperview() })
        }
    }
}
