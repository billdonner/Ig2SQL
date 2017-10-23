//
//  IgStaticFuncs.swift
//  igjs
//
//  Created by william donner on 7/16/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation
// MARK: - generic  static funcs
extension Instagramm { // generic static funcs

    static func mergeUserBlocks<T:Mergeable> ( a: [String:T], b: [T])->  [String:T]{
        var c = a // copy into new
        b.forEach({ (userblock) in
            let id = userblock.id
            if let _ = c[id] {
                //print ("merge \(T.self) block dupe: \(id)")
                c[id] = userblock
            } else {
                c[id] = userblock
            }
        })
        var rezult:[String:T] = [:]
        c.forEach { (arg) in
            let (key, val) = arg
            rezult[key] = val
        }
        return rezult
    }

 private static  func realCallWithDataResponse  (url callurl:URL,finally:@escaping (Int, Data?)->() ) {
        
        let HTTPHeaderField_ContentType         = "Content-Type"
        let ContentType_ApplicationJson         = "application/json"
        let HTTPMethod_Get                      = "GET"
        let request = NSMutableURLRequest(url:  callurl)
        request.timeoutInterval = 30.0 // TimeoutInterval in Second
        request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
        request.addValue(ContentType_ApplicationJson, forHTTPHeaderField: HTTPHeaderField_ContentType)
        request.httpMethod = HTTPMethod_Get
        IGNetOps.get(request) { status, data in
            guard status == 200 else {
                let _ = finally(status,nil)
                return
            }
            if let data = data
            {
                // no longer write this to disk here
                finally(status,data)
                ///datawrite(tag: suffix,data: data)
            }
        }
    }// real call
    static func  performRemoteCallAndResponse<T :Codable&IGResponse> (request:URLRequest ,   _ finally:@escaping (Int, Data?,T? )->()) {
        
            if let url = request.url {
               // print("performRemoteCallAndResponse: \(url) ")
                
                realCallWithDataResponse( url:url ){ status, data in
               // has results
                if let jsData = data, status == 200 {
                    // Decode data to object
                    do {
                        let rez = try GlobalData.jsonDecoder.decode(T.self, from: jsData)
                        //  print("\n\nDecoded realCallWithDataResponse...\n")
                       
                           let meta = rez.meta
                            //NSLog("%@","remoteJSONCall returned \(String(describing: meta))")
                            if meta.code != 200 {
                                NSLog("bad result \(meta.code) \(meta.error_type!) \(String(describing: meta.error_message))")
                                finally(meta.code, nil,rez) // good with code 200
                               
                            } else {
                                //print("good result \(meta.code)")
                                finally(meta.code, data,rez) // bad
                                 return // !!!!!!!!!!!!!!!!! cut this short
                            }
                            
                        finally(status,data,rez)
                         return // !!!!!!!!!!!!!!!!! cut this short
                    }
                    catch  {
                        print("\nFailed to realCallWithDataResponse  \(url) \(jsData) ... \(error) \n")
                        finally  (status,nil,nil)
                         return // !!!!!!!!!!!!!!!!! cut this short
                    }
                    } // hss jsdata
                 else {
                    // 429s come thru here, they can get handled upstairs
                    //print("\nFailed to receive data from realCallWithDataResponse  \(url) \n")
                    finally  (status, nil,nil)
                     return // !!!!!!!!!!!!!!!!! cut this short
                    }
                
                }// realCallWithDataResponse
               
        }// if let url
    }//performRemoteCallAndResponse
} // instagramm generic


extension  Instagramm {
    // MARK: - generic
    //  each IG Response gets its own struct with a similar Envelope and defined by its own typealias
    public struct EnvIg<T:Codable> : Codable, IGResponse {
        public let meta : Meta
        let data: T
        public let pagination: Pagination?
    }
    public  struct EnvIgA<T:Codable> : Codable, IGResponse {
        public let meta : Meta
        let data: [T]
        public let pagination: Pagination?
    }
    enum EnvKinds : String {
        case LoginUserResponse = "Ldrenv"
        case MediaBlocksResponse = "Mdrenv"
        case LikesBlocksResponse = "Lkrenv"
        
        case CommentsBlocksResponse = "Cmrenv"
        case LikersBlocksResponse = "Lrrenv"
        case FollowersBlocksResponse = "Flrenv"
        case FollowingsBlocksResponse = "Fwrenv"
        case RequestedsBlocksResponse = "Rqrenv"
    }
    
    public typealias Bdrenv = EnvIg< IgUser >
    public typealias Ldrenv = EnvIg< LoginBlock>
    public typealias Mdrenv = EnvIgA< MediaBlock>
    
    public typealias Cmrenv = EnvIgA< CommentBlock>
    public typealias Lkrenv = EnvIgA< MediaBlock>
    public typealias Lrrenv = EnvIgA< UserBlock>
    public typealias Flrenv = EnvIgA< UserBlock>
    public typealias Fwrenv = EnvIgA< UserBlock>
    public typealias Rqrenv = EnvIgA< UserBlock>

}
