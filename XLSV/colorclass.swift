//
//  colorclass.swift
//  MultiDirectionCollectionView
//
//  Created by yujinyano on 2018/12/28.
//  Copyright © 2018年 Credera. All rights reserved.
//
import UIKit
import Foundation




class colorclass :ViewController {
    //retrive Firebase data
    func storeValues (rl:[String],rc:[String],rsize:Int,csize:Int){
        //23,33
        let appd: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        appd.RC9 = appd.RC8
        appd.RC8 = appd.RC7
        appd.RC7 = appd.RC6
        appd.RC6 = appd.RC5
        appd.RC5 = appd.RC4
        appd.RC4 = appd.RC3
        appd.RC3 = appd.RC2
        appd.RC2 = appd.RC
        
        appd.RC = rc
        
        appd.RL9 = appd.RL8
        appd.RL8 = appd.RL7
        appd.RL7 = appd.RL6
        appd.RL6 = appd.RL5
        appd.RL5 = appd.RL4
        appd.RL4 = appd.RL3
        appd.RL3 = appd.RL2
        appd.RL2 = appd.RL
        
        appd.RL = rl
        
        appd.R_csize9 = appd.R_csize8
        appd.R_csize8 = appd.R_csize7
        appd.R_csize7 = appd.R_csize6
        appd.R_csize6 = appd.R_csize5
        appd.R_csize5 = appd.R_csize4
        appd.R_csize4 = appd.R_csize3
        appd.R_csize3 = appd.R_csize2
        appd.R_csize2 = appd.R_csize
        
        appd.R_csize = csize
        
        appd.R_rsize9 = appd.R_rsize8
        appd.R_rsize8 = appd.R_rsize7
        appd.R_rsize7 = appd.R_rsize6
        appd.R_rsize6 = appd.R_rsize5
        appd.R_rsize5 = appd.R_rsize4
        appd.R_rsize4 = appd.R_rsize3
        appd.R_rsize3 = appd.R_rsize2
        appd.R_rsize2 = appd.R_rsize
        
        appd.R_rsize = rsize
        
        
    }
    
    //
    func outValues() -> ([String],[String],Int,Int){
        //23,33
        
        
        let appd: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let outRC = appd.RC
        
        appd.RC = appd.RC2
        appd.RC2 = appd.RC3
        appd.RC3 = appd.RC4
        appd.RC4 = appd.RC5
        appd.RC5 = appd.RC6
        appd.RC6 = appd.RC7
        appd.RC7 = appd.RC8
        appd.RC8 = appd.RC9
        appd.RC9 = outRC
        
        
        let outRL = appd.RL
        
        appd.RL = appd.RL2
        appd.RL2 = appd.RL3
        appd.RL3 = appd.RL4
        appd.RL4 = appd.RL5
        appd.RL5 = appd.RL6
        appd.RL6 = appd.RL7
        appd.RL7 = appd.RL8
        appd.RL8 = appd.RL9
        appd.RL9 = outRL
        
        let outCs = appd.R_csize
        
        appd.R_csize = appd.R_csize2
        appd.R_csize2 = appd.R_csize3
        appd.R_csize3 = appd.R_csize4
        appd.R_csize4 = appd.R_csize5
        appd.R_csize5 = appd.R_csize6
        appd.R_csize6 = appd.R_csize7
        appd.R_csize7 = appd.R_csize8
        appd.R_csize8 = appd.R_csize9
        appd.R_csize9 = outCs
        
        let outRs = appd.R_rsize
        
        appd.R_rsize = appd.R_rsize2
        appd.R_rsize2 = appd.R_rsize3
        appd.R_rsize3 = appd.R_rsize4
        appd.R_rsize4 = appd.R_rsize5
        appd.R_rsize5 = appd.R_rsize6
        appd.R_rsize6 = appd.R_rsize7
        appd.R_rsize7 = appd.R_rsize8
        appd.R_rsize8 = appd.R_rsize9
        appd.R_rsize9 = outRs
        
        return (outRC,outRL,outCs,outRs)
    }
    
    
    func colorBG(tempstring:String)-> (Float, Float, Float) {
        
        if tempstring == "green"{
            
           return (Float(124.0),Float(252.0),Float(0.0))
            
        }
        else if tempstring == "cyan"{
            
           return (Float(255.0),Float(255.0),Float(0.0))
            
        }else if tempstring == "yellow"{
            
           return (Float(255.0),Float(255.0),Float(0.0))
            
        }else if tempstring == "orange"{
            
           return (Float(255.0),Float(215.0),Float(0.0))
            
        }else if tempstring == "lightgray"{
            
           return (Float(211.0),Float(211.0),Float(211.0))
            
        }else if tempstring == "magenta"{
            
           return (Float(255.0),Float(0.0),Float(255.0))
            
        }else if tempstring == "blue"{
            
           return (Float(0.0),Float(0.0),Float(255.0))
            
        }else if tempstring == "red"{
            
           return (Float(255.0),Float(0.0),Float(0.0))
            
        }else if tempstring == "brown"{
            
           return (Float(165.0),Float(42.0),Float(42.0))
            
        }else if tempstring == "purple"{
            
           return (Float(128.0),Float(0.0),Float(128.0))
            
        }else if tempstring == "darkgray"{
            
           return (Float(169.0),Float(169.0),Float(169.0))
            
        }else if tempstring == "white"{
            
           return (Float(255.0),Float(255.0),Float(255.0))
            
        }else if tempstring == "black"{
            
           return (Float(0.0),Float(0.0),Float(0.0))
        }else{
           return (Float(0.0),Float(0.0),Float(1.0))
        }
        
    }
    
    
    func colorTEXT(tempstring:String)-> (Float, Float, Float) {
        
        if tempstring == "green"{
            
            return (Float(124.0),Float(252.0),Float(0.0))
            
        }
        else if tempstring == "cyan"{
            
            return (Float(255.0),Float(255.0),Float(0.0))
            
        }else if tempstring == "yellow"{
            
            return (Float(255.0),Float(255.0),Float(0.0))
            
        }else if tempstring == "orange"{
            
            return (Float(255.0),Float(215.0),Float(0.0))
            
        }else if tempstring == "lightgray"{
            
            return (Float(211.0),Float(211.0),Float(211.0))
            
        }else if tempstring == "magenta"{
            
            return (Float(255.0),Float(0.0),Float(255.0))
            
        }else if tempstring == "blue"{
            
            return (Float(0.0),Float(0.0),Float(255.0))
            
        }else if tempstring == "red"{
            
            return (Float(255.0),Float(0.0),Float(0.0))
            
        }else if tempstring == "brown"{
            
            return (Float(165.0),Float(42.0),Float(42.0))
            
        }else if tempstring == "purple"{
            
            return (Float(128.0),Float(0.0),Float(128.0))
            
        }else if tempstring == "darkgray"{
            
            return (Float(169.0),Float(169.0),Float(169.0))
            
        }else if tempstring == "white"{
            
            return (Float(255.0),Float(255.0),Float(255.0))
            
        }else if tempstring == "black"{
            
            return (Float(0.0),Float(0.0),Float(0.0))
        }else{
            return (Float(0.0),Float(0.0),Float(1.0))
        }
        
    }
    
    
    //Increment Col
    func horribleMethod4Col(tempArray:[String],tempArrayContent:[String],colInt:Int)->([String],[String]){
    //23,33
        
        var loc = tempArray
        let con = tempArrayContent

            for i in 0..<tempArray.count {
                let twoValues = tempArray[i].split{$0 == ","}.map(String.init)
                
                if twoValues.first != nil{
                    
                    if Int(twoValues.first!)! >= colInt{
                        let newCol = Int(twoValues.first!)! + 1
                        loc[i] = String(newCol) + "," + twoValues.last!
                    }
                }
            }
     
            
        return (loc.compactMap{$0} ,con.compactMap{$0})
        
    }
    
    func horribleMethod4ColMinus(tempArray:[String],tempArrayContent:[String],colInt:Int)->([String],[String]){
        //23,33
        
        var loc = tempArray
        var con = tempArrayContent
        
       
       
        
        for i in 0..<tempArray.count {
            let twoValues = tempArray[i].split{$0 == ","}.map(String.init)
            
            if twoValues.first != nil{
            
                if Int(twoValues.first!) == colInt{
                    loc[i] = ""
                    con[i] = ""
                }else if Int(twoValues.first!)! > colInt{
                    let newCol = Int(twoValues.first!)! - 1
                    loc[i] = String(newCol) + "," + twoValues.last!
                }
            }
        }
       
         return (loc.compactMap{$0} ,con.compactMap{$0})
        
    }
    
    //Increment Row
    func horribleMethod4Row(tempArray:[String],tempArrayContent:[String],rowInt:Int)->([String],[String]){
        //23,33
        
        var loc = tempArray
        let con = tempArrayContent
        
      
            
            for i in 0..<tempArray.count {
                let twoValues = tempArray[i].split{$0 == ","}.map(String.init)
                
                if twoValues.last != nil {
                    if Int(twoValues.last!)! >= rowInt {
                        let newRow = Int(twoValues.last!)! + 1
                        loc[i] = twoValues.first! + "," + String(newRow)
                    }
                }
                
            }
        
      
        return (loc.compactMap{$0} ,con.compactMap{$0})
        
    }
    
    
    //
    func horribleMethod4RowMinus(tempArray:[String],tempArrayContent:[String],rowInt:Int)->([String],[String]){
        //23,33
        
        var loc = tempArray
        var con = tempArrayContent
        
        
        for i in 0..<tempArray.count {
            let twoValues = tempArray[i].split{$0 == ","}.map(String.init)
            
            if twoValues.last != nil {
                if twoValues.last! == String(rowInt){
                    loc[i] = ""
                    con[i] = ""
                }else if Int(twoValues.last!)! > rowInt {
                    let newRow = Int(twoValues.last!)! - 1
                    loc[i] = twoValues.first! + "," + String(newRow)
                }
            }
            
        }
    
        return (loc.compactMap{$0} ,con.compactMap{$0})
        
    }
    
    
    //
    //
    func push2FB(sourceArr:[String])->(String){
        var product_str = String()
        var tempArr = [String]()
        
        for i in 0..<sourceArr.count {
            let tempStr = sourceArr[i].replacingOccurrences(of: ",", with: "#COMMA#")
            tempArr.append(tempStr)
        }
        product_str = tempArr.joined(separator: "\n")
        return(product_str)
    }
   
    
    //
    func pullFromFB(importStr:String)->([String]){
        let str = importStr
        var product_array = [String]()
        let temp_array = str.components(separatedBy: "\n")
        
        for i in 0..<temp_array.count {
            let tempStr = temp_array[i].replacingOccurrences(of: "#COMMA#", with: ",")
            product_array.append(tempStr)
        }
        return(product_array)
    }
    
}
