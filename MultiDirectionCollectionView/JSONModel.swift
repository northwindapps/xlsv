//
//  JSONModel.swift
//  MultiDirectionCollectionView
//
//  Created by yujin on 2020/05/09.
//  Copyright © 2020 Credera. All rights reserved.
//

import Foundation

struct LocalJSON {
    
    let filename : String
    let date : String
    let content : [String]
    let location : [String]
    let fontsize : [String]
    let fontcolor : [String]
    let bgcolor : [String]
    let rowsize : Int
    let columnsize : Int
    let customcellWidth : [Double]
    let ccwLocation:[Int]
    let customecellHeight:[Double]
    let cchLocation:[Int]
    
    
    init( filename : String, date:String, content:[String],
          location:[String], fontsize:[String], fontcolor:[String], bgcolor:[String], rowsize:Int, columnsize:Int, customcellWidth:[Double], customcellHeight:[Double], ccwLocation:[Int], cchLocation:[Int]) {
     
        self.filename = filename as String
        self.date = date as String
        self.content = content as [String]
        self.location = location as [String]
        self.fontsize = fontsize as [String]
        self.fontcolor = fontcolor as [String]
        self.bgcolor = bgcolor as [String]
        self.rowsize = rowsize as Int
        self.columnsize = columnsize as Int
        self.customcellWidth = customcellWidth as [Double]
        self.customecellHeight = customcellHeight as [Double]
        self.ccwLocation = ccwLocation as [Int]
        self.cchLocation = cchLocation as [Int]
        //filename : [whole elements] so I can bundle all exsisting local data...never mind
        
    }
}
