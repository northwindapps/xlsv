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
        
        var GoodBye = [[Int]]()
        var DiffC = [[Int]]()
        var DiffR = [[Int]]()
        
        var c_size = 0
        var r_size = 0
        if (UserDefaults.standard.object(forKey: "NEWCsize") != nil) {
            c_size = UserDefaults.standard.object(forKey: "NEWCsize") as! Int
        }
        
        if (UserDefaults.standard.object(forKey: "NEWRsize") != nil) {
            r_size = UserDefaults.standard.object(forKey: "NEWRsize") as! Int
        }
        
        DiffC = Array(repeating: Array(repeating: 0, count: r_size), count: c_size)
        DiffR = Array(repeating: Array(repeating: 0, count: r_size), count: c_size)
        GoodBye = Array(repeating: Array(repeating: 0, count: r_size), count: c_size)
        
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
            
            DiffC[scInt][srowInt] = DIFFCOLUMN
            DiffR[scInt][srowInt] = DIFFROW
           
            
            if DIFFROW == 0{
                for k in 0..<DIFFCOLUMN{
                    GoodBye[scInt+k][srowInt] = -1
                }
            }else if DIFFCOLUMN == 0{
                for j in 0..<DIFFROW{
                    GoodBye[scInt][srowInt+j] = -1
                }
            }else{
                for j in 0..<DIFFROW{
                    for k in 0..<DIFFCOLUMN{
                        GoodBye[scInt+k][srowInt+j] = -1
                    }
                }
            }
            
            GoodBye[scInt][srowInt] = 0
        }
        
        return (DiffC,DiffR,GoodBye)
    }
    
    
}
