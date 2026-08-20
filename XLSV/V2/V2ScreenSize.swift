import UIKit

struct V2ScreenSize
{
    static let SCREEN_WIDTH         = UIScreen.main.bounds.size.width
    static let SCREEN_HEIGHT        = UIScreen.main.bounds.size.height
    static let SCREEN_MAX_LENGTH    = max(V2ScreenSize.SCREEN_WIDTH, V2ScreenSize.SCREEN_HEIGHT)
    static let SCREEN_MIN_LENGTH    = min(V2ScreenSize.SCREEN_WIDTH, V2ScreenSize.SCREEN_HEIGHT)
}
