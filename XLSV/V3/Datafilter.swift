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

    // From/To date-range fields, parsed by DateFilterCondition.parse.
    // Deliberately plain (no ==,>=,<= operator syntax) since a range is the
    // near-universal case for filtering dates; either side left blank means
    // an open-ended bound. ANDed with conditionfield when set.
    @IBOutlet weak var datefromfield: UITextField!
    @IBOutlet weak var datetofield: UITextField!

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

        applyLocalization()
    }

    // Same pattern used app-wide (see e.g. FileFillViewController.icloudview,
    // CalcViewController's mailbutton) -- no xib-level .strings localization
    // here since Datafilter.xib isn't in Base.lproj/a variant group, so this
    // mirrors preferredLanguages-based text swapping instead.
    private func applyLocalization() {
        let locationstr = NSLocale.preferredLanguages.first ?? "en"

        var conditionPlaceholder = "e.g. >=10,<=20 or ==apple"
        var fromPlaceholder = "From yyyy/mm/dd"
        var toPlaceholder = "To yyyy/mm/dd"
        var applyTitle = "Apply"
        var clearTitle = "Clear"

        if locationstr.contains("ja") {
            conditionPlaceholder = "例: >=10,<=20 または ==apple"
            fromPlaceholder = "開始 yyyy/mm/dd"
            toPlaceholder = "終了 yyyy/mm/dd"
            applyTitle = "適用"
            clearTitle = "クリア"
        } else if locationstr.contains("zh") {
            conditionPlaceholder = "例如 >=10,<=20 或 ==apple"
            fromPlaceholder = "起始 yyyy/mm/dd"
            toPlaceholder = "结束 yyyy/mm/dd"
            applyTitle = "应用"
            clearTitle = "清除"
        } else if locationstr.contains("de") {
            conditionPlaceholder = "z.B. >=10,<=20 oder ==apple"
            fromPlaceholder = "Von yyyy/mm/dd"
            toPlaceholder = "Bis yyyy/mm/dd"
            applyTitle = "Anwenden"
            clearTitle = "Löschen"
        } else if locationstr.contains("da") {
            conditionPlaceholder = "f.eks. >=10,<=20 eller ==apple"
            fromPlaceholder = "Fra yyyy/mm/dd"
            toPlaceholder = "Til yyyy/mm/dd"
            applyTitle = "Anvend"
            clearTitle = "Ryd"
        } else if locationstr.contains("fr") {
            conditionPlaceholder = "ex. >=10,<=20 ou ==apple"
            fromPlaceholder = "De yyyy/mm/dd"
            toPlaceholder = "À yyyy/mm/dd"
            applyTitle = "Appliquer"
            clearTitle = "Effacer"
        } else if locationstr.contains("es") {
            conditionPlaceholder = "ej. >=10,<=20 o ==apple"
            fromPlaceholder = "Desde yyyy/mm/dd"
            toPlaceholder = "Hasta yyyy/mm/dd"
            applyTitle = "Aplicar"
            clearTitle = "Borrar"
        } else if locationstr.contains("it") {
            conditionPlaceholder = "es. >=10,<=20 o ==apple"
            fromPlaceholder = "Da yyyy/mm/dd"
            toPlaceholder = "A yyyy/mm/dd"
            applyTitle = "Applica"
            clearTitle = "Cancella"
        } else if locationstr.contains("ru") {
            conditionPlaceholder = "напр. >=10,<=20 или ==apple"
            fromPlaceholder = "С yyyy/mm/dd"
            toPlaceholder = "По yyyy/mm/dd"
            applyTitle = "Применить"
            clearTitle = "Очистить"
        } else if locationstr.contains("sv") {
            conditionPlaceholder = "t.ex. >=10,<=20 eller ==apple"
            fromPlaceholder = "Från yyyy/mm/dd"
            toPlaceholder = "Till yyyy/mm/dd"
            applyTitle = "Tillämpa"
            clearTitle = "Rensa"
        } else if locationstr.contains("ar") {
            conditionPlaceholder = "مثال >=10,<=20 أو ==apple"
            fromPlaceholder = "من yyyy/mm/dd"
            toPlaceholder = "إلى yyyy/mm/dd"
            applyTitle = "تطبيق"
            clearTitle = "مسح"
        }

        conditionfield.placeholder = conditionPlaceholder
        datefromfield.placeholder = fromPlaceholder
        datetofield.placeholder = toPlaceholder
        applybutton.setTitle(applyTitle, for: .normal)
        deselectbutton.setTitle(clearTitle, for: .normal)
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
