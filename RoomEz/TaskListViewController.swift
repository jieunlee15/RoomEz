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
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "NewTaskVC") as! NewTaskViewController
        vc.modalPresentationStyle = .pageSheet
        vc.delegate = self
        vc.editingTask = nil
        vc.editingIndex = nil
        present(vc, animated: true)
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
            self.showBanner(message: t.isCompleted ? "Task Completed!" : "Task Reopened")
        }

        return cell
    }

    // (Optional) If you previously had didSelectRowAt toggling, remove it or leave it empty since allowsSelection=false
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) { }
    
    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {

        // DELETE
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self = self else { return }
            self.tasks.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            self.showBanner(message: "Task deleted")
            done(true)
        }

        // EDIT
        let edit = UIContextualAction(style: .normal, title: "Edit") { [weak self] _, _, done in
            guard let self = self else { return }
            self.presentEditor(task: self.tasks[indexPath.row], index: indexPath.row)
            done(true)
        }
        edit.backgroundColor = .systemBlue

        return UISwipeActionsConfiguration(actions: [delete, edit])
    }


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
    
    private func presentEditor(task: RoomTask?, index: Int? = nil) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let vc = sb.instantiateViewController(withIdentifier: "NewTaskVC") as! NewTaskViewController
        vc.modalPresentationStyle = .pageSheet
        vc.delegate = self
        vc.editingTask = task
        vc.editingIndex = index
        present(vc, animated: true)
    }

    
}

extension TaskListViewController: NewTaskDelegate {
    func didCreateTask(_ task: RoomTask) {
        tasks.insert(task, at: 0)
        tableView.reloadData()
    }
    
    func didUpdateTask(_ task: RoomTask, at index: Int) {
        guard tasks.indices.contains(index) else { return }
        tasks[index] = task
        tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        showBanner(message: "Task updated")
    }
    
    
}

