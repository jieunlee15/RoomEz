// CommentsViewController.swift

import UIKit
import FirebaseFirestore
import FirebaseAuth

// MARK: - Delegates

protocol CommentCellDelegate: AnyObject {
    func didTapReply(for comment: Comment)
}

protocol CommentInputDelegate: AnyObject {
    func didSendComment(text: String, replyToAuthor: String?, at indexPath: IndexPath)
    func didCancelInput(at indexPath: IndexPath)
}

// MARK: - Custom Comment Cell (Display)

class CommentTableViewCell: UITableViewCell {
    
    // UI Elements
    private let commentLabel = UILabel()
    private let detailLabel = UILabel()
    private let replyButton = UIButton(type: .system)
    
    // Data and Delegate
    private var currentComment: Comment?
    weak var delegate: CommentCellDelegate?
    
    // Layout stack view
    private let stackView = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        // Configure Labels
        commentLabel.font = UIFont.systemFont(ofSize: 15)
        commentLabel.numberOfLines = 0
        detailLabel.font = UIFont.systemFont(ofSize: 12)
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 1
        
        // Configure Button
        replyButton.setTitle("Reply", for: .normal)
        replyButton.contentHorizontalAlignment = .left
        replyButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        replyButton.addTarget(self, action: #selector(replyTapped), for: .touchUpInside)
        
        // Stack View for Comment and Detail
        let textStack = UIStackView(arrangedSubviews: [commentLabel, detailLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        
        // Main Stack View (for TextStack and Reply Button)
        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.addArrangedSubview(textStack)
        stackView.addArrangedSubview(replyButton)
        
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Constraints: Constrain stackView edge-to-edge
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    @objc private func replyTapped() {
        guard let comment = currentComment else { return }
        delegate?.didTapReply(for: comment)
    }
    
    func configure(with comment: Comment, delegate: CommentCellDelegate, isReply: Bool, formattedDate: String) {
        self.currentComment = comment
        self.delegate = delegate
        
        let basePadding: CGFloat = 16
        let indentation: CGFloat = isReply ? 20 : 0
        
        // Apply base padding and dynamic indentation via directional margins
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0,
                                                                   leading: basePadding + indentation,
                                                                   bottom: 0,
                                                                   trailing: basePadding)
        
        if isReply {
            self.contentView.backgroundColor = UIColor(white: 0.97, alpha: 1.0)
        } else {
            self.contentView.backgroundColor = .systemBackground
        }

        var commentText = comment.text
        if let replyAuthor = comment.replyToAuthor {
            commentText = "[\(replyAuthor)] \(comment.text)"
        }
        
        commentLabel.text = commentText
        detailLabel.text = "\(comment.author) • \(formattedDate)"
        
        replyButton.isHidden = isReply
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        commentLabel.text = nil
        detailLabel.text = nil
        replyButton.isHidden = false
        currentComment = nil
        delegate = nil
        contentView.backgroundColor = .systemBackground
        stackView.directionalLayoutMargins = .zero
    }
}

// MARK: - Custom Input Cell (Input Field)

class CommentInputCell: UITableViewCell {
    
    // 🚨 CRITICAL FIX: All UI components must be declared as properties here 🚨
    private let inputField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let mainStack = UIStackView()
    
    weak var delegate: CommentInputDelegate?
    private var inputIndexPath: IndexPath?
    var replyToAuthor: String?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        // Setup Input Field
        inputField.borderStyle = .roundedRect
        inputField.placeholder = "Write a comment..."
        inputField.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup Buttons (Ensures "Send" is not squashed)
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.setContentHuggingPriority(.required, for: .horizontal)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancelButton.setContentHuggingPriority(.required, for: .horizontal)

        // Stack for Buttons
        let buttonStack = UIStackView(arrangedSubviews: [cancelButton, sendButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 8
        buttonStack.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        // Main Stack for Input and Buttons
        mainStack.addArrangedSubview(inputField) // <-- FIX: Adding the input field
        mainStack.addArrangedSubview(buttonStack) // <-- FIX: Adding the buttons
        
        mainStack.axis = .horizontal
        mainStack.alignment = .center
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        mainStack.isLayoutMarginsRelativeArrangement = true
        
        contentView.addSubview(mainStack)
        
        // Constraints (Constrained edge-to-edge)
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(isReply: Bool, replyAuthor: String?, at indexPath: IndexPath) {
        self.replyToAuthor = replyAuthor
        self.inputIndexPath = indexPath
        
        let basePadding: CGFloat = 16
        let indentation: CGFloat = isReply ? 20 : 0
        
        mainStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0,
                                                                   leading: basePadding + indentation,
                                                                   bottom: 0,
                                                                   trailing: basePadding)
        
        self.contentView.backgroundColor = isReply ? UIColor(white: 0.97, alpha: 1.0) : .systemBackground

        inputField.text = nil
        inputField.placeholder = isReply ? "Replying to @\(replyAuthor!)..." : "Write a comment..."
        
        cancelButton.isHidden = !isReply
        
        // This is the logic to bring up the keyboard
        DispatchQueue.main.async {
            self.inputField.becomeFirstResponder()
        }
    }
    
    @objc private func sendTapped() {
        guard let text = inputField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty,
              let path = inputIndexPath else { return }
              
        delegate?.didSendComment(text: text, replyToAuthor: replyToAuthor, at: path)
    }
    
    @objc private func cancelTapped() {
        guard let path = inputIndexPath else { return }
        delegate?.didCancelInput(at: path)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        inputField.text = nil
        inputField.placeholder = nil
        cancelButton.isHidden = false
        contentView.backgroundColor = .systemBackground
        mainStack.directionalLayoutMargins = .zero
        replyToAuthor = nil
        inputIndexPath = nil
    }
}

// MARK: - CommentsViewController

class CommentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, CommentCellDelegate, CommentInputDelegate {

    // IMPORTANT: Disconnect these outlets in your Storyboard. We are using in-cell input now.
    @IBOutlet weak var tableView: UITableView!

    
    var announcement: Announcement?
    var roomCode: String?
    var announcementID: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var comments: [Comment] = []
    
    // NEW STATE: Tracks where the dynamic input cell is placed
    private var inputIndexPath: IndexPath?
    
    // Store the reply context when the input cell is active
    private var activeReplyContext: (comment: Comment, indexPath: IndexPath)?
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Comments"

        // Debug to make sure these are set
        print("Comments VC loaded with roomCode: \(roomCode ?? "nil"), announcementID: \(announcementID ?? "nil")")

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CommentTableViewCell.self, forCellReuseIdentifier: "CommentCell")
        tableView.register(CommentInputCell.self, forCellReuseIdentifier: "InputCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.keyboardDismissMode = .interactive

        setupHeaderView()
        listenForComments()
    }

    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Data Fetching

    private func listenForComments() {
        guard let roomCode = roomCode, let announcementID = announcementID else { return }
        
        listener = db.collection("roommateGroups")
            .document(roomCode)
            .collection("announcements")
            .document(announcementID)
            .collection("comments")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                guard let docs = snapshot?.documents else { return }

                self.comments = docs.map { doc in
                    let data = doc.data()
                    return Comment(
                        id: doc.documentID,
                        text: data["text"] as? String ?? "",
                        author: data["author"] as? String ?? "User",
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        replyToAuthor: data["replyToAuthor"] as? String
                    )
                }
                
                // IMPORTANT: Reset reply state when data reloads to prevent crashes
                self.inputIndexPath = nil
                self.activeReplyContext = nil

                self.tableView.reloadData()
                self.scrollToBottom()
            }
    }
    
    // ... [setupHeaderView remains the same] ...
    private func setupHeaderView() {
        guard let announcement = announcement else { return }
        let headerView = UIView(frame: CGRect.zero)
        headerView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        
        let titleLabel = UILabel()
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.numberOfLines = 0
        titleLabel.text = announcement.title
        
        let contentLabel = UILabel()
        contentLabel.font = UIFont.systemFont(ofSize: 15)
        contentLabel.numberOfLines = 0
        contentLabel.text = announcement.content
        
        let authorLabel = UILabel()
        authorLabel.font = UIFont.systemFont(ofSize: 12)
        authorLabel.textColor = .secondaryLabel
        let displayAuthor = announcement.isAnonymous ? "Anonymous" : announcement.author
        authorLabel.text = "Posted by: \(displayAuthor)"
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, contentLabel, authorLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: headerView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ])
        
        let targetSize = CGSize(width: tableView.bounds.width,
                                height: UIView.layoutFittingCompressedSize.height)
        let neededSize = headerView.systemLayoutSizeFitting(targetSize,
                                                           withHorizontalFittingPriority: .required,
                                                           verticalFittingPriority: .fittingSizeLevel)
        
        headerView.frame.size.height = neededSize.height
        
        tableView.tableHeaderView = headerView
    }
    
    private func scrollToBottom() {
        // Only scroll if not currently editing (to keep the keyboard focus on screen)
        guard comments.count > 0, inputIndexPath == nil else { return }
        let index = IndexPath(row: comments.count, section: 0) // Pointing to the last possible cell (the permanent input cell)
        tableView.scrollToRow(at: index, at: .bottom, animated: true)
    }
    
    // MARK: - CommentCellDelegate (Reply Entry Point)

    func didTapReply(for comment: Comment) {
        // 1. Calculate the index of the comment being replied to
        guard let index = comments.firstIndex(where: { $0.id == comment.id }) else { return }
        
        // Account for an existing active input cell
        var commentIndex = index
        if let currentInputPath = inputIndexPath, currentInputPath.row <= index {
            // If the active input cell is before or at the index, adjust the comment index
            commentIndex += 1
        }
        
        // 2. The input cell goes immediately after the tapped comment
        let newIndexPath = IndexPath(row: commentIndex + 1, section: 0)
        
        // 3. If an input cell is already active, remove it first
        if let currentInputPath = inputIndexPath {
            tableView.performBatchUpdates {
                self.inputIndexPath = nil // Reset state first
                self.tableView.deleteRows(at: [currentInputPath], with: .fade)
            }
            
            // If we tapped the same comment again, we're done (toggle off)
            if currentInputPath == newIndexPath {
                activeReplyContext = nil
                return
            }
        }
        
        // 4. Insert the new input cell
        tableView.performBatchUpdates {
            self.inputIndexPath = newIndexPath
            self.activeReplyContext = (comment, newIndexPath)
            self.tableView.insertRows(at: [newIndexPath], with: .top)
        }
        
        // 5. Scroll the new input cell into view
        tableView.scrollToRow(at: newIndexPath, at: .middle, animated: true)
    }

    // MARK: - CommentInputDelegate (Send and Cancel Actions)
    
    func didSendComment(text: String, replyToAuthor: String?, at indexPath: IndexPath) {
        guard let roomCode = roomCode,
              let announcementID = announcementID else { return }

        guard let user = Auth.auth().currentUser else { return }

        let author = user.displayName ?? user.email ?? "User"
        
        var data: [String: Any] = [
            "text": text,
            "author": author,
            "timestamp": Timestamp(date: Date())
        ]
        
        // Add reply tag if present (only true for dynamically inserted reply cells)
        if let replyAuthor = replyToAuthor {
            data["replyToAuthor"] = replyAuthor
        }
        
        // Send to Firestore
        db.collection("roommateGroups")
            .document(roomCode)
            .collection("announcements")
            .document(announcementID)
            .collection("comments")
            .addDocument(data: data)
        
        // Remove the dynamic input cell after sending (if it was a reply cell)
        if indexPath == inputIndexPath {
            tableView.performBatchUpdates {
                self.inputIndexPath = nil
                self.activeReplyContext = nil
                self.tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
        
        // Note: The listener will refresh the whole table after sending the top-level comment
    }
    
    func didCancelInput(at indexPath: IndexPath) {
        // Called when the user clicks 'Cancel' on a dynamic reply cell
        tableView.performBatchUpdates {
            self.inputIndexPath = nil
            self.activeReplyContext = nil
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    // MARK: - TableView Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Base count (all comments) + 1 for the always-present top-level input cell
        var count = comments.count + 1
        
        // If we have a dynamic reply input cell active, add another 1
        if inputIndexPath != nil {
            count += 1
        }
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // 1. Dynamic reply input cell
        if let inputPath = inputIndexPath, indexPath == inputPath {
            let cell = tableView.dequeueReusableCell(withIdentifier: "InputCell", for: indexPath) as! CommentInputCell
            let isReply = true
            let replyAuthor = activeReplyContext?.comment.author
            cell.configure(isReply: isReply, replyAuthor: replyAuthor, at: indexPath)
            cell.delegate = self
            cell.selectionStyle = .none
            return cell
        }

        // 2. Determine the correct index for regular comments, accounting for the dynamic input cell
        var commentIndex = indexPath.row
        if let inputPath = inputIndexPath, indexPath.row > inputPath.row {
            commentIndex -= 1
        }

        if commentIndex < comments.count {
            let comment = comments[commentIndex]
            let isReply = comment.replyToAuthor != nil
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentCell", for: indexPath) as! CommentTableViewCell
            cell.configure(with: comment, delegate: self, isReply: isReply, formattedDate: formattedDate(comment.timestamp))
            cell.selectionStyle = .none
            return cell
        }

        // 3. Bottom top-level input cell (always last)
        let cell = tableView.dequeueReusableCell(withIdentifier: "InputCell", for: indexPath) as! CommentInputCell
        cell.configure(isReply: false, replyAuthor: nil, at: indexPath)
        cell.delegate = self
        cell.selectionStyle = .none
        return cell
    }

    // Disable selecting comment cells now that we have a button
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    private func formattedDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "MM-dd HH:mm"
        return df.string(from: date)
    }
}
