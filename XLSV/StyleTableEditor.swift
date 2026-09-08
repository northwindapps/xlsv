//
//  StyleTableEditor.swift
//  XLSV
//
//  Editable, find-or-create view over an xl/styles.xml document. Everything else
//  in the app that touches styles.xml (Service.testExtractStyle, resolveCellStyles)
//  only *reads* -- this is the one place that can add a <font>/<fill>/<xf> that
//  didn't exist before and hand back the new cell style index (`s=`).
//
//  Used at save time by Service.flushPendingEditsToXlsx: given a cell's current
//  style index and a desired text color / fill color / font size, `styleIndex(...)`
//  returns an xf index that produces that appearance -- reusing an existing entry
//  when one already matches, appending new <font>/<fill>/<xf> entries when not.
//  `serializedXML()` then emits the rewritten styles.xml.
//
//  Design constraints (see todo.md "In-app cell styling" + Claude memory
//  `feedback_xlsx_structural_validity_over_formula_correctness` /
//  `feedback_xlsx_xml_edit_pattern`):
//   - Appends only. Existing font/fill/xf indices never shift, so every `s=` a
//     cell already carries stays valid and Service.testExtractStyle's own
//     re-append of its 3 fixed numFmt <xf> rows on the next load stays consistent.
//   - Colors are always written as explicit rgb="FFRRGGBB" (never theme refs).
//   - The `count=` attribute on <fonts>/<fills>/<cellXfs> is kept in sync with the
//     actual child count -- a stale count is a guaranteed "we found a problem"
//     repair-dialog trigger.
//   - Everything not touched (borders, cellStyleXfs, dxfs, numFmts, tableStyles,
//     every existing <xf>'s exact bytes) is left alone via literal-anchor splicing.
//

import Foundation
import SWXMLHash

final class StyleTableEditor {

    // MARK: - Parsed tables

    private struct FontSpec: Equatable {
        var size: Double?
        var colorRgb: String?      // "FFRRGGBB" once set explicitly
        var colorTheme: Int?       // original theme index, dropped as soon as colorRgb is set
        var colorTint: Double?
        var bold = false
        var italic = false
        var underline = false
        var strike = false
        var name: String?
        var family: String?
        var scheme: String?

        // Excel's own child order: b, i, strike, u, sz, color, name, family, scheme.
        // Two fonts that render identically produce the same string here, which is
        // what lets an existing font be reused instead of appending a near-duplicate.
        func canonical() -> String {
            var s = "<font>"
            if bold { s += "<b/>" }
            if italic { s += "<i/>" }
            if strike { s += "<strike/>" }
            if underline { s += "<u/>" }
            if let size = size { s += "<sz val=\"\(StyleTableEditor.trimNumber(size))\"/>" }
            if let rgb = colorRgb {
                s += "<color rgb=\"\(rgb)\"/>"
            } else if let theme = colorTheme {
                if let tint = colorTint, tint != 0 {
                    s += "<color theme=\"\(theme)\" tint=\"\(tint)\"/>"
                } else {
                    s += "<color theme=\"\(theme)\"/>"
                }
            }
            if let name = name { s += "<name val=\"\(StyleTableEditor.xmlAttr(name))\"/>" }
            if let family = family { s += "<family val=\"\(family)\"/>" }
            if let scheme = scheme { s += "<scheme val=\"\(scheme)\"/>" }
            s += "</font>"
            return s
        }
    }

    private struct FillSpec: Equatable {
        var solidFgRgb: String?    // "FFRRGGBB" -- the visible color for patternType="solid"
        var rawMarker: String      // canonical key for a fill we don't model (none/gray125/theme fills)

        func canonical() -> String {
            if let rgb = solidFgRgb {
                return "<fill><patternFill patternType=\"solid\"><fgColor rgb=\"\(rgb)\"/><bgColor indexed=\"64\"/></patternFill></fill>"
            }
            return rawMarker
        }
    }

    private struct XfSpec {
        var numFmtId = 0
        var fontId = 0
        var fillId = 0
        var borderId = 0
        var xfId = 0
        var applyFont = false
        var applyFill = false
        var alignHorizontal: String?
        var alignVertical: String?
        var wrapText = false

        // Only the fields that decide "does this xf render what I want" -- apply*
        // flags are ignored (a matching font/fill id renders the same with or
        // without them).
        func matchKey() -> String {
            "\(numFmtId)|\(fontId)|\(fillId)|\(borderId)|\(xfId)|\(alignHorizontal ?? "")|\(alignVertical ?? "")|\(wrapText ? 1 : 0)"
        }

        func hasAlignment() -> Bool {
            alignHorizontal != nil || alignVertical != nil || wrapText
        }

        func generated() -> String {
            var s = "<xf numFmtId=\"\(numFmtId)\" fontId=\"\(fontId)\" fillId=\"\(fillId)\" borderId=\"\(borderId)\" xfId=\"\(xfId)\""
            if applyFont { s += " applyFont=\"1\"" }
            if applyFill { s += " applyFill=\"1\"" }
            if hasAlignment() { s += " applyAlignment=\"1\"" }
            if hasAlignment() {
                s += "><alignment"
                if let h = alignHorizontal { s += " horizontal=\"\(h)\"" }
                if let v = alignVertical { s += " vertical=\"\(v)\"" }
                if wrapText { s += " wrapText=\"1\"" }
                s += "/></xf>"
            } else {
                s += "/>"
            }
            return s
        }
    }

    // MARK: - State

    private let originalXML: String
    private var fonts: [FontSpec] = []
    private var fills: [FillSpec] = []
    private var xfs: [XfSpec] = []

    private let originalFontCount: Int
    private let originalFillCount: Int
    private let originalXfCount: Int

    private(set) var didChange = false

    // MARK: - Init

    /// Parses `stylesXML`. Returns nil only if the document has no <cellXfs> at all
    /// (not a usable styles.xml), in which case the caller should leave styles.xml
    /// untouched.
    init?(stylesXML: String) {
        self.originalXML = stylesXML
        let xml = XMLHash.parse(stylesXML)
        guard let root = xml.children.first else { return nil }

        if let fontsNode = root.children.first(where: { $0.element?.name == "fonts" }) {
            for fontEl in fontsNode.children where fontEl.element?.name == "font" {
                fonts.append(StyleTableEditor.parseFont(fontEl))
            }
        }
        if let fillsNode = root.children.first(where: { $0.element?.name == "fills" }) {
            for fillEl in fillsNode.children where fillEl.element?.name == "fill" {
                fills.append(StyleTableEditor.parseFill(fillEl))
            }
        }
        guard let xfsNode = root.children.first(where: { $0.element?.name == "cellXfs" }) else { return nil }
        for xfEl in xfsNode.children where xfEl.element?.name == "xf" {
            xfs.append(StyleTableEditor.parseXf(xfEl))
        }
        guard !xfs.isEmpty else { return nil }

        originalFontCount = fonts.count
        originalFillCount = fills.count
        originalXfCount = xfs.count
    }

    // MARK: - Public API

    /// Returns an xf index that renders `baseXf`'s appearance with the given
    /// overrides applied. `textColorHex`/`bgColorHex` are "#RRGGBB" (or nil = keep);
    /// `fontSize` is a point size (or nil = keep); `bold`/`italic` are nil = keep.
    /// Creates <font>/<fill>/<xf> entries as needed. Returns `baseXf` unchanged if
    /// nothing actually differs.
    func styleIndex(baseXf: Int, textColorHex: String?, bgColorHex: String?, fontSize: Double?,
                    bold: Bool? = nil, italic: Bool? = nil) -> Int {
        let safeBase = (baseXf >= 0 && baseXf < xfs.count) ? baseXf : 0
        let base = xfs[safeBase]

        var targetFontId = base.fontId
        if textColorHex != nil || fontSize != nil || bold != nil || italic != nil {
            var font = (base.fontId >= 0 && base.fontId < fonts.count) ? fonts[base.fontId] : (fonts.first ?? FontSpec())
            if let hex = textColorHex, let argb = StyleTableEditor.argb(fromHex: hex) {
                font.colorRgb = argb
                font.colorTheme = nil
                font.colorTint = nil
            }
            if let size = fontSize {
                font.size = size
            }
            if let bold = bold { font.bold = bold }
            if let italic = italic { font.italic = italic }
            targetFontId = findOrAppendFont(font)
        }

        var targetFillId = base.fillId
        if let hex = bgColorHex, let argb = StyleTableEditor.argb(fromHex: hex) {
            targetFillId = findOrAppendFill(FillSpec(solidFgRgb: argb, rawMarker: ""))
        }

        let fontChanged = targetFontId != base.fontId
        let fillChanged = targetFillId != base.fillId
        guard fontChanged || fillChanged else { return safeBase }

        var target = base
        target.fontId = targetFontId
        target.fillId = targetFillId
        target.applyFont = target.applyFont || fontChanged
        target.applyFill = target.applyFill || fillChanged
        return findOrAppendXf(target)
    }

    /// The rewritten styles.xml. Identical to the input when `didChange` is false.
    func serializedXML() -> String {
        guard didChange else { return originalXML }
        var xml = originalXML

        if fonts.count > originalFontCount {
            let appended = fonts[originalFontCount...].map { $0.canonical() }.joined()
            xml = spliceBeforeClose(xml, close: "</fonts>", insert: appended)
            xml = bumpCount(xml, opening: "fonts", to: fonts.count)
        }
        if fills.count > originalFillCount {
            let appended = fills[originalFillCount...].map { $0.canonical() }.joined()
            xml = spliceBeforeClose(xml, close: "</fills>", insert: appended)
            xml = bumpCount(xml, opening: "fills", to: fills.count)
        }
        if xfs.count > originalXfCount {
            let appended = xfs[originalXfCount...].map { $0.generated() }.joined()
            xml = spliceBeforeClose(xml, close: "</cellXfs>", insert: appended)
            xml = bumpCount(xml, opening: "cellXfs", to: xfs.count)
        }
        return xml
    }

    // MARK: - Find-or-append

    private func findOrAppendFont(_ spec: FontSpec) -> Int {
        let key = spec.canonical()
        if let idx = fonts.firstIndex(where: { $0.canonical() == key }) { return idx }
        fonts.append(spec)
        didChange = true
        return fonts.count - 1
    }

    private func findOrAppendFill(_ spec: FillSpec) -> Int {
        let key = spec.canonical()
        if let idx = fills.firstIndex(where: { $0.canonical() == key }) { return idx }
        fills.append(spec)
        didChange = true
        return fills.count - 1
    }

    private func findOrAppendXf(_ spec: XfSpec) -> Int {
        let key = spec.matchKey()
        if let idx = xfs.firstIndex(where: { $0.matchKey() == key }) { return idx }
        xfs.append(spec)
        didChange = true
        return xfs.count - 1
    }

    // MARK: - XML parsing helpers

    private static func parseFont(_ el: XMLIndexer) -> FontSpec {
        var f = FontSpec()
        for prop in el.children {
            switch prop.element?.name {
            case "sz":
                f.size = Double(prop.element?.allAttributes["val"]?.text ?? "")
            case "color":
                if let rgb = prop.element?.allAttributes["rgb"]?.text {
                    f.colorRgb = normalizeArgb(rgb)
                } else if let themeStr = prop.element?.allAttributes["theme"]?.text {
                    f.colorTheme = Int(themeStr)
                    f.colorTint = Double(prop.element?.allAttributes["tint"]?.text ?? "")
                }
            case "b":
                f.bold = (prop.element?.allAttributes["val"]?.text ?? "1") != "0"
            case "i":
                f.italic = (prop.element?.allAttributes["val"]?.text ?? "1") != "0"
            case "u":
                f.underline = (prop.element?.allAttributes["val"]?.text ?? "single") != "none"
            case "strike":
                f.strike = (prop.element?.allAttributes["val"]?.text ?? "1") != "0"
            case "name":
                f.name = prop.element?.allAttributes["val"]?.text
            case "family":
                f.family = prop.element?.allAttributes["val"]?.text
            case "scheme":
                f.scheme = prop.element?.allAttributes["val"]?.text
            default:
                break
            }
        }
        return f
    }

    private static func parseFill(_ el: XMLIndexer) -> FillSpec {
        guard let patternFill = el.children.first(where: { $0.element?.name == "patternFill" }) else {
            return FillSpec(solidFgRgb: nil, rawMarker: "<fill><patternFill/></fill>")
        }
        let patternType = patternFill.element?.allAttributes["patternType"]?.text ?? "none"
        if patternType == "solid",
           let fgColor = patternFill.children.first(where: { $0.element?.name == "fgColor" }),
           let rgb = fgColor.element?.allAttributes["rgb"]?.text {
            return FillSpec(solidFgRgb: normalizeArgb(rgb), rawMarker: "")
        }
        // none / gray125 / mediumGray / theme-colored fills -- not modelled, but
        // still needs a stable key so we never think a new solid fill matches one.
        var marker = "<fill><patternFill patternType=\"\(patternType)\""
        if let fg = patternFill.children.first(where: { $0.element?.name == "fgColor" }),
           let theme = fg.element?.allAttributes["theme"]?.text {
            marker += " fgTheme=\"\(theme)\""
        }
        marker += "/></fill>"
        return FillSpec(solidFgRgb: nil, rawMarker: marker)
    }

    private static func parseXf(_ el: XMLIndexer) -> XfSpec {
        var xf = XfSpec()
        let a = el.element?.allAttributes
        xf.numFmtId = Int(a?["numFmtId"]?.text ?? "") ?? 0
        xf.fontId = Int(a?["fontId"]?.text ?? "") ?? 0
        xf.fillId = Int(a?["fillId"]?.text ?? "") ?? 0
        xf.borderId = Int(a?["borderId"]?.text ?? "") ?? 0
        xf.xfId = Int(a?["xfId"]?.text ?? "") ?? 0
        xf.applyFont = (a?["applyFont"]?.text ?? "0") != "0"
        xf.applyFill = (a?["applyFill"]?.text ?? "0") != "0"
        if let alignment = el.children.first(where: { $0.element?.name == "alignment" }) {
            xf.alignHorizontal = alignment.element?.allAttributes["horizontal"]?.text
            xf.alignVertical = alignment.element?.allAttributes["vertical"]?.text
            xf.wrapText = (alignment.element?.allAttributes["wrapText"]?.text ?? "0") != "0"
        }
        return xf
    }

    // MARK: - Serialization helpers

    private func spliceBeforeClose(_ xml: String, close: String, insert: String) -> String {
        guard let range = xml.range(of: close) else { return xml }
        var out = xml
        out.replaceSubrange(range, with: insert + close)
        return out
    }

    private func bumpCount(_ xml: String, opening tag: String, to newCount: Int) -> String {
        // Matches `<tag count="123"` (any digits) so it works even when the file's
        // declared count had drifted from the real child count.
        guard let regex = try? NSRegularExpression(pattern: "<\(tag) count=\"[0-9]+\"") else { return xml }
        let ns = xml as NSString
        let fullRange = NSRange(location: 0, length: ns.length)
        guard let match = regex.firstMatch(in: xml, range: fullRange) else {
            // No count attribute at all -- add one right after `<tag`.
            if let plain = xml.range(of: "<\(tag)") {
                var out = xml
                out.replaceSubrange(plain, with: "<\(tag) count=\"\(newCount)\"")
                return out
            }
            return xml
        }
        return ns.replacingCharacters(in: match.range, with: "<\(tag) count=\"\(newCount)\"")
    }

    // MARK: - Color / number helpers

    /// "#RRGGBB" or "RRGGBB" or "AARRGGBB" -> "FFRRGGBB" (8-digit ARGB, upper-case),
    /// or nil if not a well-formed hex color.
    static func argb(fromHex hex: String) -> String? {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if h.hasPrefix("#") { h.removeFirst() }
        if h.count == 8, UInt32(h, radix: 16) != nil { return h }
        guard h.count == 6, UInt32(h, radix: 16) != nil else { return nil }
        return "FF" + h
    }

    private static func normalizeArgb(_ rgb: String) -> String {
        let h = rgb.uppercased()
        if h.count == 6 { return "FF" + h }
        return h
    }

    static func trimNumber(_ value: Double) -> String {
        if value == value.rounded() { return String(Int(value)) }
        return String(value)
    }

    private static func xmlAttr(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
