//
//  AnnouncementViewController.swift
//  RoomEz
//
//  Created by Jieun Lee on 10/20/25.
//

import UIKit

struct Announcement {
    let title: String
    let content: String
    let author: String
    let isAnonymous: Bool
    let date: Date
}

class AnnouncementViewController: UIViewController,  UITableViewDataSource, UITableViewDelegate, NewAnnouncementDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var announcements: [Announcement] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 167
    }
    
    @IBAction func addAnnouncementTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "showNewAnnouncement", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showNewAnnouncement",
           let dest = segue.destination as? NewAnnouncementViewController {
                dest.delegate = self
               }
           }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return announcements.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AnnouncementCell", for: indexPath) as! AnnouncementCell
        let announcement = announcements[indexPath.row]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd"
        let dateString = dateFormatter.string(from: announcement.date)
        cell.authorLabel.text = "\(announcement.author) | \(dateString)"
        cell.titleLabel.text = announcement.title
        cell.contentLabel.text = announcement.content
        return cell
    }
    func didPostAnnouncement(_ announcement: Announcement) {
        announcements.insert(announcement, at: 0)
        tableView.reloadData()
        if announcement.isAnonymous {
            showNewAnnouncementBanner()
        }
    }
    func showNewAnnouncementBanner() {
        let bannerHeight: CGFloat = 60
        let banner = UIView()
        banner.backgroundColor = .systemBlue
        banner.layer.cornerRadius = 12
        banner.layer.masksToBounds = false
        banner.layer.shadowColor = UIColor.black.cgColor
        banner.layer.shadowOpacity = 0.3
        banner.layer.shadowOffset = CGSize(width: 0, height: 2)
        banner.layer.shadowRadius = 4
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)

        // Add label
        let label = UILabel()
        label.text = "📢 New Anonymous Note Posted!"
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        banner.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: banner.topAnchor),
            label.bottomAnchor.constraint(equalTo: banner.bottomAnchor)
        ])

        // Banner constraints (start offscreen)
        let topConstraint = banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -bannerHeight)
        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            banner.heightAnchor.constraint(equalToConstant: bannerHeight),
            topConstraint
        ])
        view.layoutIfNeeded()

        // Animate slide down
        topConstraint.constant = 16
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)

        // Tap to dismiss
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissBannerView(_:)))
        banner.addGestureRecognizer(tap)
    }

    @objc func dismissBannerView(_ sender: UITapGestureRecognizer) {
        guard let banner = sender.view else { return }
        UIView.animate(withDuration: 0.3, animations: {
            banner.transform = CGAffineTransform(translationX: 0, y: -banner.frame.height - 16)
            banner.alpha = 0
        }, completion: { _ in
            banner.removeFromSuperview()
        })
    }
}
