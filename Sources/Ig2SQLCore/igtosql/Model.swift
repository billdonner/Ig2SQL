//
//  Model.swift
//  sql4ig
//
//  Created by william donner on 9/8/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation

class Model: Codable {
    var user : Instagramm.IgUser = Instagramm.IgUser(id: "0", username:  "",full_name: "", profile_picture: "",  bio:  " ", website:  "", counts: Instagramm.Counts(media: 0, follows: 0, followed_by: 0))
    var followers: Set<Instagramm.UserBlock> = Set()
    var followings: Set<Instagramm.UserBlock> = Set()
    var requestedby: Set<Instagramm.UserBlock> = Set()
    var commentdata:  [String:Instagramm.CommentBlock] = [:]
    var mediadata:  [String:Instagramm.MediaBlock] = [:]
    var likesdata: [String:Instagramm.MediaBlock] = [:]
    var likersOf: [String:Set<String>] = [:]
    var commentsAboutMedia: [String:Set<String>] = [:]
    var miniseen: String? // computed by scanning mediadatablocks
    var lastApiStatus:Int = 100
   // var globalBuckets =  APIBuckets()
    
    var cyclestart = Date()
    var cyclelastcompleted = Date()
    var cycleelapsed : TimeInterval = 0.0
    var cyclenumber = 100001 // starts here
    
    convenience init(user:Instagramm.IgUser,followers:Set<Instagramm.UserBlock>,followings:Set<Instagramm.UserBlock>,requestedby:Set<Instagramm.UserBlock>,mediadata:[String:Instagramm.MediaBlock] ,likesdata:[String:Instagramm.MediaBlock] ) {
        self.init()
        self.user = user
        self.followers = followers
        self.followings = followings
        self.requestedby = requestedby
        self.mediadata = mediadata
        self.likesdata = likesdata
    }
    func dump() {
        print("count of mediatdata is \(mediadata.count)")
        print("count of likesdata is \(likesdata.count)")
    }
} 
