//
//  TableViewCell.swift
//  MultiDirectionCollectionView
//
//  Created by yujinyano on 2018/06/27.
//  Copyright © 2018年 Credera. All rights reserved.
//

import UIKit

class TableViewCell: UITableViewCell {

    @IBOutlet weak var datelabel: UILabel!
    @IBOutlet weak var titlelabel: UILabel!
    @IBOutlet weak var contentlabel: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
