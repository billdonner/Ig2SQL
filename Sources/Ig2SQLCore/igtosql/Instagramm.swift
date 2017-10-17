//
//  Instagramm
//  igr
//
//  Created by william donner on 7/9/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation
protocol Mergeable  {
    var id: String {get}
}

public protocol IGResponse {
    var meta : Instagramm.Meta {get}
    var pagination: Instagramm.Pagination? {get}
}


public struct  Instagramm {
    // MARK: - non generic
    
    // things that come back from Instagram across all APIs
    struct ImageSpec: Codable { //
        let url:String
        let width:Int
        let height:Int
    }
    struct LocationSpec: Codable { //
        let latitude: Double
        let longitude: Double
        let id: UInt64 // wierd
        let street_address: String?
        let name: String?
    }
    struct Comments: Codable {
        let count: Int
    }
    struct Likes: Codable {
        let count: Int
    }
    struct Caption: Codable { //
        let created_time: String
        let text: String
        let from: FromBlock
        let id: String
    }
    struct FromBlock: Codable { //
        let username: String
        let full_name: String
        let profile_picture : String
        let id: String
    }
 
    
    // the UserBlock covers followers, followings, and requesed-by            
    public  struct UserBlock: Codable,Mergeable,Hashable {
        public static func ==(lhs: Instagramm.UserBlock, rhs: Instagramm.UserBlock) -> Bool {
             return lhs.id == rhs.id
        }
        
        let username: String
        let full_name:String
        let profile_picture: String
        let id: String
        public var hashValue: Int {
            return id.hashValue
        }
    }
    struct PositionBlock: Codable { //
        let x: Double
        let y: Double
    }
    struct UserAndPosition: Codable {
        let user: UserBlock
        let position: PositionBlock
    }
    struct Counts: Codable {
        let media: Int
        let follows: Int
        let followed_by:Int
    }
    struct Attribution: Codable {
        
    }
    struct CarouselBlock : Codable{
        enum  kind {
            case images
            case video
        }
        let users_in_photo: [UserAndPosition]
        let type: String 
    }
    
    // this structure comes from IG
    public struct CommentBlock:Codable,Mergeable {
        let created_time:String//
        let text:String
        let from:UserBlock//
        let id: String
    }
    public struct MediaBlock: Codable,Mergeable,Hashable {
        public static func ==(lhs: Instagramm.MediaBlock, rhs: Instagramm.MediaBlock) -> Bool {
            return lhs.id == rhs.id
        }
        public var hashValue: Int {
            return id.hashValue
        }
        let attribution: Attribution? // found in stream
        let user_has_liked: Int//
        let comments:Comments //
        let caption:Caption? //
        let likes:Likes //
        let link:String//
        let user:UserBlock//
        let created_time:String//
        let images:[String:ImageSpec]? //
        let videos: [String:ImageSpec]? //wierd
        let type: String //"image", "video", etc
        let users_in_photo:[UserAndPosition] //
        let filter:String //
        let tags:[String] //
        let id:String //
        let location: LocationSpec? //

    }


    public struct  LoginBlock: Codable {
        let thing1:String // two parts, one always for data
        let thing2:String // two parts, one always for data
    }
    
   public struct IgUser: Codable { //
    
        let id: String
        let username: String
        let full_name : String
        let profile_picture: String
        let bio: String
        let website: String
        let counts: Counts
    
    }
   public struct Meta : Codable {
        let code: Int
        let error_type: String?
        let error_message: String?
    }
    public struct Pagination : Codable{
        let nextURL: String?
        let nextMaxID: String?
    }


}

class InstagrammModel: Codable {
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
