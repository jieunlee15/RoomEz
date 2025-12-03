//  DashboardViewController.swift
//  RoomEz
//  Created by Jieun Lee on 11/7/25.

import UIKit
import FirebaseAuth
import FirebaseFirestore

class DashboardViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: - Outlets (connect in storyboard)
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var progressContainer: UIView!
    @IBOutlet weak var detailButton: UIButton!
    
    private var progressLayer = CAShapeLayer()
    private var trackLayer = CAShapeLayer()
    
    private var taskManager = TaskManager.shared
    // Filtered array: only uncompleted tasks
    private var filteredTasks: [RoomTask] {
        taskManager.tasks.filter { $0.status != .done }
    }
    
    // Firestore reference
    private let db = Firestore.firestore()
    
    // User info cache
    private var firstName: String?
    private var roomCode: String?


    override func viewDidLoad() {
        super.viewDidLoad()
        
        let lineView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 0.5))
        lineView.backgroundColor = UIColor.separator
        tableView.tableHeaderView = lineView
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 110
        tableView.estimatedRowHeight = 110
        
        setupCircularProgress()
        fetchUserData()
        setupTaskObservation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
          super.viewWillAppear(animated)
          updateProgress()
          tableView.reloadData()
          fetchUserData()
      }
    
    private func fetchUserData() {
        // 1️⃣ Use Auth.displayName if available
        if let displayName = Auth.auth().currentUser?.displayName {
            let firstName = displayName.components(separatedBy: " ").first ?? ""
            greetingLabel.text = "Hello \(firstName)!"
            return
        }
        
        // 2️⃣ Fallback: fetch from Firestore
        guard let uid = Auth.auth().currentUser?.uid else {
            greetingLabel.text = "Hello!"
            return
        }
        
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let data = snapshot?.data(), let firstName = data["firstName"] as? String {
                DispatchQueue.main.async {
                    self.greetingLabel.text = "Hello \(firstName)!"
                }
            } else {
                DispatchQueue.main.async {
                    self.greetingLabel.text = "Hello!"
                }
            }
        }
    }
    
    private func setupTaskObservation() {
            // You can use Combine or NotificationCenter to observe changes
            // For simplicity, we'll update when the view appears and when tasks change
        }

    @IBAction func detailPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "toTaskTabBar", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toTaskTabBar" {
            let tabBar = segue.destination as! UITabBarController
            tabBar.selectedIndex = 1  // 0 = first tab, change as needed
        }
    }

    

// MARK: - Circular Progress Setup
    func setupCircularProgress() {
        let center = CGPoint(x: progressContainer.bounds.midX, y: progressContainer.bounds.midY)
        let radius = min(progressContainer.bounds.width, progressContainer.bounds.height) / 2.5
        let circlePath = UIBezierPath(arcCenter: center,
                                          radius: radius,
                                          startAngle: -.pi / 2,
                                          endAngle: 1.5 * .pi,
                                          clockwise: true)

            // Track (gray background circle)
        trackLayer.path = circlePath.cgPath
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor.systemGray5.cgColor
        trackLayer.lineWidth = 10
        trackLayer.lineCap = .round
        progressContainer.layer.addSublayer(trackLayer)

            // Progress (colored arc)
        progressLayer.path = circlePath.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = UIColor.black.cgColor
        progressLayer.lineWidth = 10
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        progressContainer.layer.addSublayer(progressLayer)
    }

    func updateProgress() {
        let tasks = taskManager.tasks
        guard !tasks.isEmpty else {
            progressLayer.strokeEnd = 0
            progressLabel.text = "0%"
            messageLabel.text = "Let's get started together!"
            return
        }

        let completed = tasks.filter { $0.status == .done }.count
        let ratio = CGFloat(completed) / CGFloat(tasks.count)

        UIView.animate(withDuration: 0.5) {
            self.progressLayer.strokeEnd = ratio
        }
        progressLabel.text = "\(Int(ratio * 100))%"

        switch ratio {
        case 0:
            messageLabel.text = "Let's get started together!"
        case 0..<0.85:
            messageLabel.text = "Nice teamwork — we're getting there!"
        case 0.85..<1.0:
            messageLabel.text = "Almost done — just a few more steps!"
        default:
            messageLabel.text = "All done! Great job, everyone!"
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTasks.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell") as? TaskCell else {
            // fallback — make sure you never crash
            return UITableViewCell(style: .default, reuseIdentifier: "FallbackCell")
        }
        let task = filteredTasks[indexPath.row]
        cell.configure(with: task)
        cell.onStatusTapped = { [weak self, weak tableView, weak cell] in
            guard
                let self = self,
                let tableView = tableView,
                let cell = cell,
                let tappedIndexPath = tableView.indexPath(for: cell)
            else { return }
            
            let task = self.filteredTasks[tappedIndexPath.row]
            
            if let originalIndex = self.taskManager.tasks.firstIndex(where: { $0.id == task.id }) {
                var updatedTask = task
                // Cycle through the three states
                switch updatedTask.status {
                case .todo:
                    updatedTask.status = .inProgress
                case .inProgress:
                    updatedTask.status = .done
                case .done:
                    updatedTask.status = .todo
                }
                self.taskManager.updateTask(updatedTask, at: originalIndex)
                
                // Show banner message based on the *new* status
                switch updatedTask.status {
                case .todo:
                    self.showBanner(message: "Task started")
                case .inProgress:
                    self.showBanner(message: "Task marked in progress")
                case .done:
                    self.showBanner(message: "Task completed")
                }
            }
            
            tableView.reloadData()
            self.updateProgress()
        }
        return cell
    }


    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    

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

