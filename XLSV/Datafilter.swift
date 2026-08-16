//
//  Customview2.swift
//  MultiDirectionCollectionView
//
//  Created by 矢野悠人 on 2016/12/09.
//  Copyright © 2016年 Credera. All rights reserved.
//

import UIKit

class Datafilter: UIView {

    var view:UIView!
    
    @IBOutlet weak var closebutton: UIButton!

    @IBOutlet weak var applybutton: UIButton!

    @IBOutlet weak var deselectbutton: UIButton!

    // Single free-form condition field -- parsed by
    // ColumnFilterCondition.parse (==, >=, <=, <, >, comma-separated and
    // ANDed together, e.g. ">=10,<=20" for a range). Replaced the previous
    // four fixed fields (text/num-larger/num-lesser/num-equal).
    @IBOutlet weak var conditionfield: UITextField!
    
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
        let nib = UINib(nibName: "Datafilter",bundle: bundle)
        let v = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return v
    }

}
