//
//  ApiCycles.swift
//  sql4ig
//
//  Created by bill donner on 8/29/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//
import Foundation
public enum APIFlow {
    case instagramm
    case debug
}
class APICycle {
 private      let bm : InstagramPoller
  private     let flow: APIFlow
 private      let uid: String = ""
       var main : ((@escaping UseridStatusCompletionHandler)->())?
  private   var mkeys : [String] = []

    
    init(flow:APIFlow,  bm:InstagramPoller) {
        self.bm = bm
        self.flow = flow
        switch flow {
        case .instagramm:
            self.main = standardCycle(_:)
        case .debug:
            self.main = dummyCycle1(_:)
        }
    }

    func dummyCycle1 (  _ finally:@escaping UseridStatusCompletionHandler) {
    
        dbgprint("***** - \(uid)  starting dummycycle1 ")
   
        // work goes here, but for dummy lets just delay a bit to simulate api call
       // bm.delay(0.1) {
            self.bm.apiCountUp()
                dbgprint("***** - \(self.uid) finished dummycycle1")
            self.dummyCycle2(finally)
       // }
    }
    
    func dummyCycle2 (   _ finally:@escaping UseridStatusCompletionHandler) {
       
        dbgprint("***** - \(uid) starting dummycycle2")
        bm.delay(0.2) {
            self.bm.apiCountUp()
            let randomNum:UInt32 = arc4random_uniform(100) // range is 0 to 99
            let st  = randomNum > 50 ? 200 : 429
            dbgprint("***** - \(self.uid) finished dummycycle2 AND NOW Completing finally")
            self.bm.bitterend(st,finally)
      
        }
    }
    
    func feelingsCycle(  _ finally:@escaping  UseridStatusCompletionHandler) {
        
        // when we get here we process only one piece of media
        if  mkeys.count > 0 ,
            let mkeya = mkeys.last ,
            let media = bm.model.mediadata[mkeya] {
            mkeys.removeLast(1) // shrink for next go
 
            // 7
            // now get the "who likes list for each piece of media here
            bm.apiCountUp()
            Instagramm.getLikersOfMedia(mediaid:media.id ) {  status,  rawlikers, likers   in
                guard let likers = likers , status == 200 else {
                    finally(self.uid,status); return
                    
                }
                for liker in likers.data {
                    if let _ = self.bm.model.likersOf[media.id ] {
                        self.bm.model.likersOf[media.id ]!.insert(liker.id)
                    } else {
                        var tt = Set<String>()
                        tt.insert(liker.id)
                        self.bm.model.likersOf[media.id ] = tt
                    }
                }//for each liker
                // 8
                // now get the "who comments list for each piece of media here
                self.bm.apiCountUp()
                Instagramm.getCommentsOfMedia(mediaid:media.id ) {  status,  rawcomments, comments   in
                    guard let comments = comments , status == 200 else
                    {
                        finally(self.uid,status); return
                    }
                    //print("getlikersfor \(media.id) likers: \(likers.data.count) countdown: \(countdown)") 
                    for comment in comments.data {
                        // gotta split this into a set of comment ids and separately and store them both
                        
                        self.bm.model.commentdata[comment.id ] = comment
                        if let _ = self.bm.model.commentsAboutMedia[media.id ] {
                            self.bm.model.commentsAboutMedia[media.id ]!.insert(comment.from.id)
                        } else {
                            var tt = Set<String>()
                            tt.insert(comment.from.id)
                            self.bm.model.commentsAboutMedia[media.id ] = tt
                        }
                    }// for each comment
                    // 9
                    // either moveto next task for this user, or to next user
                    self.bm.delay(0.01) {
                        self.feelingsCycle( finally)
                    }
                }// get comments
            }// get likers for 1
        }//fif let last
        else {
            // nothing left in mediakeys, so we are finally done
          
           // let randomNum:UInt32 = arc4random_uniform(100) // range is 0 to 99
           // let st  = randomNum > 50 ? 200 : 407
            let st = 200
            //dbgprint("- \(uid) finished feelingscycle \(st)")
            self.bm.bitterend(st, finally)
        }
    } //end func
    
    func standardCycle (   _ finally:@escaping UseridStatusCompletionHandler){
        // 1
        bm.apiCountUp()
        Instagramm.getUserInfo( ) { status, rawuserinfo, userinfo    in
            guard let userinfo = userinfo, status == 200 else { self.bm.bitterend(status, finally); return}
            let userid  = userinfo.data.id
            Persistence.igUserID =  userid //stash this in global singleton
            self.bm.model.user = userinfo.data // adjust global model
            // 2
            self.bm.apiCountUp()
            Instagramm.getFollows( ) {  status,  rawfollowings, followings    in
                guard  let followings = followings, status == 200 else {self.bm.bitterend(status, finally); return}
                self.bm.model.followings =   self.bm.model.followings.union(followings.data)
                // 3
                self.bm.apiCountUp()
                Instagramm.getFollowers ( ) {  status,  rawfollowers , followers   in
                    guard let followers = followers, status == 200 else { self.bm.bitterend(status, finally); return}
                    self.bm.model.followers = self.bm.model.followers.union ( followers.data )//     Instagramm.mergeUserBlocks(a: self.bm.model.followers, b:followers.data)
                    // 4
                    self.bm.apiCountUp()
                    Instagramm.getSelfRequestedby( ) {  status,  rawrequestors,requestors     in
                        guard let requestors = requestors , status == 200 else { self.bm.bitterend(status, finally); return}
                        self.bm.model.requestedby =  self.bm.model.requestedby.union(requestors.data)
                        // 5
                        self.bm.apiCountUp()
                        Instagramm.getSelfLikedRecent( ) { status,   rawlikes,likes    in
                            guard let likes = likes, status == 200 else { self.bm.bitterend(status, finally); return}
                            self.bm.model.likesdata =
                                 Instagramm.mergeUserBlocks(a: self.bm.model.likesdata, b:likes.data)
                                //elf.bm.model.likesdata.union(likes.data)
                            // 6
                            self.bm.apiCountUp()
                            /// we want to get to old media as well as what it gives us
                            /// work backwards in time, finding the time of the earliest in each batch we get back
                            Instagramm.getSelfMediaRecent(maxID: self.bm.model.miniseen  ?? "999999999999999", count: 5) {  status,  rawmedias,medias  in
                                guard let medias = medias , status == 200 else { self.bm.bitterend(status, finally); return}
                                var miniseen = self.bm.model.miniseen  ?? "999999999999999"
                                self.bm.model.mediadata =
                                    Instagramm.mergeUserBlocks(a: self.bm.model.mediadata, b:medias.data) //self.bm.model.mediadata.union(medias.data)
                                for media in medias.data {
                                    let t = media.created_time
                                    if t < miniseen {
                                        miniseen = t
                                    }
                                }
                                self.bm.model.miniseen = miniseen // preserve this on diskmodel so we can restart in the mi
                                dbgprint("***** - \(userid)-\(self.uid) finished standardcycle \(status)")
                                // delay just to unwind this closures before starting a large bunch more
                                self.bm.delay(0.0001) {
                                    // build an array of keys we can messwith thru many calls to the feelings cycle until they've all been handled
                                    
                                self.mkeys = self.bm.model.mediadata.map() {k,v in return k}
                                self.feelingsCycle(finally)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
