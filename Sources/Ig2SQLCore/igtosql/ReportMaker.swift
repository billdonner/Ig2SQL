//
//  ReportMaker.swift
//  MySQLSampleOSX
//
//  Created by william donner on 9/14/17.
//

import Foundation

public enum ReportKind {
    case samples
    case heartless
    case topposts
    
   public static  func freport(s:String) -> ReportKind?  {
        return rk.findreport(s)
        
    }
    
    func findreport(_ s:String) -> ReportKind? {
        let xx:[String:ReportKind]  = ["samples":.samples,"heartless":.heartless,"topposts":.topposts]
        return xx[s]
    }
    func anyreport(_ userid:String,name:ReportKind){
        do {
            
            print("\n\n")
            
        switch name {
        case .samples:
            try samplesReport(userid)
        case .heartless:
            try heartlessReport(userid)
        case .topposts:
            try toppostsReport(userid)
        }
        }
        catch {
            print("problem generating \(name) for \(userid)")
        }
        
    }
    
    func rep (stmnt:String,tag:String) throws {
        
      
        var first = true
        try iselectfrom( stmnt, args: [ ]) { rows in
            for ff in rows {
                if first {
                    print("REPORT:")
                    print ("\(tag) \(ff.map{$0.key})")
                    print("RESULTS:")
                }
                print ("   \(ff.map{$1})")
                first = false
            }
        }
    }//rep

    private func samplesReport(_ userid:String ) throws {
       
        func printrowsOfTable(_ table:String,args:[Any],limit:Int = 10 ) throws {
            var first = true
            try iselectfrom(  "SELECT * FROM \(table) LIMIT \(limit)", args: args) { rows in
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
    
    fileprivate func toppostsReport(_ userid:String ) throws {
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
        try rep(stmnt:stmnt,tag:tag)
        
    }
    fileprivate func heartlessReport(_ userid:String ) throws {
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
        try rep(stmnt:stmnt,tag:tag)
    }
}
