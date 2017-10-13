//
//  ReportMaker.swift
//  MySQLSampleOSX
//
//  Created by william donner on 9/14/17.
//

import Foundation

public enum ReportKind:String {
    case samples
    case heartless
    case topposts
    
   public static  func make(s:String) -> ReportKind?  {
        return rk.findreport(s)
        
    }
    
    func findreport(_ s:String) -> ReportKind? {
        let xx:[String:ReportKind]  = ["samples":.samples,"heartless":.heartless,"topposts":.topposts]
        return xx[s]
    }
    typealias ReportCallback = (([String], [[String]],TimeInterval)->Void)
    
    func anyreport(_ userid:String,name:ReportKind, callback:ReportCallback) ->  Bool  {
     
        do {
            
            print("\n\n")
            
        switch name {
        case .samples:
            try  samplesReport(userid,callback:callback)
        case .heartless:
            try  heartlessReport(userid,callback:callback)
        case .topposts:
            try  toppostsReport(userid,callback:callback)
        }
        }
        catch {
            print("problem generating \(name) for \(userid)")
            return  false
        }
        return  true
    }
    
    // run the report and copy out the results, call the callback
    func rep (stmnt:String,tag:String,  callback:ReportCallback ) throws {
        let st = Date()
         var repheader:[String] = []
        var repdata : [[String]] = []
        var first = true
        try zh.iselectfrom( stmnt, args: [ ]) { rows in
        
            for ff in rows {
                var line:[String] = []
                if first {
                    print("REPORT: \(tag) ")
                    print ("  fields: \(ff.map{$0.key})")
                    for f in ff {
                        repheader.append("\(f.0)")
                    }
                    print("RESULTS:")
                }
                let ny = "\(ff.map{$1})"
                print (" ",ny)
                for f in ff {
                line.append("\(f.1)")
                }
                repdata.append(line)
                first = false
            }
            
            let elapsed = Date().timeIntervalSince(st)*1000
            callback(repheader,repdata,elapsed)
            let x = String(format:"%0.2f",elapsed)
            print("  \(x)ms READY> ")
        }
    }//rep

    private func samplesReport(_ userid:String , callback:ReportCallback) throws  {
       
        func printrowsOfTable(_ table:String,args:[Any],limit:Int = 10 ) throws {
            var first = true
            try zh.iselectfrom(  "SELECT * FROM \(table) LIMIT \(limit)", args: args) { rows in
                for ff in rows {
                    if first {
                        print ("Table - \(table) \(ff.map{$0.key})")
                    }
                    print (ff.map{$1})
                    first = false
                }
            }
        }
        func roze(_ s:String,_ args:[Any]) {
            do {
                try printrowsOfTable(s,args: []) // pass empty arglist for now
            }
            catch {
                print("Could not select from  \(s) \(error)")
            }
        }
        
        print("Samples")
        print("=============")
        roze("userblocks", ["192839"])
        roze("iguser", ["12312"])
        roze("followingblocks", ["192839"])
        roze("followerblocks", ["192839"])
        roze("requestedbyblocks", ["192839"])
        roze("mediavideos", ["3Bfas"])
        roze("mediaimages", ["3BXZ5"])
        roze("mediatagged", ["3Bfas"])
        roze("commentsofmedia",["3Bfas"])
        roze("likersofmedia",["3Bfas"])
        roze("likesdatablocks",["3Bfas"])
        roze("mediadatablocks",["3Bfas"])
    }
}
extension ReportKind {
    
    fileprivate func toppostsReport(_ userid:String  , callback:ReportCallback) throws   {
        let stmnt = """
SELECT mediaid  post_that_is_liked,
          userid   userid_of_liker ,
          Count(*) liker_count
   FROM   likersofmedia
   GROUP  BY mediaid,
             userid
             ORDER  BY post_that_is_liked,userid_of_liker,
          liker_count DESC
"""
        let tag = "top posts"
        return try rep(stmnt:stmnt,tag:tag , callback:callback )
        
    }
    fileprivate func heartlessReport(_ userid:String, callback:ReportCallback ) throws  {
        let stmnt = """
-- following not followers
-- SELECT 'CREATING IIGNOTER -  FOLLOWINGS NOT IN FOLLOWERS' AS 'FAN-ONLYS';
 (SELECT followingblocks.*
    FROM   followingblocks
             LEFT JOIN followerblocks
                   ON followingblocks.userid = followerblocks.iguserid
                       AND followerblocks.userid = followingblocks.iguserid
         WHERE  followerblocks.userid IS NULL);
"""
        let tag = "heart less"
        return try rep(stmnt:stmnt,tag:tag, callback:callback )
    }
}
