//
//  mergedCellStyle.swift
//  MultiDirectionCollectionView
//
//  Created by yujin on 2020/02/01.
//  Copyright © 2020 Credera. All rights reserved.
//

import Foundation
import UIKit

class MergedCalc{

    func mergeCalc (mergedCells:[String]) -> ([[Int]],[[Int]],[[Int]]) {
        let appd : AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        var GoodBye = [[Int]]()
        var DiffC = [[Int]]()
        var DiffR = [[Int]]()
        
        var c_size = 0
        var r_size = 0
        c_size = appd.numberofColumn
        r_size = appd.numberofRow
//        if (UserDefaults.standard.object(forKey: "NEWCsize") != nil) {
//            c_size = UserDefaults.standard.object(forKey: "NEWCsize") as! Int
//        }
//
//
//
//        if (UserDefaults.standard.object(forKey: "NEWRsize") != nil) {
//            r_size = UserDefaults.standard.object(forKey: "NEWRsize") as! Int
//        }
//
//        if appd.JSON.count > 0{
//            let index = appd.index
//            r_size = appd.JSON[index]["rSize"] as! Int
//            c_size = appd.JSON[index]["cSize"] as! Int
//
//            //            let t = UserDefaults.standard
//            //            t.set(rowsize, forKey: "NEWRsize")
//            //            t.synchronize()
//        }
    
        
        DiffC = Array(repeating: Array(repeating: 0, count: c_size), count: r_size)
        DiffR = Array(repeating: Array(repeating: 0, count: c_size), count: r_size)
        GoodBye = Array(repeating: Array(repeating: 0, count: c_size), count: r_size)
        
      
        for i in 0 ..< mergedCells.count{
            let ab = mergedCells[i]//2,2:4,4
            let abArray = ab.split(separator: ":")
            let start = abArray.first//2,2
            let end = abArray.last//4,4
            
            let start_column = String((start?.split(separator: ",").first)!)
            let start_row = String((start?.split(separator: ",").last)!)
            let scInt = Int(start_column)!
            let srowInt = Int(start_row)!
            
            let end_column = String((end?.split(separator: ",").first)!)
            let end_row = String((end?.split(separator: ",").last)!)
            let ecInt = Int(end_column)!
            let erowInt = Int(end_row)!
            
            let DIFFROW = erowInt - srowInt
            let DIFFCOLUMN = ecInt - scInt
            
            //these two has the same address
            DiffC[srowInt][scInt] = DIFFCOLUMN//
            DiffR[srowInt][scInt] = DIFFROW//
           
            
            if DIFFROW == 0{
                for k in 0..<DIFFCOLUMN+1{
                    GoodBye[srowInt][scInt+k] = -1
                }
            }else if DIFFCOLUMN == 0{
                for j in 0..<DIFFROW+1{
                    GoodBye[srowInt+j][scInt] = -1
                    
                }
            }else{
                for j in 0..<DIFFROW+1{
                    for k in 0..<DIFFCOLUMN+1{
                        GoodBye[srowInt+j][scInt+k] = -1
                    }
                }
            }
            
            GoodBye[srowInt][scInt] = 0
        }
        
        return (DiffC,DiffR,GoodBye)
    }
    
    
}
