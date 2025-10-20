//
//  MessageViewController.swift
//  RoomEz
//
//  Created by Jieun Lee on 10/19/25.
//

import UIKit

class MessageListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var messages: [String] = [] // just simple text messages for now

    override func viewDidLoad() {
            super.viewDidLoad()
            title = "Messages"
            tableView.dataSource = self
        }

        // Prepare for segue to set delegate
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "toNewMessage",
               let newMessageVC = segue.destination as? NewMessageViewController {
                newMessageVC.delegate = self
            }
        }
    }

    // MARK: - TableView Data Source
    extension MessageListViewController: UITableViewDataSource {

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return messages.count
        }

        func tableView(_ tableView: UITableView,
                       cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
            cell.textLabel?.text = messages[indexPath.row]
            return cell
        }
    }

    // MARK: - NewMessageDelegate
    extension MessageListViewController: NewMessageDelegate {
        func didPostMessage(_ message: String) {
            messages.insert(message, at: 0)
            tableView.reloadData()
        }
    }
