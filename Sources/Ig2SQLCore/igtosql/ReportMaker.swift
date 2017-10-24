//
//  ReportMaker.swift
//  MySQLSampleOSX
//
//  Created by william donner on 9/14/17.
//

import Foundation

public typealias ReportCallback = (([String], [[String]],TimeInterval)->Void)
public enum ReportKind:String {

    case heartless
    case topposts
    
    public static  func make(s:String) -> ReportKind?  {
        let xx:[String:ReportKind]  = ["heartless":.heartless,"topposts":.topposts]
        return xx[s]
    } 
    
    public static   func anyreport(_ userid:String,name:ReportKind, callback:ReportCallback) ->  Bool  {
        
        do {
            
            print("\n\n")
            
            switch name {
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


}
extension ReportKind {
    
    fileprivate static func toppostsReport(_ userid:String  , callback:ReportCallback) throws   {
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
        return try SQLMaker.rep(stmnt:stmnt,tag:tag , callback:callback )
        
    }
    fileprivate static func heartlessReport(_ userid:String, callback:ReportCallback ) throws  {
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
        return try SQLMaker.rep(stmnt:stmnt,tag:tag, callback:callback )
    }
}
