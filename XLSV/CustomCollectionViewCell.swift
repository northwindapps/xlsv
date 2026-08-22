//
//  CustomCollectionViewCell.swift
//  MultiDirectionCollectionView
//
//  Created by Kyle Andrews on 3/22/15.
//  Copyright (c) 2015 Credera. All rights reserved.
//

import UIKit

// A UIView whose tappable region extends past its own drawn bounds by
// `touchExpansion` points on every side, without changing how big it looks.
class TouchExpandedView: UIView {
    var touchExpansion: CGFloat = 0

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        bounds.insetBy(dx: -touchExpansion, dy: -touchExpansion).contains(point)
    }
}

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

    // Small dot shown on a column-header cell when that column has an
    // active Datafilter condition -- positioned in the top-right corner,
    // sized/laid out in layoutSubviews() like the edge border layers above.
    private let filterBadgeLayer = CALayer()
    private let filterBadgeDiameter: CGFloat = 6

    // Excel/Sheets-style range-selection handle: a small circle centered on
    // the bottom-right corner, shown only on the single cursor cell. Unlike
    // the layers above this needs to be a real UIView (not a CALayer) so it
    // can own a gesture recognizer of its own -- dragging from it starts a
    // range selection directly, without the double-tap-to-arm step that
    // handlePanGesture otherwise requires. The pan recognizer is created
    // once here and forwards to whatever ViewController wires up per
    // reuse via onSelectionHandlePan, since the cell has no reference to
    // the view controller itself.
    //
    // The tappable area is padded well beyond the visible dot (via
    // TouchExpandedView below) -- a finger-sized hit target drawn at full
    // size would swallow a big corner of small spreadsheet cells, so the
    // circle stays modest while the actual touch region is much bigger.
    let selectionHandleView = TouchExpandedView()
    let selectionHandlePanGesture = UIPanGestureRecognizer()
    private let selectionHandleDiameter: CGFloat = 16
    private let selectionHandleTouchExpansion: CGFloat = 14
    var onSelectionHandlePan: ((UIPanGestureRecognizer) -> Void)?

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

        filterBadgeLayer.backgroundColor = UIColor.systemBlue.cgColor
        filterBadgeLayer.cornerRadius = filterBadgeDiameter / 2
        filterBadgeLayer.isHidden = true
        layer.addSublayer(filterBadgeLayer)

        // A rotated square reads as a diamond -- bounds/center are set in
        // layoutSubviews() rather than frame, since frame is meaningless
        // once a non-identity transform is applied.
        selectionHandleView.backgroundColor = UIColor(red: 255/255, green: 0/255, blue: 51/255, alpha: 1)
        selectionHandleView.layer.borderColor = UIColor.white.cgColor
        selectionHandleView.layer.borderWidth = 1
        selectionHandleView.isHidden = true
        selectionHandleView.bounds = CGRect(x: 0, y: 0, width: selectionHandleDiameter, height: selectionHandleDiameter)
        selectionHandleView.transform = CGAffineTransform(rotationAngle: .pi / 4)
        addSubview(selectionHandleView)

        selectionHandleView.touchExpansion = selectionHandleTouchExpansion
        selectionHandlePanGesture.addTarget(self, action: #selector(handleSelectionHandlePan(_:)))
        selectionHandleView.addGestureRecognizer(selectionHandlePanGesture)
    }

    @objc private func handleSelectionHandlePan(_ gesture: UIPanGestureRecognizer) {
        onSelectionHandlePan?(gesture)
    }

    // Callers set this every reuse -- dequeued cells otherwise keep whatever
    // a previous index path last set (visible on a cell that's no longer
    // the cursor).
    func setSelectionHandle(visible: Bool) {
        selectionHandleView.isHidden = !visible
    }

    // Callers set this every reuse (same convention as setEdgeBorders) --
    // dequeued cells otherwise keep whatever a previous index path last set.
    func setFilterBadge(visible: Bool) {
        filterBadgeLayer.isHidden = !visible
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

        let inset: CGFloat = 2
        filterBadgeLayer.frame = CGRect(x: bounds.width - filterBadgeDiameter - inset, y: inset,
                                         width: filterBadgeDiameter, height: filterBadgeDiameter)

        // Centered on the bottom-right corner (half hanging outside the
        // cell), matching Excel/Sheets' own fill-handle placement. Set via
        // center rather than frame -- frame isn't meaningful on a view
        // that carries a rotation transform (see setup()).
        selectionHandleView.center = CGPoint(x: bounds.width, y: bounds.height)
    }
    
    // 再利用時に呼ばれるシステムメソッド
    override func prepareForReuse() {
        super.prepareForReuse()
        // 枠線の状態をデフォルトの初期状態（枠線なし）に戻す
        clearAllEdgeBorders()
        setFilterBadge(visible: false)
        setSelectionHandle(visible: false)
        onSelectionHandlePan = nil
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

