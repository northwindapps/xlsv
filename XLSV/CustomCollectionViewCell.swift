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
    private let defaultGridBorderWidth: CGFloat = 0.3 //0 this is useful. 
    var indexPath: IndexPath? {
            didSet {
            }
        }

    // Per-side xlsx border accents. When any imported border is present, the
    // default gridline is hidden so the two systems do not visually stack.
    // CALayer only supports one
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
        self.layer.borderWidth = defaultGridBorderWidth
        self.layer.borderColor = UIColor(white: 0.85, alpha: 1.0).cgColor
        //self.layer.borderColor = UIColor.white.cgColor
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
        let hasExcelBorder = leftBorderWidth > 0 || rightBorderWidth > 0 || topBorderWidth > 0 || bottomBorderWidth > 0
        layer.borderWidth = hasExcelBorder ? 0 : defaultGridBorderWidth
        setNeedsLayout()
    }

    @discardableResult
    private func applyEdge(_ spec: (width: CGFloat, color: UIColor)?, to edgeLayer: CALayer) -> CGFloat {
        guard let spec = spec, spec.width > 0 else {
            edgeLayer.isHidden = true
            return 0
        }
        // Sub-pixel widths don't rasterize to a fixed pixel row/column -- as the
        // cell's frame shifts by fractional points during scroll, CALayer has to
        // re-anti-alias the line against a different pixel offset each frame,
        // which reads as the border shifting/flickering while scrolling. Snap up
        // to a whole device pixel so any width > 0 still renders, but always as
        // the same crisp line regardless of scroll offset.
        let onePixel = 1 / UIScreen.main.scale
        let renderedWidth = max(spec.width, onePixel)
        edgeLayer.backgroundColor = spec.color.cgColor
        edgeLayer.isHidden = false
        return renderedWidth
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        leftBorderLayer.frame = CGRect(x: 0, y: 0, width: leftBorderWidth, height: bounds.height)
        rightBorderLayer.frame = CGRect(x: bounds.width - rightBorderWidth, y: 0, width: rightBorderWidth, height: bounds.height)
        topBorderLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: topBorderWidth)
        bottomBorderLayer.frame = CGRect(x: 0, y: bounds.height - bottomBorderWidth, width: bounds.width, height: bottomBorderWidth)
    }
    
    // 再利用時に呼ばれるシステムメソッド
    override func prepareForReuse() {
        super.prepareForReuse()
        // 枠線の状態をデフォルトの初期状態（枠線なし）に戻す
        clearAllEdgeBorders()
    }

    // 4辺のカスタム枠線をすべてクリアしてデフォルトの薄い網線に戻すメソッド
    func clearAllEdgeBorders() {
        leftBorderWidth = 0
        rightBorderWidth = 0
        topBorderWidth = 0
        bottomBorderWidth = 0
        
        leftBorderLayer.isHidden = true
        rightBorderLayer.isHidden = true
        topBorderLayer.isHidden = true
        bottomBorderLayer.isHidden = true
        
        // デフォルトの網線表示に戻す
        layer.borderWidth = defaultGridBorderWidth
        layer.borderColor = UIColor(white: 0.85, alpha: 1.0).cgColor
    }


}

