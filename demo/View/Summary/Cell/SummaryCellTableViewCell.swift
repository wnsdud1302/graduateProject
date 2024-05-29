//
//  SummaryCellTableViewCell.swift
//  demo
//
//  Created by 박준영 on 2022/11/03.
//

import UIKit

class SummaryCellTableViewCell: UITableViewCell {

    @IBOutlet weak var DateLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
