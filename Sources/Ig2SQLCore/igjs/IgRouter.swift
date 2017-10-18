//
//  IgRouter.swift
//  igr
//
//  Created by william donner on 7/11/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation


// MARK: - Instagramm Statics

// MARK: - Instagramm Router
extension Instagramm {
    enum Router {
        static let baseURLString = "https://api.instagram.com"
        static let clientID = "d7020b2caaf34e13a1ca4bdf1504e4dc"
        static let redirectURI = "https://billdonner.com/"
        static let clientSecret = "81b197d145c1470caeec39fc6ad0b48a"
        
        case selfuserinfo(String)
        
        case selfmedialiked(String)
        case medialiked(String,String)
        
        case mediainfo(String, String)
        case relationship(String, String)
        
        case selffollows( String)
        case selffollowedby( String)
        
        case selfrequestedby( String)
        case requestedby( String,String)
        
        case commentsofmedia( String,String)
        case likersofmedia( String,String)
        case userInfo(String, String)
        
        case selfmediarecent(String,String,String)
        case mediarecent(String, String)
        case mediaRecentAboveMin(String,String,String )//token,min_id,max_id
        case mediaRecentBelowMax(String,String,String )//token,min_id,max_id
        case mediaRecentInRange(String,String,String,String)//token,min_id,max_id
        
        case taginfo(String,String)
        case tagrecent(String,String)
        case requestOauthCode
        
        static func getAccessTokenRequest (_ code:String) ->  NSMutableURLRequest? {
            let pathString = "/oauth/access_token"
            if let url =  URL(string: baseURLString + pathString) {
                let params = ["client_id": clientID, "client_secret":  clientSecret, "grant_type": "authorization_code", "redirect_uri":  redirectURI, "code": code]
                var paramString = ""
                for (key, value) in params {
                    if let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                        let escapedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                        paramString += "\(escapedKey)=\(escapedValue)&"
                    }
                }
                
                let request = NSMutableURLRequest(url:url)
                request.httpMethod = "POST"
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.httpBody = paramString.data(using: String.Encoding.utf8)
                return request
            }
            return nil
        }

        func makeURLRequest()-> URLRequest {
            let result: (path: String, parameters: [String: AnyObject]?) = {
                switch self {
                case .selfmedialiked (  let accessToken):
                    let params = ["access_token": accessToken]
                    let pathString = "/v1/users/self" +  "/media/liked"
                    return (pathString, params as [String : AnyObject])
                    
                case .medialiked (  let accessToken, let userID):
                    let params = ["access_token": accessToken]
                    let pathString = "/v1/users/" + userID + "/media/liked"
                    return (pathString, params as [String : AnyObject])
                    
                case .relationship( let userID, let accessToken):
                    let params = ["access_token": accessToken]
                    let pathString = "/v1/users/" + userID  +  "/relationship"
                    return (pathString, params as [String : AnyObject])
                    
                case .mediainfo( let mediaID, let accessToken):
                    let params = ["access_token": accessToken]
                    let pathString = "/v1/media/" + mediaID
                    return (pathString, params as [String : AnyObject])
                    
                case .selfuserinfo(let accessToken):
                    let params = ["access_token": accessToken]
                    let pathString = "/v1/users/self"
                    return (pathString, params as [String : AnyObject])
                    
                case .userInfo( let userID, let accessToken):
                    let params = ["access_token": accessToken]
                    let pathString = "/v1/users/" + userID
                    return (pathString, params as [String : AnyObject])
                    
                case .selffollows (  let accessToken):
                    let params = ["access_token": accessToken]
                    let pathString = "/v1/users/self" +  "/follows"
                    return (pathString, params as [String : AnyObject])
                case .selffollowedby (  let accessToken):
                    let params = ["access_token": accessToken]
                    let pathString = "/v1/users/self" + "/followed-by"
                    return (pathString, params as [String : AnyObject])
                    
                case .selfrequestedby (  let accessToken):
                    let params = ["access_token": accessToken]
                    let pathString = "/v1/users/self" +  "/requested-by"
                    return (pathString, params as [String : AnyObject])
                    
                case .requestedby (  let accessToken ,let userID):
                    let params = ["access_token": accessToken]
                    let pathString = "/v1/users/" + userID + "/requested-by"
                    return (pathString, params as [String : AnyObject])
                    
                case .likersofmedia (  let accessToken ,let mediaID):
                    let params = ["access_token": accessToken]
                    let pathString = "/v1/media/" + mediaID + "/likes"
                    return (pathString, params as [String : AnyObject])
                    
                case .commentsofmedia (  let accessToken ,let mediaID):
                    let params = ["access_token": accessToken]
                    let pathString = "/v1/media/" + mediaID + "/comments"
                    return (pathString, params as [String : AnyObject])
                    
                case .selfmediarecent ( let accessToken, let maxID, let count) :
                    let params = ["access_token": accessToken,"MAX_ID": maxID, "COUNT":count]
                    let pathString = "/v1/users/self" + "/media/recent"
                    return (pathString, params as [String : AnyObject])
                    
                case .mediarecent (  let accessToken, let userID):
                    let params = ["access_token": accessToken]
                    let pathString = "/v1/users/" + userID + "/media/recent"
                    return (pathString, params as [String : AnyObject])
                    
                    
                case .mediaRecentAboveMin ( _ , let accessToken, let minID  ):
                    let userID = "self"
                    let pathString = "/v1/users/" + userID + "/media/recent"
                    return (pathString, ["access_token": accessToken  ,"min_id":minID    ] as [String : AnyObject])
                    
                case .mediaRecentBelowMax ( _ , let accessToken, let maxID ):
                    let userID = "self"
                    let pathString = "/v1/users/" + userID + "/media/recent"
                    return (pathString, ["access_token": accessToken  , "max_id":maxID    ] as [String : AnyObject])
                    
                case .mediaRecentInRange ( _ , let accessToken, let minID, let maxID ):
                    let userID = "self"
                    let pathString = "/v1/users/" + userID + "/media/recent"
                    return (pathString, ["access_token": accessToken  ,"min_id":minID  ,"max_id":maxID    ] as [String : AnyObject])
                    
                    
                case .taginfo( let tagName  , let accessToken  ):
                    
                    let pathString = "/v1/tags/" + tagName
                    return (pathString, ["access_token": accessToken    ] as [String : AnyObject])
                    
                    
                case .tagrecent( let tagName  , let accessToken  ):
                    
                    let pathString = "/v1/tags/" + tagName  + "/media/recent"
                    return (pathString, ["access_token": accessToken    ] as [String : AnyObject])
                    
                    
                case .requestOauthCode:
                    let params = ["client_id": Router.clientID,
                               "scope":"basic likes follower_list comments relationships public_content",
                                  "redirect_uri":Router.redirectURI,
                                   "response_type":"code"] // server side
                    let pathString = "/oauth/authorize/" //?client_id=" + Router.clientID + "&redirect_uri=" + Router.redirectURI + "&response_type=code"
                    return (pathString, params as [String : AnyObject])
                }
            }()
            let baseURL = URL(string: Router.baseURLString)!
            let fullurl = baseURL.appendingPathComponent(result.path)
            return   encodedRequest(fullurl, params: result.parameters) as URLRequest
        }
        private func encodedRequest(_ fullurl:URL, params:URLParamsToEncode?) -> NSMutableURLRequest {
            let parms:URLParamsToEncode = (params != nil) ? params! : [:]
            let encreq = NSMutableURLRequest(url:fullurl)
            if params != nil {
                nwEncode(encreq, parameters: parms)
            }
            return encreq
        }
        private func nwEncode(_ req:NSMutableURLRequest,parameters:[String:AnyObject]){
            // extracted from Alamofire
            func escape(_ string: String) -> String {
                let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
                let subDelimitersToEncode = "!$&'()*+,;="
                let allowedCharacterSet = (CharacterSet.urlQueryAllowed as NSCharacterSet).mutableCopy() as! NSMutableCharacterSet
                allowedCharacterSet.removeCharacters(in: generalDelimitersToEncode + subDelimitersToEncode)
                return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet as CharacterSet) ?? ""
            }
            func queryComponents(_ key: String, _ value: AnyObject) -> [(String, String)] {
                var components: [(String, String)] = []
                if let dictionary = value as? [String: AnyObject] {
                    for (nestedKey, value) in dictionary {
                        components += queryComponents("\(key)[\(nestedKey)]", value)
                    }
                } else if let array = value as? [AnyObject] {
                    for value in array {
                        components += queryComponents("\(key)[]", value)
                    }
                } else {
                    components.append((escape(key), escape("\(value)")))
                }
                return components
            }
            func query(_ parameters: [String: AnyObject]) -> String {
                var components: [(String, String)] = []
                for key in Array(parameters.keys).sorted(by: <) {
                    let value = parameters[key]!
                    components += queryComponents(key, value)
                }
                // tweaked for swift 4
                return  (components.flatMap { "\($0.0)=\($0.1)" } ).joined(separator: "&")
            }
            //nwEncode starts and finishes by adjusting the url of the nsmutablerequest
            
            let uRLComponents = URLComponents(url: req.url!, resolvingAgainstBaseURL: false)
            if let comp = uRLComponents {
                let percentEncodedQuery = "?" + (comp.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
                let turls = req.url!.absoluteString + percentEncodedQuery
                let turl = URL(string:turls)
                req.url = turl
            }
        }// nwencode
    }// Router
} // instagramm router

extension Instagramm {
    //public funcs
    public  static  func getSelfMediaRecent( maxID:String = "999999999999", count:Int = 0,  _ f:@escaping (Int,Data?,Instagramm.Mdrenv?)->() ) {
        //print("getselfmediarecent maxID is \(maxID)")
        let request = Instagramm.Router.selfmediarecent(Persistence.igToken!, maxID, "\(count)" ).makeURLRequest()
        Instagramm.performRemoteCallAndResponse (request:request  ) { (status:Int, raw:Data?, result:Instagramm.Mdrenv?) in
            f(status, raw,result)
        }// result in
    }
    public  static  func getSelfLikedRecent(   _ f:@escaping (Int,Data?,Instagramm.Lkrenv? )->() ) {
        let request = Instagramm.Router.selfmedialiked(Persistence.igToken!).makeURLRequest()
        Instagramm.performRemoteCallAndResponse (request:request ) { ( status:Int,raw:Data?, result:Instagramm.Lkrenv?) in
            f(status, raw,result)
        }// result in
    }
    
    
    public  static  func getSelfRequestedby(   _ f:@escaping (Int,Data?,Instagramm.Rqrenv? )->() ) {
        let request = Instagramm.Router.selfrequestedby(Persistence.igToken!).makeURLRequest()
        Instagramm.performRemoteCallAndResponse (request:request ) { ( status:Int,raw:Data?, result:Instagramm.Rqrenv?) in
            f(status, raw,result)
        }// result in
    }
    public  static  func getMediaRecent(userid:String,   _ f:@escaping (Int,Data?,Instagramm.Mdrenv?)->() ) {
        let request = Instagramm.Router.mediarecent(Persistence.igToken!,userid).makeURLRequest()
        Instagramm.performRemoteCallAndResponse (request:request  ) { (status:Int, raw:Data?, result:Instagramm.Mdrenv?) in
            f(status, raw,result)
        }// result in
    }
    public  static  func getLikedRecent( userid:String,  _ f:@escaping (Int,Data?,Instagramm.Lkrenv? )->() ) {
        let request = Instagramm.Router.medialiked(Persistence.igToken!,userid).makeURLRequest()
        Instagramm.performRemoteCallAndResponse (request:request ) { ( status:Int,raw:Data?, result:Instagramm.Lkrenv?) in
            f(status, raw,result)
        }// result in
    }
    
    
    public  static  func getRequestedby(userid:String,   _ f:@escaping (Int,Data?,Instagramm.Rqrenv? )->() ) {
        let request = Instagramm.Router.requestedby(Persistence.igToken!,userid).makeURLRequest()
        Instagramm.performRemoteCallAndResponse (request:request ) { ( status:Int,raw:Data?, result:Instagramm.Rqrenv?) in
            f(status, raw,result)
        }// result in
    }
    public  static  func getLikersOfMedia(mediaid:String,   _ f:@escaping (Int,Data?,Instagramm.Lrrenv? )->() ) {
        let request = Instagramm.Router.likersofmedia(Persistence.igToken!,mediaid).makeURLRequest()
        Instagramm.performRemoteCallAndResponse (request:request ) { ( status:Int,raw:Data?, result:Instagramm.Lrrenv?) in
            f(status, raw,result)
        }// result in
    }
    public  static  func getCommentsOfMedia(mediaid:String,   _ f:@escaping (Int,Data?,Instagramm.Cmrenv? )->() ) {
        let request = Instagramm.Router.commentsofmedia(Persistence.igToken!,mediaid).makeURLRequest()
        Instagramm.performRemoteCallAndResponse (request:request ) { ( status:Int,raw:Data?, result:Instagramm.Cmrenv?) in
            f(status, raw,result)
        }// result in
    }
    public  static  func getFollows(   _ f:@escaping (Int,Data?,Instagramm.Flrenv? )->() ) {
        let request = Instagramm.Router.selffollows( Persistence.igToken!).makeURLRequest()
        Instagramm.performRemoteCallAndResponse (request:request ) { (status:Int, raw:Data?, result:Instagramm.Flrenv?) in
            f(status, raw,result)
        }// result in
    }
    public  static  func getFollowers(    _ f:@escaping (Int,Data?,Instagramm.Fwrenv? )->() ) {
        let request = Instagramm.Router.selffollowedby(Persistence.igToken!).makeURLRequest()
        Instagramm.performRemoteCallAndResponse (request:request ) { (status:Int, raw:Data?, result:Instagramm.Fwrenv?) in
            f(status, raw,result)
        }// result in
    }
    public    static  func getUserInfo(   _ f:@escaping (Int, Data?,Instagramm.Bdrenv?)->() ) {
        let request =  Instagramm.Router.selfuserinfo(Persistence.igToken!).makeURLRequest()
        Instagramm.performRemoteCallAndResponse (request:request ) { (status:Int, raw:Data?, result:Instagramm.Bdrenv?) in
            f(status, raw,result  )
        }// result in
    }
    // only useful with serverflow
    public    static  func getTokens(_ code:String , _ sample:  Instagramm.Ldrenv?  ,   _ f:@escaping (Int,Data?, Instagramm.Ldrenv?)->() ) {
        let request =  Instagramm.Router.requestOauthCode.makeURLRequest()
        Instagramm.performRemoteCallAndResponse (request:request ) { ( status:Int,raw:Data?, result: Instagramm.Ldrenv?) in
            f(status, raw,result  )
        }// result in
    }
    
    
    
}
