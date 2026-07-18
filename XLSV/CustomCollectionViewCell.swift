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
            }
        }

    // Per-side xlsx border accents, drawn as thin sublayers over the cell's own
    // uniform 0.5pt gridline border (set below) since CALayer only supports one
    // borderWidth/borderColor for all four edges at once -- these are independent
    // rects positioned in layoutSubviews() so they track the cell's actual size.
    private let leftBorderLayer = CALayer()
    private let rightBorderLayer = CALayer()
    private let topBorderLayer = CALayer()
    private let bottomBorderLayer = CALayer()
    private var leftBorderWidth: CGFloat = 0
    private var rightBorderWidth: CGFloat = 0
    private var topBorderWidth: CGFloat = 0
    private var bottomBorderWidth: CGFloat = 0

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
        //updateBorder()
        for edgeLayer in [leftBorderLayer, rightBorderLayer, topBorderLayer, bottomBorderLayer] {
            edgeLayer.isHidden = true
            layer.addSublayer(edgeLayer)
        }
    }

    // Pass nil (or a width <= 0) for a side to hide it -- callers must reset all
    // four sides on every reuse, since dequeued cells keep whatever a previous
    // index path last set here.
    func setEdgeBorders(left: (width: CGFloat, color: UIColor)?,
                         right: (width: CGFloat, color: UIColor)?,
                         top: (width: CGFloat, color: UIColor)?,
                         bottom: (width: CGFloat, color: UIColor)?) {
        leftBorderWidth = applyEdge(left, to: leftBorderLayer)
        rightBorderWidth = applyEdge(right, to: rightBorderLayer)
        topBorderWidth = applyEdge(top, to: topBorderLayer)
        bottomBorderWidth = applyEdge(bottom, to: bottomBorderLayer)
        setNeedsLayout()
    }

    @discardableResult
    private func applyEdge(_ spec: (width: CGFloat, color: UIColor)?, to edgeLayer: CALayer) -> CGFloat {
        guard let spec = spec, spec.width > 0 else {
            edgeLayer.isHidden = true
            return 0
        }
        edgeLayer.backgroundColor = spec.color.cgColor
        edgeLayer.isHidden = false
        return spec.width
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        leftBorderLayer.frame = CGRect(x: 0, y: 0, width: leftBorderWidth, height: bounds.height)
        rightBorderLayer.frame = CGRect(x: bounds.width - rightBorderWidth, y: 0, width: rightBorderWidth, height: bounds.height)
        topBorderLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: topBorderWidth)
        bottomBorderLayer.frame = CGRect(x: 0, y: bounds.height - bottomBorderWidth, width: bounds.width, height: bottomBorderWidth)
    }

}




