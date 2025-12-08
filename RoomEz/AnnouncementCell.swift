import UIKit
struct Announcement {
    let id: String
    let title: String
    let content: String
    let author: String
    let isAnonymous: Bool
    let date: Date
}


protocol AnnouncementCellDelegate: AnyObject {
    func didTapComments(for announcementID: String)
}

class AnnouncementCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var commentButton: UIButton!

    weak var delegate: AnnouncementCellDelegate?
    private var announcementID: String?

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.numberOfLines = 0
        contentLabel.numberOfLines = 0
        authorLabel.numberOfLines = 1
        
        // Only this target triggers segue
        commentButton.addTarget(self, action: #selector(commentTapped), for: .touchUpInside)
    }

    func configure(with announcement: Announcement, delegate: AnnouncementCellDelegate?) {
        self.announcementID = announcement.id
        self.delegate = delegate
        
        let df = DateFormatter()
        df.dateFormat = "MM-dd"
        let displayAuthor = announcement.isAnonymous ? "Anonymous" : announcement.author
        authorLabel.text = "\(displayAuthor) | \(df.string(from: announcement.date))"
        titleLabel.text = announcement.title
        contentLabel.text = announcement.content
        
        // Disable row selection
        self.selectionStyle = .none
    }

    @objc private func commentTapped() {
        guard let id = announcementID else { return }
        delegate?.didTapComments(for: id)
    }
}
