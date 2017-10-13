//
//  sqlartest.swift
//  MySQLSampleOSX
//
//  Created by william donner on 9/11/17.
//

import Foundation
  func selectallTest( ) {
    
    func dose(_ s:String,_ args:[Any]) {
        do {
            try zh.iselectfrom(s,args: []) {_ in 
                
            }// pass empty arglist for now
        }
        catch {
            print("Could not select from  \(s) \(error)")
        }
    }
    dose("userblocks", ["192839"])
    dose("iguser", ["12312"])
    dose("followingblocks", ["192839"])
    dose("followerblocks", ["192839"])
    dose("requestedbyblocks", ["192839"])
    dose("mediavideos", ["3Bfas"])
    dose("mediaimages", ["3BXZ5"])
    dose("mediatagged", ["3Bfas"])
    dose("commentsofmedia",["3Bfas"])
    dose("likersofmedia",["3Bfas"])
    dose("likesdatablocks",["3Bfas"])
    dose("mediadatablocks",["3Bfas"])
    
}

func insertallTest( ) {
    
    zh.likesdatablocksInsert(mediaid: "3Bfas", filter:  "green", type: "anime", link: "http://ks", countcomments: 3, countlikes: 2, user_has_liked: 1, caption_text: "bigley", caption_created_time: " 000", caption_id: "9999", caption_from_id: "S878", location_id:UInt64(234234), iguserid: "12312", created_time: "1234")
    
    
    zh.mediadatablocksInsert(mediaid: "3Bfas", filter:  "green", type: "anime", link: "http://ks", countcomments: 3, countlikes: 2, user_has_liked: 1, caption_text: "bigley", caption_created_time: " 000", caption_id: "9999", caption_from_id: "S878", location_id:  UInt64(234234) , iguserid: "12312", created_time: "1234")
    
    zh.likersofmediaInsert(mediaid: "3Bfas",userid:  "192839",iguserid: "12312")
    zh.commentsofmediaInsert(mediaid: "3Bfas", comment: "oerfecti:", userid:  "192839" , created_time: "000", iguserid: "12312")
    zh.mediaTaggedInsert(mediaid: "3Bfas",tag:"FOOTAG", iguserid:  "12312")
    zh.mediaVideosInsert(mediaid: "3Bfas", url: "http://vidblah", width: 300, height: 200, iguserid:  "12312")
    zh.mediaImagesInsert(mediaid: "3BXZ5", url: "http://blah", width: 300, height: 200, iguserid:  "12312")
    zh.userblocksInsert(userid: "192839", username: "bdonner", full_name: "bill donner", profile_picture: "http:billdnner,con", iguserid:  "12312")
    zh.iguserInsert(bio:"go away",  username: "bdonner", full_name: "bill donner", profile_picture: "http:billdonner.com", website:"http://billdonner.com", iguserid:  "12312")
    zh.followingblocksInsert(userid:"192839", iguserid: "12312")
    zh.followerblocksInsert(userid:"192839", iguserid: "12312")
    zh.requestedbyblocksInsert(userid:"192839", iguserid: "12312")
    
}
