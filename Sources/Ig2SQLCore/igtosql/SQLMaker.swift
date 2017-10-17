//
//  ModelToSQL.swift
//  igjs
//
//  Created by william donner on 8/7/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation


class SQLMaker {
    var obuf = ""
    
    var vcache:[String:Int] = [:]
    var models: [InstagrammModel]
    var model: InstagrammModel
    
    init(model:InstagrammModel){
        self.models = [model]
        self.model = model
    }
    init(models:[InstagrammModel]){
        self.models = models
        if let m =  models.first {
            self.model = m
        } else {
            self.model = InstagrammModel()
        }
    }
    
    fileprivate  func getQueriesDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0].appendingPathComponent("stablequeries", isDirectory: true)
        try? FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: false, attributes: nil)
        return documentsDirectory
    }
    // this is translation after some obvious flattening
    
    fileprivate struct FlatMediaParts: Codable {
        //let attribution: Attribution? // found in stream
        let user_has_liked: Int//iguser
        let count_comments:Int //
        let caption_created_time: String
        let caption_text: String
        let caption_from_username: String
        let caption_from_full_name: String
        let caption_from_profile_picture : String
        let caption_from_id: String
        let caption_id: String
        let count_likes:Int //
        let link:String//
        let user_username: String
        let user_full_name:String
        let user_profile_picture: String
        let user_id: String
        let created_time:String//
        let type: String //"image", "video", etc //
        let filter:String //
        let id:String //
        let location_latitude: Double
        let location_longitude: Double
        let location_id: UInt64 // wierd
        let location_street_address: String?
        let location_name: String?
    }
    
    fileprivate func flattenIGMedia(_ omb:Instagramm.MediaBlock) -> FlatMediaParts {
        let nmb = FlatMediaParts(user_has_liked: omb.user_has_liked,
                                 count_comments: omb.comments.count,
                                 caption_created_time: (omb.caption?.created_time) ?? "",
                                 caption_text: (omb.caption?.text) ?? "",
                                 caption_from_username: (omb.caption?.from.username) ?? "",
                                 caption_from_full_name: (omb.caption?.from.full_name) ?? "",
                                 caption_from_profile_picture: (omb.caption?.from.profile_picture) ?? "",
                                 caption_from_id: (omb.caption?.from.id) ?? "",
                                 caption_id: (omb.caption?.id) ?? "",
                                 count_likes: omb.likes.count,
                                 link: omb.link,
                                 user_username: omb.user.username,
                                 user_full_name: omb.user.full_name,
                                 user_profile_picture: omb.user.profile_picture,
                                 user_id: omb.user.id,
                                 created_time: omb.created_time,
                                 type:omb.type ,
                                 filter: omb.filter,
                                 id: omb.id,
                                 location_latitude: (omb.location?.latitude) ?? 0,
                                 location_longitude: (omb.location?.longitude) ?? 0,
                                 location_id: (omb.location?.id) ?? 0,
                                 location_street_address: omb.location?.street_address  ?? "",
                                 location_name: omb.location?.name  ?? "")
        return nmb
    }
    
    
    fileprivate struct FlatCommentParts: Codable {
        //let attribution: Attribution? // found in stream
        let id: String
        let created_time:String//
        let text:String
        let user_username: String
        let user_full_name:String
        let user_profile_picture: String
        let user_id: String
        
    }
    
    fileprivate func flattenIGComments(_ omb:Instagramm.CommentBlock) -> [FlatCommentParts] {
            var nmb: [FlatCommentParts] = []
        nmb.append(FlatCommentParts(id: omb.id, created_time: omb.created_time, text: omb.text, user_username: omb.from.username, user_full_name: omb.from.full_name, user_profile_picture: omb.from.profile_picture, user_id: omb.from.id))
        return nmb
    }
    fileprivate struct FlatTagParts: Codable {
        //let attribution: Attribution? // found in stream
        let id: String
        let tag:String
        let user_id: String
        
    }
    
    fileprivate func flattenIGTags(_ omb:Instagramm.MediaBlock,userid:String) -> [FlatTagParts] {
        var nmb: [FlatTagParts] = []
        omb.tags.forEach( ){ tag in
        nmb.append(FlatTagParts(id: omb.id, tag: tag,  user_id: userid))
        }
        return nmb
    }
    
    fileprivate func vprint(_ s:String = "\n") {
        
        let found = vcache[s]
        if found == nil
        {
            obuf.append("\(s)\n")
            vcache[s] = 1
        } else {
            vcache[s]! += 1
        }
    }
    
    fileprivate func colvaluesForInsert(prefix:String, fmb:FlatMediaParts) -> String {
        
        var sql = ""
        func fs(_ s:String) {
            sql.append("'\(s)',")
        }
        func fi(_ i:Int) {
            sql.append("'\(i)',")
        }
        fs(fmb.id); fs(fmb.filter); fs(fmb.type); fs(fmb.link);
        fi(fmb.count_comments); fi(fmb.count_likes)
        fi(fmb.user_has_liked);
        
        fs(cleanup(fmb.caption_text)) ; fs(fmb.caption_created_time) ;
        
        fs(fmb.caption_id) ; fs(fmb.caption_from_id) ;
        fs("\(fmb.location_id)")
        fs(model.user.id);fs(fmb.created_time);
        // extra comma
        let ret =   prefix + " (" + sql.dropLast()  + ");"
        return ret
    }
    fileprivate func gencreateDB( )->String {
        let qas =  getQueriesDirectory().appendingPathComponent( "Query-Setup.sql")
        do {
            let temptableSQL = try  String.init(contentsOf:qas)
            return  " -- ---------------------- schema \(qas) generated \(Date()) --------------------------- \n" + temptableSQL
        }
        catch {
        }
        return " ********* no schema generated due to missing Query-Setup file ******** "
    }
    
    fileprivate func gensubordinatetables(media: Instagramm.MediaBlock) {

        
    }
 
    fileprivate func genFollowersInserts() {
        model.followers.forEach { (  user) in
            //userblockid += 1
            let t = "INSERT INTO  FollowerBlocks VALUES ( '\(user.id)' ,'\(model.user.id)');"
            vprint (t)
            let t2 = "INSERT INTO  UserBlocks VALUES ( '\(user.id)','\(user.username)','\(user.full_name)','\(user.profile_picture)','\(model.user.id)');"
            vprint (t2)
        }
    }
    fileprivate func executeFollowersInserts() {
        model.followers.forEach { (  user) in
            zh.followerblocksInsert(userid: user.id, iguserid: model.user.id)
            zh.userblocksInsert(userid: user.id, username: user.username, full_name: user.full_name, profile_picture: user.profile_picture, iguserid: model.user.id)
        }
    }
    fileprivate func genFollowingInserts() {
        model.followings.forEach { (  user) in
            // userblockid += 1
            let t = "INSERT INTO  FollowingBlocks VALUES ( '\(user.id)' ,'\(model.user.id)');"
            vprint (t)
            let t2 = "INSERT INTO  UserBlocks VALUES ( '\(user.id)','\(user.username)','\(user.full_name)','\(user.profile_picture)','\(model.user.id)');"
            vprint (t2)
        }
    }
    fileprivate func executeFollowingInserts() {
        model.followings.forEach { (  user) in
            zh.followingblocksInsert(userid: user.id, iguserid: model.user.id)
            zh.userblocksInsert(userid: user.id, username: user.username, full_name: user.full_name, profile_picture: user.profile_picture, iguserid: model.user.id)
        }
    }
    fileprivate func genRequestedByInserts() {
        model.requestedby.forEach { (  user) in
            //  userblockid += 1
            let t = "INSERT INTO  RequestedByBlocks VALUES ( '\(user.id)' ,'\(model.user.id)');"
            vprint (t)
            let t2 = "INSERT INTO  UserBlocks VALUES ( '\(user.id)','\(user.username)','\(user.full_name)','\(user.profile_picture),'\(model.user.id)');"
            vprint (t2)
        }
    }
    fileprivate func executeRequestedByInserts() {
        model.requestedby.forEach { (  user) in
            zh.requestedbyblocksInsert(userid: user.id, iguserid: model.user.id)
            zh.userblocksInsert(userid: user.id, username: user.username, full_name: user.full_name, profile_picture: user.profile_picture, iguserid: model.user.id)
        }
    }
 
    fileprivate func genMediaStyleInserts(_ prefix:String, data: [String:Instagramm.MediaBlock]  ) {
        data.forEach { (_,  media) in
            vprint (colvaluesForInsert(prefix:prefix, fmb:flattenIGMedia( media)))
         
            var first = true
            vprint("")
            
            media.users_in_photo.forEach({ (uip) in
                vprint ( "    INSERT INTO  UserPosition VALUES ('\(media.id)','\(uip.user.id)','\(uip.position.x)','\(uip.position.y)','\(model.user.id)' );")
                first = false
            })
            if first { vprint("") }
            let x = flattenIGTags(media, userid: model.user.id)
            x.forEach({ (ftp) in
                vprint ("    INSERT INTO  MediaTagged VALUES  ( '\(ftp.id)','\(cleanup(ftp.tag))','\(ftp.user_id)' );" )
                first = false
            })
            if first { vprint("") }
            media.images?.forEach({ (key,imagespec) in
                vprint ("    INSERT INTO  MediaImages VALUES  ( '\(media.id)','\(imagespec.url)',\(imagespec.width),\(imagespec.height),'\(model.user.id)' );")
                first = false
            })
            if first { vprint("") }
            // when written as above it sometimes fails with nil
            if let mv = media.videos {
                mv.forEach({ (key,imagespec) in
                    vprint ("    INSERT INTO  MediaVideos VALUES ('\(media.id)','\(imagespec.url)',\(imagespec.width),\(imagespec.height),'\(model.user.id)' );")
                    first = false
                })
            }//video
            model.likersOf[media.id]?.forEach {  userid in
                vprint ("INSERT INTO  likersofmedia VALUES ('\(media.id)','\(userid)', '\(model.user.id)' );")
            }
            
               }
        
            model.commentdata.forEach { (key, comment ) in
                vprint ("INSERT INTO commentsofmedia VALUES ('\(comment.id)','\(comment.text)',' \(comment.from.id) ',' \(comment.created_time)', '\(model.user.id)' );")
         
        }
    }
    fileprivate func cleanup(_ s:String)->String {
        return s.replacingOccurrences(of: "'", with: "")
    }
    
    fileprivate func genMediaInserts() {
        vprint()
        genMediaStyleInserts("INSERT INTO  MediadataBlocks VALUES  ",data:model.mediadata)
    }
    fileprivate func executeMediaInserts(  ) {
        let  data =   model.mediadata
        for (_,media) in data {
            
            zh.mediadatablocksInsert(mediaid: media.id, filter: media.filter , type: media.type, link: media.link, countcomments: media.comments.count, countlikes: media.likes.count, user_has_liked: media.user_has_liked, caption_text:media.caption?.text ?? "xxx", caption_created_time: media.caption?.created_time ?? "1234", caption_id: media.caption?.id ?? "00", caption_from_id: media.caption?.from.id ?? "99" , location_id: media.location?.id ?? UInt64(0.0), iguserid: model.user.id , created_time: media.created_time)
       
            
            
            
            media.users_in_photo.forEach({ (uip) in  zh.userpositionInsert(mediaid :media.id,userid  :uip.user.id,x:Float(uip.position.x),y:Float(uip.position.y),iguserid:model.user.id)
            })
            let x = flattenIGTags(media, userid: model.user.id)
            x.forEach({ (ftp) in
                zh.mediaTaggedInsert(mediaid:  ftp.id, tag: cleanup(ftp.tag), iguserid: ftp.user_id)
            })
            media.images?.forEach({ (key,imagespec) in
                zh.mediaImagesInsert(mediaid: media.id, url: imagespec.url, width: imagespec.width, height: imagespec.height, iguserid: model.user.id)
            })
            media.videos?.forEach({ (key,imagespec) in
                zh.mediaVideosInsert(mediaid: media.id, url: imagespec.url, width: imagespec.width, height: imagespec.height, iguserid: model.user.id)
            })
            
            model.likersOf[media.id]?.forEach {  userid in
                zh.likersofmediaInsert(mediaid: media.id, userid: userid, iguserid: model.user.id)
            }
            
            
    
        }
  
        model.commentdata.forEach {   arg   in
            let (_,comment) = arg
            zh.commentsofmediaInsert(mediaid: comment.id, comment: comment.text, userid: comment.from.id, created_time: comment.created_time, iguserid: model.user.id)
        }
    }
    fileprivate func genLikeInserts() {
        vprint()
        genMediaStyleInserts("INSERT INTO  LikesdataBlocks VALUES  ",data:model.likesdata)
    }
    fileprivate func executeLikeInserts(  ) {
         let data = model.likesdata
        for ( _,media) in data {
 
        zh.likesdatablocksInsert(mediaid: media.id, filter: media.filter , type: media.type, link: media.link, countcomments: media.comments.count, countlikes: media.likes.count, user_has_liked: media.user_has_liked, caption_text:media.caption?.text ?? "xxx", caption_created_time: media.caption?.created_time ?? "1234", caption_id: media.caption?.id ?? "00", caption_from_id: media.caption?.from.id ?? "99" , location_id: media.location?.id ?? UInt64(0.0), iguserid: model.user.id , created_time: media.created_time)
        
        }
      
    }
    fileprivate func genAboutMeInserts() {
        vprint()
        let u = model.user
        let t = "INSERT INTO  iguser VALUES ('\(cleanup(u.bio))','\(u.username)','\(u.full_name)','\(u.profile_picture)','\(u.website)','\(u.id)');"
        vprint (t)
    }
    fileprivate func executeAboutMeInserts() {
        let u = model.user
        zh.iguserInsert(bio: cleanup(u.bio), username: u.username, full_name: u.full_name, profile_picture: u.profile_picture, website: u.website, iguserid: u.id)
    }
    fileprivate  func genloadDB( )->String {
        obuf = ""
        let u = model.user
        vprint(  " -- ---------------------- inserts  \(u.id) generated \(Date()) --------------------------- \n" )
        genAboutMeInserts()
        genFollowersInserts()
        genFollowingInserts()
        genRequestedByInserts()
        genMediaInserts()
        genLikeInserts()
        return obuf
    }
    fileprivate  func executeloadDB( ) {
       
        executeAboutMeInserts()
        executeFollowersInserts()
        executeFollowingInserts()
        executeRequestedByInserts()
        executeMediaInserts()
        executeLikeInserts()
       
    }
    
    
    fileprivate   func gentempTables()->String {
        obuf = ""
        let qas = getQueriesDirectory().appendingPathComponent( "Query-Samples.sql")
        do {
            let temptableSQL = try  String.init(contentsOf:qas)
            let partA = (  " -- ---------------------- temp tables generated \(Date()) --------------------------- \n" )
            vprint(partA + temptableSQL)
            return obuf
        }
        catch 
        {
            return "Query-Samples is missing"
        }
    }
    
    
    public  func generateNativeSql(finally: (String,String,String)->()){
        let a = gencreateDB( )
        var b  = ""
        for m in models {
            model = m
            b  += genloadDB( )
        }
        let c = gentempTables( )
        finally(a ,b ,c)
    }
    public  func executeNativeSql(finally: (String )->()){
        
        for m in models {
            model = m
             executeloadDB()
        }
        let c = gentempTables( )
        finally(c )
    }
}


