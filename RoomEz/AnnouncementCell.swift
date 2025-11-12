//  AnnouncementCell.swift
//  RoomEz
//  Created by Jieun Lee on 10/21/25.

import UIKit

class AnnouncementCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var contentLabel
    : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.numberOfLines = 0
        contentLabel.numberOfLines = 0
        authorLabel.numberOfLines = 1
    }
}
