//
//  Customview2.swift
//  MultiDirectionCollectionView
//
//  Created by 矢野悠人 on 2016/12/09.
//  Copyright © 2016年 Credera. All rights reserved.
//

import UIKit

class Customview2: UIView {

    var view2:UIView!
    
   
    @IBOutlet weak var calcAll: UIButton!
    @IBOutlet weak var export: UIButton!
    
    @IBOutlet weak var resetStyling: UIButton!

    @IBOutlet weak var xlsxSheetExportOniCloudDrive: UIButton!
    @IBOutlet weak var localLoad: UIButton!
    @IBOutlet weak var localSave: UIButton!
    @IBOutlet weak var reset: UIButton!
    @IBOutlet weak var back: UIButton!
    
    @IBOutlet weak var savebutton: UIButton!
    @IBOutlet weak var deletebutton: UIButton!
    
    @IBOutlet weak var v135Data: UIButton!
    
    @IBOutlet weak var emailButton: UIButton!
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
        view2 = loadviewfromNib()
        view2.frame = bounds
        //http://stackoverflow.com/questions/30867325/binary-operator-cannot-be-applied-to-two-UIView.AutoresizingMask-operands
        view2.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        addSubview(view2)
        
    }
    
    //http://stackoverflow.com/questions/34658838/instantiate-view-from-nib-throws-error
    func loadviewfromNib() ->UIView
    {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: "Customviewboard2",bundle: bundle)
        let view2 = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        
        return view2
    }

}
