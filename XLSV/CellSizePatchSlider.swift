//
//  Customview2.swift
//  MultiDirectionCollectionView
//
//  Created by 矢野悠人 on 2016/12/09.
//  Copyright © 2016年 Credera. All rights reserved.
//

import UIKit

class CellSizePatchSlider: UIView {

    var view:UIView!
    
    @IBOutlet weak var widthLabel: UILabel!
    
    @IBOutlet weak var widthSlider: UISlider!
    @IBOutlet weak var heightLabel: UILabel!
    
    
    @IBOutlet weak var heightSlider: UISlider!
    
    
    @IBOutlet weak var closebutton: UIButton!

    // Which real column/row this panel is currently patching -- owned here
    // rather than by the presenting view controller, so the panel always
    // knows exactly what it's editing regardless of what else changes
    // selection elsewhere.
    var targetColumn: Int?
    var targetRow: Int?

    override init(frame: CGRect)
    {
        super.init(frame: frame)
        setup()
    }
    
    required init(coder aDecoder:NSCoder)
    {
        super.init(coder:aDecoder)!
        setup()
    }
    
    func setup()
    {
        view = loadviewfromNib()
        view.frame = bounds
        //http://stackoverflow.com/questions/30867325/binary-operator-cannot-be-applied-to-two-UIView.AutoresizingMask-operands
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        addSubview(view)

        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.lightGray.cgColor
        view.clipsToBounds = true

   
    }

    //http://stackoverflow.com/questions/34658838/instantiate-view-from-nib-throws-error
    func loadviewfromNib() ->UIView
    {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "CellSizePatchSlider",bundle: bundle)
        let v = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return v
    }

}
