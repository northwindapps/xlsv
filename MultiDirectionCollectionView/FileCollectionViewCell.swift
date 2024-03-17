//
//  FileCollectionViewCell.swift
//  MultiDirectionCollectionView
//
//  Created by yujin on 2020/05/09.
//  Copyright © 2020 Credera. All rights reserved.
//

import UIKit

class FileCollectionViewCell: UICollectionViewCell {
    
    
    @IBOutlet weak var FileLabel: UILabel!
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    func setup() {
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.gray.cgColor
        
        
        //self.layer.cornerRadius = 5.0
    }
}
