//
//  AppDelegate.swift
//  MultiDirectionCollectionView
//
//  Created by Kyle Andrews on 3/21/15.
//  Copyright (c) 2015 Credera. All rights reserved.


import UIKit
//import GoogleMobileAds
//import GoogleSignIn

// One entry per committed cell edit at runtime -- the eventual goal is to
// replay/apply these onto loadedSheetXML to write a sheetN.xml back out that
// keeps every original property CoreXLSX doesn't round-trip (styles, borders,
// merges, etc.) and only patches in what actually changed.
struct CellEditRecord {
    let location: String // "column,row" key, matches ViewController's IPd/location format
    let oldValue: String
    let newValue: String
    let timestamp: Date
}

@UIApplicationMain
//https://stackoverflow.com/questions/46648834/ld-entry-point-main-undefined-for-architecture-x86-64-xcode-9
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var radigree = 0
    var accessID = String()
    var isAppStarted = false
    
    //StringFormat
    var FONT_SIZE_DEFAULT = 12
    var fontcolor = 10
    var labelcolor = 5
    var fontbackground = 15
    var labelborderclear = 0
    var fontitalic = 0
    var fontbold = 0
    
    var cswLocation = [Int]()
    var customSizedWidth = [Double]()
    var cshLocation = [Int]()
    var customSizedHeight = [Double]()
    var cswLocation_temp = [Int]()
    var customSizedWidth_temp = [Double]()
    var cshLocation_temp = [Int]()
    var customSizedHeight_temp = [Double]()

    // Row filter (FileFillViewController's Datafilter dialog). When active,
    // display section i+1 shows real row visibleRows[i] -- content/location
    // keep their real row numbers untouched, only the render/layout
    // coordinate space is compacted. ViewController never sets these, so its
    // own grid is unaffected.
    var rowFilterActive = false
    var visibleRows: [Int] = []
    //
//    var border_ids = [Int]()
//    var borders_left_style = [String]()
//    var borders_right_style = [String]()
//    var borders_top_style = [String]()
//    var borders_bottom_style = [String]()
//    var borders_left_color = [String]()
//    var borders_right_color = [String]()
//    var borders_top_color = [String]()
//    var borders_bottom_color = [String]()
    var index_border_id = [String: String]()
    var diff_start_index = [String]()
    var diff_end_index = [String]()
    var cellIndex = IndexPath()
    var wsSheetIndex = 1
    var imported_xlsx_file_path=""
    // Same handoff mechanism as imported_xlsx_file_path (set by BackupTableViewController,
    // claimed once by the receiving controller's viewDidLoad), but dedicated to ViewController
    // restores specifically -- imported_xlsx_file_path is FileFillViewController's own field
    // (and the generic one PlaygroundViewController reads), so BackupTableViewController needs
    // a separate field to hand a Spreadsheet restore to ViewController without it colliding
    // with whatever FileFillViewController last left on the shared field.
    var imported_xlsx_file_path_ss=""
    // Global user setting controlling whether storeInput() triggers a full
    // whole-sheet calculatormode_update_main() (formulas stay live everywhere,
    // but O(formulas * literals) cost -- a confirmed crash risk on very large
    // sheets) or the scoped recalculateSingleCell() (only the edited cell
    // updates immediately; other formulas referencing it go stale until
    // themselves re-entered). Read by both ViewController.storeInput and
    // FileFillViewController.storeInput. Defaults to true (full recalc) to
    // match the app's prior unconditional behavior.
    var fullFormulaRecalcEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: "fullFormulaRecalcEnabled") == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: "fullFormulaRecalcEnabled")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "fullFormulaRecalcEnabled")
        }
    }
    // Raw XML text of the currently loaded worksheet part (e.g. xl/worksheets/sheet1.xml),
    // captured as-is at import time in ExcelHelper.readExcel2 -- CoreXLSX only exposes a
    // decoded Worksheet struct, not the original markup, so this is read independently via
    // ZIPFoundation. Needed as the source-of-truth base for eventually writing a sheetN.xml
    // back out that preserves whatever CoreXLSX's model doesn't round-trip.
    var loadedSheetXML = ""
    var editHistory = [CellEditRecord]()
    var excelStyleIdx = [Int]()
    var excelStyleLocation = [String]()
    var excelStyleLocationAlphabet = [String]()
    var cellXfs = [Int]()
    var cellStyleXfs = [Int]()
    var border_lefts = [Int]()
    var border_rights = [Int]()
    var border_bottoms = [Int]()
    var border_tops = [Int]()
    // Actual per-side border style name (e.g. "thin") and "#RRGGBB" color, indexed
    // by borderId in lockstep with border_lefts/rights/tops/bottoms above.
    var borderLeftStyles = [String]()
    var borderLeftColors = [String]()
    var borderRightStyles = [String]()
    var borderRightColors = [String]()
    var borderTopStyles = [String]()
    var borderTopColors = [String]()
    var borderBottomStyles = [String]()
    var borderBottomColors = [String]()
    var formatCodes = [String]()
    var numFmts = [String]()
    var numFmtIds = [Int]()

    // fontId/fillId per style index (position in <cellXfs>), parallel to cellXfs/numFmtIds.
    var xfFontIds = [Int]()
    var xfFillIds = [Int]()
    // Alignment, also per style index -- unlike font/fill/border, <alignment> is inline
    // on each <xf> rather than a separate lookup table, so these read directly off the
    // style index with no extra id indirection.
    var xfHorizontalAligns = [String]()
    var xfVerticalAligns = [String]()
    var xfWrapTexts = [Bool]()
    // Font table, indexed by fontId (position in <fonts>).
    var fontSizes = [String]()
    var fontColors = [String]()
    var fontBolds = [Bool]()
    var fontItalics = [Bool]()
    var fontUnderlines = [Bool]()
    var fontStrikes = [Bool]()
    // Fill table, indexed by fillId (position in <fills>) -- only solid-pattern fills
    // resolve to a color; others are left as "".
    var fillColors = [String]()
    // xl/theme/theme1.xml's clrScheme resolved into a 12-slot "#RRGGBB" table, indexed
    // the way <color theme="N"/> actually refers to slots (lt1, dk1, lt2, dk2, accent1-6,
    // hlink, folHlink) -- see Service.testExtractTheme.
    var themeColors = [String]()


    //
    var CELL_HEIGHT_INIT = 40.0
    var CELL_WIDTH_INIT = 100.0
    let DEFAULT_ROW_NUMBER = 1001
    let DEFAULT_COLUMN_NUMBER = 201
    var CELL_HEIGHT_EXCEL_GSHEET = 30.0
    var CELL_WIDTH_EXCEL_GSHEET = 100.0
    

    //workbook info
    var sheetNameIds = [String]()
    var sheetNames = [String]()
    
    
    var tag_int = 0

    
    var numberofRow = 0
    var numberofColumn = 0
    var exportContent=[String]()
    var exportContent_location=[String]()
    var currentindex_trip : IndexPath!
    var wentWrong = false

    //
    var RL = [String]()
    var RC = [String]()
    var RL2 = [String]()
    var RC2 = [String]()
    var RL3 = [String]()
    var RC3 = [String]()
    var RL4 = [String]()
    var RC4 = [String]()
    var RL5 = [String]()
    var RC5 = [String]()
    var RL6 = [String]()
    var RC6 = [String]()
    var RL7 = [String]()
    var RC7 = [String]()
    var RL8 = [String]()
    var RC8 = [String]()
    var RL9 = [String]()
    var RC9 = [String]()
    
    var R_rsize = Int()
    var R_csize = Int()
    var R_rsize2 = Int()
    var R_csize2 = Int()
    var R_rsize3 = Int()
    var R_csize3 = Int()
    var R_rsize4 = Int()
    var R_csize4 = Int()
    var R_rsize5 = Int()
    var R_csize5 = Int()
    var R_rsize6 = Int()
    var R_csize6 = Int()
    var R_rsize7 = Int()
    var R_csize7 = Int()
    var R_rsize8 = Int()
    var R_csize8 = Int()
    var R_rsize9 = Int()
    var R_csize9 = Int()

    
    //
    var collectionViewCellSizeChanged = -1
    
    var excelfilename = ""
    
    var lastLaunchDate: Date = {
        return UserDefaults.standard.object(forKey: "lastLaunchDateKey") as? Date ?? Date(timeIntervalSince1970: 0)
    }()
    
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
        
        // Override point for customization after application launch.
        self.window = UIWindow(frame: UIScreen.main.bounds)
        // An unset UIWindow background defaults to black, which flashes through any
        // transient gap in the view hierarchy during layout/rotation. The app's own
        // colors (spreadsheet grid, cells) are all hardcoded light and not Dark-Mode
        // aware, so pin both the window background and interface style to light to
        // remove the black side of the white/black flicker rather than just papering
        // over one trigger of it.
        self.window?.backgroundColor = .white
        self.window?.overrideUserInterfaceStyle = .light
        let storyboard = UIStoryboard(name: "Manager", bundle: nil)

        if(DeviceType.IS_IPHONE_4_OR_LESS == true)
        {
            //storyboard = UIStoryboard(name: "Small", bundle: nil)
            tag_int = 3
            
        }
        else if(DeviceType.IS_IPHONE_5==true)
        {
            tag_int = 3
        }
        else if(DeviceType.IS_IPHONE_6==true)
        {
            //storyboard = UIStoryboard(name: "Large", bundle: nil)
            tag_int = 3
            
        }
        else if(DeviceType.IS_IPHONE_6P)
        {
            //storyboard = UIStoryboard(name: "XLarge", bundle: nil)
            tag_int = 3
        }
        else if(DeviceType.IS_IPAD)
        {
            //storyboard = UIStoryboard(name: "iPad", bundle: nil)
            tag_int = 4
        }
        else if(DeviceType.IS_IPAD_PRO)
        {
            //storyboard = UIStoryboard(name: "iPadP", bundle: nil)
            tag_int = 5
        }

        
        
        // Runs regardless of which mode (v2 Classic or v3) the user opens first -- this is a
        // pure FileManager move on Documents/sub/, no UI/engine dependency, and it's the only
        // thing that makes 1.3.6-era legacy sheets ever become visible again (see
        // V2LegacyMigration.swift). Idempotent, safe to call on every launch.
        V2LegacyMigration.migrateLegacySheetsIfNeeded()

        let initialViewController = storyboard.instantiateViewController(withIdentifier: "Home")




        self.window?.rootViewController = initialViewController
        self.window?.frame = self.window!.bounds
        self.window?.makeKeyAndVisible()

        return true

    }

    // Lets Mail/Gmail/Files hand an .xlsx attachment straight to this app via
    // "Open in XLSV"/"Copy to XLSV" -- requires the UTI declarations in
    // Info.plist (CFBundleDocumentTypes + UTImportedTypeDeclarations for
    // org.openxmlformats.spreadsheetml.sheet) for iOS to offer XLSV in that
    // list at all; this handler is where the OS lands once the user picks it.
    //
    // Mirrors iCloudViewController.documentPicker(_:didPickDocumentAt:)'s xlsx
    // branch + replaceLocalFileWithImportedOne() (isFileFillMode branch):
    // stage the incoming file, unzip it via Service.testSandBox (populates
    // appd.themeColors/style tables -- still required even though readExcel2
    // does its own independent parse later, same as every other import path
    // in this app), then land it at importedExcel/initialXLSX_ff.xlsx.
    // FileFillViewController's own viewDidLoad already loads from that
    // well-known default path whenever appd.imported_xlsx_file_path is empty,
    // so a freshly-instantiated FileFillViewController picks this up with no
    // extra plumbing -- same as a cold launch with no prior file would.
    //
    // Lands in Form Fill mode (FileFillViewController), not Spreadsheet --
    // changed 2026-08-16 per explicit request.
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard url.pathExtension.lowercased() == "xlsx" else { return false }

        let pathDirectory = ExcelHelper().getRootDocumentsDirectory()
        let stagedURL = pathDirectory.appendingPathComponent(url.lastPathComponent)

        do {
            if FileManager.default.fileExists(atPath: stagedURL.path) {
                try FileManager.default.removeItem(at: stagedURL)
            }
            // Mail/Gmail hand off a copy already sitting in this app's own
            // Inbox folder -- moveItem both relocates it out of Inbox (which
            // iOS expects the receiving app to clean up) and avoids a
            // separate copy+delete step.
            try FileManager.default.moveItem(at: url, to: stagedURL)
        } catch {
            print("Open-in xlsx: failed to stage incoming file: \(error)")
            return false
        }

        excelfilename = url.lastPathComponent
        imported_xlsx_file_path = stagedURL.path

        let serviceInstance = Service(imp_sheetNumber: 0, imp_stringContents: [String](), imp_locations: [String](), imp_idx: [Int](), imp_fileName: "", imp_formula: [String]())
        _ = serviceInstance.testSandBox(fp: stagedURL.path)

        let destinationFilePath = pathDirectory.appendingPathComponent("importedExcel").appendingPathComponent("initialXLSX_ff.xlsx")
        do {
            try FileManager.default.createDirectory(at: destinationFilePath.deletingLastPathComponent(), withIntermediateDirectories: true)
            // Same non-backup "Import" branch replaceLocalFileWithImportedOne()
            // uses -- replaceItemAt succeeds whether or not destinationFilePath
            // already exists, and consumes (deletes) stagedURL as part of the
            // atomic replace.
            try FileManager.default.replaceItemAt(destinationFilePath, withItemAt: stagedURL)
            imported_xlsx_file_path = destinationFilePath.path
        } catch {
            print("Open-in xlsx: failed to finalize import: \(error)")
            return false
        }

        let storyboard = UIStoryboard(name: "V3", bundle: nil)
        let target = storyboard.instantiateViewController(withIdentifier: "Filefill") as! FileFillViewController
        target.isExcel = true
        target.modalPresentationStyle = .fullScreen

        // Same dismiss-then-unconditional-swap pattern the
        // rootViewController-swap-leak fix established (see memory) --
        // window.rootViewController might currently be HomeController (cold
        // launch) or an already-open FileFillViewController/ViewController/
        // PlaygroundViewController (app already running); dismiss whatever's
        // presented on top of it first so the swap below doesn't leak a
        // presenter<->presented retain cycle, and perform the swap
        // unconditionally right after rather than nesting it in dismiss's
        // completion (nesting it broke "Exit Playground" previously -- see
        // memory for why).
        window?.rootViewController?.dismiss(animated: false, completion: nil)
        window?.rootViewController = target
        window?.makeKeyAndVisible()

        return true
    }


    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        // Both FileFillViewController and ViewController defer xlsx writes to
        // memory (pendingXlsxChanges, see PendingXlsxChangeSet.swift) until an
        // explicit Save/Export or a sheet-management op -- unlike the old
        // eager per-edit write, a background/kill with edits still unflushed
        // would previously lose them silently, with no crash and no error.
        // Flush here as a safety net so backgrounding (including the app then
        // being killed while backgrounded, e.g. under memory pressure)
        // durably saves whatever was pending. Overwriting the real file in
        // place is fine -- that's exactly what flushPendingXlsxChangesIfNeeded
        // already does for an explicit Save. window.rootViewController is
        // whichever mode is currently active (mode switches swap
        // rootViewController directly; transient modals like Settings/Backups
        // are presented on top of it, not swapped in), so this check finds
        // it regardless of what's presented above it.
        let flush: () -> Bool
        if let ff = window?.rootViewController as? FileFillViewController {
            flush = { ff.flushPendingXlsxChangesIfNeeded() }
        } else if let vc = window?.rootViewController as? ViewController {
            flush = { vc.flushPendingXlsxChangesIfNeeded() }
        } else {
            return
        }

        // unzip+splice+rezip on a large xlsx (e.g. a 100k-row/47MB file) can
        // take longer than iOS's default ~5s grace period before suspending a
        // backgrounded app -- request extra time so the write isn't cut off
        // mid-rezip, which could otherwise corrupt the file this is trying to
        // protect.
        var bgTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
        bgTask = application.beginBackgroundTask(withName: "FlushPendingXlsxChangesOnBackground") {
            application.endBackgroundTask(bgTask)
            bgTask = UIBackgroundTaskInvalid
        }

        _ = flush()

        if bgTask != UIBackgroundTaskInvalid {
            application.endBackgroundTask(bgTask)
            bgTask = UIBackgroundTaskInvalid
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        
    }

}


//http://stackoverflow.com/questions/26028918/ios-how-to-determine-iphone-model-in-swift/26962452#26962452
public extension UIDevice {
    
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                 return "iPod Touch 5"
        case "iPod7,1":                                 return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
        case "iPhone4,1":                               return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
        case "iPhone7,2":                               return "iPhone 6"
        case "iPhone7,1":                               return "iPhone 6 Plus"
        case "iPhone8,1":                               return "iPhone 6s"
        case "iPhone8,2":                               return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
        case "iPhone8,4":                               return "iPhone SE"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
        case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
        case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
        case "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8":return "iPad Pro"
        case "AppleTV5,3":                              return "Apple TV"
        case "i386", "x86_64":                          return "Simulator"
        default:                                        return identifier
        }
    }
    
}

enum UIUserInterfaceIdiom : Int
{
    case unspecified
    case phone
    case pad
}

struct ScreenSize
{
    static let SCREEN_WIDTH         = UIScreen.main.bounds.size.width
    static let SCREEN_HEIGHT        = UIScreen.main.bounds.size.height
    static let SCREEN_MAX_LENGTH    = max(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
    static let SCREEN_MIN_LENGTH    = min(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
}

struct DeviceType
{
    static let IS_IPHONE_4_OR_LESS  = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH < 568.0
    static let IS_IPHONE_5          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 568.0
    static let IS_IPHONE_6          = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 667.0
    static let IS_IPHONE_6P         = UIDevice.current.userInterfaceIdiom == .phone && ScreenSize.SCREEN_MAX_LENGTH == 736.0
    static let IS_IPAD              = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.SCREEN_MAX_LENGTH == 1024.0
    static let IS_IPAD_PRO          = UIDevice.current.userInterfaceIdiom == .pad && ScreenSize.SCREEN_MAX_LENGTH == 1366.0
}



