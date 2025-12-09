// CommentsViewController.swift

import UIKit
import FirebaseFirestore
import FirebaseAuth

// Comment cell: chat-bubble style
final class BubbleCommentCell: UITableViewCell {
    static let reuseID = "BubbleCommentCell"

    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    private let metaLabel = UILabel()
    private let replyButton = UIButton(type: .system)

    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!

    var replyTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubbleView.layer.cornerRadius = 14
        bubbleView.layer.masksToBounds = true
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)

        messageLabel.numberOfLines = 0
        messageLabel.font = UIFont.systemFont(ofSize: 15)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(messageLabel)

        metaLabel.font = UIFont.systemFont(ofSize: 12)
        metaLabel.textColor = .secondaryLabel
        metaLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(metaLabel)

        replyButton.setTitle("Reply", for: .normal)
        replyButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        replyButton.tintColor = UIColor(hex: "#4F9BDE")
        replyButton.translatesAutoresizingMaskIntoConstraints = false
        replyButton.addTarget(self, action: #selector(didTapReply), for: .touchUpInside)
        contentView.addSubview(replyButton)

        // Constraints
        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -100)

        NSLayoutConstraint.activate([
            leadingConstraint,
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            trailingConstraint,
            bubbleView.bottomAnchor.constraint(equalTo: metaLabel.topAnchor, constant: -8),

            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -12),
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -8),

            metaLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor),
            metaLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor),
            metaLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            replyButton.leadingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: 8),
            replyButton.centerYAnchor.constraint(equalTo: bubbleView.centerYAnchor)
        ])
    }

    @objc private func didTapReply() {
        replyTapped?()
    }

    func configure(with comment: Comment, isReply: Bool) {
        // Message text (prefix with reply author if present)
        if let reply = comment.replyToAuthor {
            messageLabel.text = "[\(reply)] \(comment.text)"
        } else {
            messageLabel.text = comment.text
        }

        let df = DateFormatter()
        df.dateFormat = "MM-dd HH:mm"
        metaLabel.text = "\(comment.author) • \(df.string(from: comment.timestamp))"

        // Visual: replies slightly dim and indented
        if isReply {
            bubbleView.backgroundColor = UIColor(white: 0.96, alpha: 1)
            leadingConstraint.constant = 36
            trailingConstraint.constant = -40
            messageLabel.textColor = .label
        } else {
            bubbleView.backgroundColor = UIColor(white: 0.98, alpha: 1)
            leadingConstraint.constant = 16
            trailingConstraint.constant = -100
            messageLabel.textColor = .label
        }

        // Hide "Reply" on replies (optional)
        replyButton.isHidden = isReply
    }
}

/// Top-level input bar (sticky)
final class CommentInputBar: UIView {
    let textView = UITextView()
    let sendButton = UIButton(type: .system)
    private let replyLabel = UILabel()
    private let cancelReplyButton = UIButton(type: .system)

    // callback closures
    var onSend: ((String) -> Void)?
    var onCancelReply: (() -> Void)?

    private let container = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        container.backgroundColor = UIColor.systemBackground
        container.layer.cornerRadius = 12
        container.layer.shadowColor = UIColor.black.cgColor
        container.layer.shadowOpacity = 0.06
        container.layer.shadowRadius = 6
        container.translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)

        textView.isScrollEnabled = false
        textView.font = UIFont.systemFont(ofSize: 15)
        textView.layer.cornerRadius = 8
        textView.backgroundColor = UIColor(white: 0.97, alpha: 1)
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.translatesAutoresizingMaskIntoConstraints = false

        sendButton.setTitle("Send", for: .normal)
        sendButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        replyLabel.font = UIFont.systemFont(ofSize: 13)
        replyLabel.textColor = .secondaryLabel
        replyLabel.translatesAutoresizingMaskIntoConstraints = false
        replyLabel.isHidden = true

        cancelReplyButton.setTitle("Cancel", for: .normal)
        cancelReplyButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        cancelReplyButton.tintColor = .systemGray
        cancelReplyButton.translatesAutoresizingMaskIntoConstraints = false
        cancelReplyButton.isHidden = true
        cancelReplyButton.addTarget(self, action: #selector(cancelReplyTapped), for: .touchUpInside)

        container.addSubview(replyLabel)
        container.addSubview(cancelReplyButton)
        container.addSubview(textView)
        container.addSubview(sendButton)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            container.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

            replyLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            replyLabel.trailingAnchor.constraint(lessThanOrEqualTo: cancelReplyButton.leadingAnchor, constant: -8),
            replyLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),

            cancelReplyButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            cancelReplyButton.centerYAnchor.constraint(equalTo: replyLabel.centerYAnchor),

            textView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            textView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            textView.topAnchor.constraint(equalTo: replyLabel.bottomAnchor, constant: 8),
            textView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),

            sendButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            sendButton.centerYAnchor.constraint(equalTo: textView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60)
        ])

        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
    }

    @objc private func sendTapped() {
        let text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        onSend?(text)
    }

    @objc private func cancelReplyTapped() {
        replyLabel.isHidden = true
        cancelReplyButton.isHidden = true
        onCancelReply?()
    }

    func setReplying(to author: String?) {
        if let a = author, !a.isEmpty {
            replyLabel.isHidden = false
            cancelReplyButton.isHidden = false
            replyLabel.text = "Replying to @\(a)"
        } else {
            replyLabel.isHidden = true
            cancelReplyButton.isHidden = true
            replyLabel.text = nil
        }
    }

    func clearInput() {
        textView.text = ""
        textView.resignFirstResponder()
    }
}


/// The main view controller
class CommentsViewController: UIViewController {

    // If you have an IBOutlet for a tableView in storyboard, hook it up. Otherwise create programmatically.
    @IBOutlet weak var tableView: UITableView!

    var announcement: Announcement?
    var roomCode: String?
    var announcementID: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private var comments: [Comment] = []

    // Reply state
    private var replyToAuthor: String?

    // Input UI
    private let inputBar = CommentInputBar()
    private var inputBarBottomConstraint: NSLayoutConstraint!

    // Keyboard tracking
    private var keyboardObserverTokens: [NSObjectProtocol] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Comments"

        // Table setup
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(BubbleCommentCell.self, forCellReuseIdentifier: BubbleCommentCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
        tableView.keyboardDismissMode = .interactive

        // Input bar setup (programmatic)
        setupInputBar()

        // Header
        setupHeaderView()

        // Firestore listener
        listenForComments()
    }

    deinit {
        listener?.remove()
        for t in keyboardObserverTokens { NotificationCenter.default.removeObserver(t) }
    }

    private func setupHeaderView() {
        guard let announcement = announcement else { return }

        let container = UIView()
        container.backgroundColor = .clear

        // Card view
        let card = UIView()
        card.backgroundColor = .systemBackground
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 3)
        card.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(card)

        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .label

        let contentLabel = UILabel()
        contentLabel.font = UIFont.systemFont(ofSize: 16)
        contentLabel.numberOfLines = 0
        contentLabel.textColor = .secondaryLabel

        let authorLabel = UILabel()
        authorLabel.font = UIFont.systemFont(ofSize: 13)
        authorLabel.textColor = .tertiaryLabel

        titleLabel.text = announcement.title
        contentLabel.text = announcement.content
        authorLabel.text = "Posted by \(announcement.isAnonymous ? "Anonymous" : announcement.author)"

        let stack = UIStackView(arrangedSubviews: [titleLabel, contentLabel, authorLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            card.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            card.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),

            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        // Auto-size header
        let width = tableView.bounds.width
        let target = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let fitted = container.systemLayoutSizeFitting(
            target,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        container.frame.size.height = fitted.height
        tableView.tableHeaderView = container
    }


    private func setupInputBar() {
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inputBar)

        inputBar.onSend = { [weak self] text in
            self?.sendComment(text)
        }
        inputBar.onCancelReply = { [weak self] in
            self?.replyToAuthor = nil
            self?.inputBar.setReplying(to: nil)
        }

        // Constraints: pin to safe area bottom
        inputBarBottomConstraint = inputBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)

        NSLayoutConstraint.activate([
            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            inputBarBottomConstraint
        ])

        // Make sure table view final content inset accounts for inputBar height
        // We will update it when layout happens / keyboard changes
        view.layoutIfNeeded()

        // Keyboard notifications
        let willShow = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] n in
            self?.keyboardWillChange(notification: n)
        }
        let willHide = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] n in
            self?.keyboardWillChange(notification: n)
        }
        keyboardObserverTokens.append(contentsOf: [willShow, willHide])
    }

    private func keyboardWillChange(notification: Notification) {
        guard let info = notification.userInfo else { return }
        let endFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        let keyboardVisible = notification.name == UIResponder.keyboardWillShowNotification
        let duration = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        let curveRaw = (info[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue ?? 0
        let options = UIView.AnimationOptions(rawValue: UInt(curveRaw << 16))

        // Convert keyboard frame to local coordinates
        let keyboardHeight = keyboardVisible ? endFrame.height - view.safeAreaInsets.bottom : 0

        self.inputBarBottomConstraint.constant = -keyboardHeight

        UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
            self.view.layoutIfNeeded()
            // also adjust table content inset so last message is visible above keyboard/input bar
            let bottomInset = keyboardHeight + 12 + self.inputBar.frame.height
            self.tableView.contentInset.bottom = bottomInset
            self.tableView.scrollIndicatorInsets.bottom = bottomInset
        })
    }

    private func listenForComments() {
        guard let roomCode = roomCode, let announcementID = announcementID else { return }

        listener?.remove()
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

                // Reset reply UI (we keep replyToAuthor but hide input reply label if needed)
                self.inputBar.clearInput()
                self.inputBar.setReplying(to: self.replyToAuthor)

                self.tableView.reloadData()
                // Scroll to bottom
                DispatchQueue.main.async {
                    self.scrollToBottom(animated: true)
                }
            }
    }

    private func scrollToBottom(animated: Bool) {
        // If there are comments, scroll to bottom (last row is index = comments.count - 1)
        guard comments.count > 0 else { return }
        let lastIndex = IndexPath(row: comments.count - 1, section: 0)
        tableView.scrollToRow(at: lastIndex, at: .bottom, animated: animated)
    }

    private func sendComment(_ text: String) {
        guard let roomCode = roomCode, let announcementID = announcementID else { return }
        guard let user = Auth.auth().currentUser else { return }

        let author = user.displayName ?? user.email ?? "User"
        var data: [String: Any] = [
            "text": text,
            "author": author,
            "timestamp": Timestamp(date: Date())
        ]
        if let reply = replyToAuthor {
            data["replyToAuthor"] = reply
        }

        let commentsRef = db.collection("roommateGroups")
            .document(roomCode)
            .collection("announcements")
            .document(announcementID)
            .collection("comments")

        commentsRef.addDocument(data: data) { [weak self] err in
            if let err = err {
                print("Failed to send comment: \(err)")
            } else {
                // Clear input and reply state
                self?.replyToAuthor = nil
                self?.inputBar.clearInput()
                self?.inputBar.setReplying(to: nil)

                // Optionally scroll to bottom after a slight delay to let listener update
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self?.scrollToBottom(animated: true)
                }
            }
        }
    }
}

// MARK: - Table view datasource & delegate
extension CommentsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let comment = comments[indexPath.row]
        let isReply = comment.replyToAuthor != nil

        guard let cell = tableView.dequeueReusableCell(withIdentifier: BubbleCommentCell.reuseID, for: indexPath) as? BubbleCommentCell else {
            return UITableViewCell()
        }

        cell.configure(with: comment, isReply: isReply)
        cell.replyTapped = { [weak self] in
            guard let self = self else { return }
            // Set reply state
            self.replyToAuthor = comment.author
            self.inputBar.setReplying(to: comment.author)
            // Focus text view
            self.inputBar.textView.becomeFirstResponder()
            // Scroll the tapped comment into view
            self.tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
        }

        return cell
    }

    // minor spacing
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
