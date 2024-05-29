//
//  SummaryCell.swift
//  demo
//
//  Created by 박준영 on 2022/11/03.
//

import UIKit

class SummaryCell: UITableViewCell {
    
    @IBOutlet weak var DateLabel: UILabel!
    
    @IBOutlet weak var countLabel: UILabel!
    
    @IBOutlet weak var resultLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
}
