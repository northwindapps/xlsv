//
//  AppDelegate.swift
//  MultiDirectionCollectionView
//
//  Created by Kyle Andrews on 3/21/15.
//  Copyright (c) 2015 Credera. All rights reserved.


import UIKit
import GoogleMobileAds
import GoogleSignIn

@UIApplicationMain
//https://stackoverflow.com/questions/46648834/ld-entry-point-main-undefined-for-architecture-x86-64-xcode-9
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var radigree = 0
    var accessID = String()
    
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
    //
    var border_ids = [Int]()
    var borders_left_style = [String]()
    var borders_right_style = [String]()
    var borders_top_style = [String]()
    var borders_bottom_style = [String]()
    var borders_left_color = [String]()
    var borders_right_color = [String]()
    var borders_top_color = [String]()
    var borders_bottom_color = [String]()
    var index_border_id = [String: String]()
    var diff_start_index = [String]()
    var diff_end_index = [String]()
    var cellIndex = IndexPath()
    var ws_path = ""
    var wsIndex = 1
    var imported_xlsx_file_path=""
    //
    var CELL_HEIGHT_INIT = 40.0
    var CELL_WIDTH_INIT = 100.0
    let DEFAULT_ROW_NUMBER = 51
    let DEFAULT_COLUMN_NUMBER = 30
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
    
//    func application(
//      _ app: UIApplication,
//      open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]
//    ) -> Bool {
//      var handled: Bool
//
//      handled = GIDSignIn.sharedInstance.handle(url)
//      if handled {
//        return true
//      }
//
//      // Handle other custom URL types.
//
//      // If not handled by this app, return false.
//      return false
//    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
        
        // Override point for customization after application launch.
        self.window = UIWindow(frame: UIScreen.main.bounds)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
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

        //
        if (UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH") != nil) {
            customSizedWidth = UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT") != nil) {
            customSizedHeight = UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH_LOCATION") != nil) {
            cswLocation = UserDefaults.standard.object(forKey: "NEW_CELL_WIDTH_LOCATION") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT_LOCATION") != nil) {
            cshLocation = UserDefaults.standard.object(forKey: "NEW_CELL_HEIGHT_LOCATION") as! Array
        }
        
        if (UserDefaults.standard.object(forKey: "FONT_SIZE_DEFAULT ") != nil) {
            FONT_SIZE_DEFAULT  = UserDefaults.standard.object(forKey: "FONT_SIZE_DEFAULT ") as! Int
        }
        
        var initialViewController = storyboard.instantiateViewController(withIdentifier: "StartLine")//googleSignIn
        
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if (error != nil || user == nil) {
                // Show the app's signed-out state.
                print("sign out")
                initialViewController = storyboard.instantiateViewController(withIdentifier: "StartLine")//googleSignIn
            } else {
                // Show the app's signed-in state.
                print("sign in")
                //let initialViewController = storyboard.instantiateViewController(withIdentifier: "StartLine")
                initialViewController = storyboard.instantiateViewController(withIdentifier: "StartLine")//googleDrive
            }
        }
        
        self.window?.rootViewController = initialViewController
        self.window?.frame = self.window!.bounds
        self.window?.makeKeyAndVisible()
        
        return true

    }
    
//    func application(
//      _ application: UIApplication,
//      didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//    ) -> Bool {
//      GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
//        if error != nil || user == nil {
//          // Show the app's signed-out state.
//        } else {
//          // Show the app's signed-in state.
//        }
//      }
//      return trues
//    }
//
   

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
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



