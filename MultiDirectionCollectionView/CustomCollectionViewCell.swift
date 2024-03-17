//
//  CustomCollectionViewCell.swift
//  MultiDirectionCollectionView
//
//  Created by Kyle Andrews on 3/22/15.
//  Copyright (c) 2015 Credera. All rights reserved.
//

import UIKit

@IBDesignable
class CustomCollectionViewCell: UICollectionViewCell {
   
    
    @IBOutlet weak var label2: UIMarginLabel!
    var indexPath: IndexPath? {
            didSet {
                //updateBorder()
            }
        }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
//    private func updateBorder() {
//        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
//        if (indexPath != nil && appd.index_border_id .count > 0){
//            let border_id = appd.index_border_id[String(indexPath!.item) + "," + String(indexPath!.section)]
//            if(border_id != nil){
////                if((indexPath?.item == 1 && indexPath?.section == 1) || (indexPath?.item == 5 && indexPath?.section == 5)){
//
//                // Apply border settings
//                let borderWidth: CGFloat = 2.0
//                let borderColor = UIColor.red.cgColor
//                let borderWidthTest: CGFloat = 0.0
//
//                //border style
//                let int_border_id = Int(border_id!)
//                if  appd.borders_right_style[appd.border_ids[int_border_id!]] != "nil"{
//                    // right border
//                    let borderLayer = CALayer()
//                    borderLayer.backgroundColor = borderColor
//                    borderLayer.frame = CGRect(x: bounds.width - borderWidth, y: 0, width: borderWidth, height: bounds.height)
//                    layer.addSublayer(borderLayer)
//                }else{
//                    layer.sublayers?.filter { $0.backgroundColor == UIColor.red.cgColor }.forEach { $0.removeFromSuperlayer() }
//                }
//
//                if  appd.borders_left_style[appd.border_ids[int_border_id!]] != "nil"{
//                    // left border
//                    let borderLayer1 = CALayer()
//                    borderLayer1.backgroundColor = borderColor
//                    borderLayer1.frame = CGRect(x: 0, y: 0, width: borderWidth, height: bounds.height)
//                    layer.addSublayer(borderLayer1)
//                }else{
//                    layer.sublayers?.filter { $0.backgroundColor == UIColor.red.cgColor }.forEach { $0.removeFromSuperlayer() }
//                }
//
//                if  appd.borders_top_style[appd.border_ids[int_border_id!]] != "nil"{
//                    // top border
//                    let borderLayer2 = CALayer()
//                    borderLayer2.backgroundColor = borderColor
//                    borderLayer2.frame = CGRect(x: 0, y: 0, width:bounds.width, height: borderWidth)
//                    layer.addSublayer(borderLayer2)
//                }else{
//                    layer.sublayers?.filter { $0.backgroundColor == UIColor.red.cgColor }.forEach { $0.removeFromSuperlayer() }
//                }
//
//                if  appd.borders_bottom_style[appd.border_ids[int_border_id!]] != "nil"{
//                    // bottom border
//                    let borderLayer3 = CALayer()
//                    borderLayer3.backgroundColor = borderColor
//                    borderLayer3.frame = CGRect(x: 0, y: bounds.height - borderWidth, width: bounds.width, height: borderWidth)
//                    layer.addSublayer(borderLayer3)
//                }else{
//                    layer.sublayers?.filter { $0.backgroundColor == UIColor.red.cgColor }.forEach { $0.removeFromSuperlayer() }
//                }
//
//                }else{
//                    layer.sublayers?.filter { $0.backgroundColor == UIColor.red.cgColor }.forEach { $0.removeFromSuperlayer() }
//                }
//        }
//    }
    
    func setup() {
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.gray.cgColor
        //updateBorder()
    }
    
    
    
}




