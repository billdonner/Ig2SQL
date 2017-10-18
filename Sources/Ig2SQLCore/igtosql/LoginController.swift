
struct IgIdent {
    var touch = 06
    var text = "Hello, World! IgIDENT "
}
//
//  IGController
//  Kitura-Starter
//
//  Created by william donner on 2/10/17.
//
//

enum SMaxxResponseCode: Int {
    case success = 200
    case workerNotActive = 538
    case duplicate = 539
    case badMemberID = 533
    case noData = 541
    case waiting = 542
    case noToken = 545
}
/// Instagram Authentication
///  inspired by Kitura Credentials and the google and facebook plugins
///  however, this is not a plugin and it uses NSURLSession to communicate with Instagram, not the Kitura HTTP library

import Foundation
import Kitura
import KituraNet
import KituraRequest
import LoggerAPI
import Dispatch

open class LoginController {
    let startdate = Date()
    // open let configMgr: ConfigurationManager
    open  var serverConfig: [String:String] = [:] // ServerConfig
    fileprivate   var jsonEndpointEnabled: Bool = true
    fileprivate   var jsonEndpointDelay: UInt32 = 0
    open  let globalData = GlobalData()
    static let appscope = "basic+likes+comments+relationships+follower_list+public_content"
    static let igVerificationToken = "zzABCDEFG0123456789zz"
    
    fileprivate var clientId : String = ""
    fileprivate var clientSecret : String = ""
    fileprivate var callbackUrl : String = ""
    fileprivate var callbackPostUrl : String = ""
    
    var fullyInitialized = false
    
    // these all come from the config file
    //var instagramCredentials : InstagramController!
    //var igApps: [String:[String:String]] = [:]
    var usersHack: [String:[String:String]] = [:]
    //var globalProps: [String:String] = [:]
    //var globalRoutingComponents : [String] = []
    
    //MARK:- Globals
    let boottime = Date()
    var sess: SessionState?
    var session: Session?
    var activeRoutes:[[String:String]] = []
    
    static let boottime = Date()
    
    // static  let sloCallback : SloRunner = sloRunningWebService as! SloRunner
    
    //  static let remoteWebService: RemoteWebServiceCall =  Fetch.get as! RemoteWebServiceCall
    
    
    public  func sloRunningWebService(id:String, token: String,completion:(Int,Int,[String:Any])->()){
        
    }
    // called when fully started, load all the specials
    func controllerIsFullyStarted() {
        
        //loadIGData()
        // loadGlobalzData(config: controller.configurl)
        
        self.fullyInitialized = true
        
    }
    public init?(tag:String ) throws  {
            self.clientId =  "d7020b2caaf34e13a1ca4bdf1504e4dc"
            self.clientSecret = "81b197d145c1470caeec39fc6ad0b48a"
            self.callbackUrl =  "http://96.250.76.158:9080/authcallback"
            self.callbackPostUrl = "http://igblu.mybluemix.net"
        
    }// init
    
    //MARK: - ///////////// HANDLERS ////////////////////////
    

    
    /**
     * Handler for getting an application/json response.
     */

    

    func sendCallAgainSoon(_ response: RouterResponse) {
        
        sendErrorResponse(response, status: 500, message: "initializing - try again soon")
    }
    
    /// standard outbound calls -
    public   func finally(code:Int,data:Data,userid:String,token:String,
                          request: RouterRequest, response: RouterResponse)
        
    {
        /// now , finally we c
        
        guard let what = request.parameters["what"] else { return   missingID(response)  }
        switch what {
            
        case "json" :
            sloRunningWebService(id: userid, token: token){status,html, dict in
                do{
                    let jsonResponse = ["fetchedStatus":status ,"status":status ,"payload":dict,"serverURL":serverip,"time-of-report":"\(Date())"] as [String : Any]
                    let  data = try   Config.jsonEncoder.encode(jsonResponse)
                        sendOKPreEncoded(response, data: data)
                }
                catch{
                    print("sloRunningWebService json try failed")
                }
                return
            }
  
        default: break
        }
        
    }//finally
 
    
}

// doesnt this neesd


// MARK: - Sorting

public func sortNestedData(lhsIsFolder: Bool, rhsIsFolder: Bool,  ascending: Bool,
                           attributeComparation: Bool) -> Bool {
    if(lhsIsFolder && !rhsIsFolder) {
        return ascending ? true : false
    }
    else if (!lhsIsFolder && rhsIsFolder) {
        return ascending ? false : true
    }
    return attributeComparation
}

public func itemComparator<T:Comparable>(lhs: T, rhs: T, ascending: Bool) -> Bool {
    return ascending ? (lhs < rhs) : (lhs > rhs)
}


public func ==(lhs: Date, rhs: Date) -> Bool {
    if lhs.compare(rhs) == .orderedSame {
        return true
    }
    return false
}

public func <(lhs: Date, rhs: Date) -> Bool {
    if lhs.compare(rhs) == .orderedAscending {
        return true
    }
    return false
}

//////public

extension LoginController {

    public class func discoverIpAddress(completion:@escaping (String) ->()) {
        KituraRequest.request(.get, "https://api.ipify.org?format=json").response {
            request, response, data, error in
            if let data = data ,
                  let rez = try? Config.jsonDecoder.decode(SomeIp.self, from: data){
                   let ip = rez.ip
                    completion(ip )
                }
                else {
                    fatalError("no ip address for this Kitura Server instance, status is \(String(describing: error))")
                }
            }
        }
  
    
    ////
    //MARK: Configuration process starts right here:::

    
    static func innerHTTP( requestOptions:inout [ClientRequest.Options],completion:@escaping (Int,Data?) ->()) {
        //print ("innerhttp \(requestOptions)")
        
        //request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        var responseBody = Data()
        let req = HTTP.request(requestOptions) { response in
            if let response = response {
                guard response.statusCode == .OK else {
                    _ = try? response.readAllData(into: &responseBody)
                    completion(404,responseBody)
                    return }
                _ = try? response.readAllData(into: &responseBody)
                completion(200,responseBody)
            }
        }
        
        req.end()
    }
    static   func fetch(_ urlstr: String, completion:@escaping (Int,Data?) ->()) {/// makes http request outbund
        var requestOptions: [ClientRequest.Options] = ClientRequest.parse(urlstr)
        let headers = ["Content-Type": "application/json"]
        requestOptions.append(.headers(headers))
        innerHTTP(requestOptions: &requestOptions,completion:completion)
    }
}



extension LoginController {
    
    /// OAuth2 steps with Instagram
    
    open func STEP_ONE(_ response: RouterResponse) {
    let loc =  Instagramm.Router.requestOauthCode.makeURLRequest().url!.absoluteString
        Log.error("STEP_ONE redirecting to Instagram authorization \(loc)")
        // Log in
        do {
            try response.redirect( loc)
        }
        catch {
            Log.error("Failed to redirect to Instagram login page")
        }
    }
    /// step two: receive request from instagram - has ?code paramater
    open func STEP_TWO (_ request: RouterRequest, response: RouterResponse,   completion:((Int) -> ())?) {
        
        func inner_two(_ code:String ) {
            let cburl = self.callbackUrl //+ "?nonce=112332133" // deliberat3ly changed
            Log.error("STEP_TWO inner cburl \(cburl) starting with \(code) just received from Instagram")
       
             //https://api.instagram.com/oauth/access_token
       
            let params:[String:String] = ["client_id" : "\(clientId)",
                "redirect_uri": cburl ,
                "grant_type": "authorization_code",
                "client_secret": clientSecret,
                "code":"\(code)" ]
            
            KituraRequest.request(.post,
                                  "https://api.instagram.com/oauth/access_token",
                                  parameters: params,
                                  encoding: URLEncoding.default)
                .response {
                    innerrequest, innerresponse, data, error in
                    // do something with data
                    let stat = innerresponse?.status
                    guard stat == 200 && error == nil      else {
                            // bad status but get error messag
                            let mesg = ""
                        Log.error("STEP_TWOBEE post to api.instagram.com/oauth/access_token params: \(params) >>> Bad Status From Instagram  \(mesg)  \(String(describing: stat!))")
                            completion?(stat!)
                            return
                        }
                   
                    let rez = try! Config.jsonDecoder.decode(Instagramm.AccessTokenResponse.self, from: data!)

                        Log.info("STEP_TWO Instagram sent back \(rez.access_token) and \(rez.user.id)")
                        /// stash these, creating new object if needed
                        
                        let smtoken =  (rez.user.id + rez.access_token).hashValue
                        
                         do {
                        try zh.setLoginCredentials(smaxxtoken: smtoken, igtoken: rez.access_token, iguserid: rez.user.id, name: rez.user.username, pic: rez.user.profile_picture)
                        }
                         catch {
                            
                            Log.error("STEP_TWOBEE  processInstagramResponse could not set logincredentials")// \(request.session)")
                        }
                        Log.error("STEP_TWOBEE  processInstagramResponse")// \(request.session)")
                        // w.start(userid,request,response)
                        // see if we can go somewhere interesting
                        
                        let vv:[String:Any] = ["userid":rez.user.id,"smtoken":smtoken,"token":rez.access_token]
                        self.globalData.usersLoggedOn[smtoken] = vv
                        ///TODO: when done debugging, dont include userid and token in here, the client has no need
                        let tk = "/unwindor?token=\(rez.access_token)&userid=\(rez.user.id)&smaxx-token=\(smtoken)&smaxx-name=\(rez.user.username)&smaxx-pic=\(rez.user.profile_picture)"
                        do {
                            Log.info("STEP_TWOBEE redirect back to client with \(tk)")
                            try response.redirect(tk)  }
                        catch {
                            Log.error("STEP_TWOBEE   Could not redirect to client \(tk)")
                        }
                    
                    completion?(200)
            }
        }//inner_two
        /// authenticate starts here
        if let error = request.queryParameters["error"] {
            let error_reason = request.queryParameters["error_reason"]
            let error_description = request.queryParameters["error_message"]
            Log.error("Instagram error \(error) and \(String(describing: error_reason)) - \(String(describing: error_description))")
        } else
            if let code = request.queryParameters["code"] {
//                if let nonce = request.queryParameters["nonce"] {
//                    print("--got nonce \(nonce) ")
//                }
                inner_two(code)
                
            } else {
                print("--no code")
        }
        
    }// end of step two
    

    /// make subscription
    open func make_subscription (_ outerresponse:RouterResponse, access_token:String, subscriptionVerificationToken:String) {
        
        /// DispatchQueue(label: "com.foo.bar", qos: DispatchQoS.utility).async {
        
        Log.info(">>>>>make_subscription for \(subscriptionVerificationToken) callback is \(self.callbackPostUrl) ")
        
        
        let params:[String:Any] = [
            "access_token" : "\(access_token)",
            "client_id" : "\(self.clientId)",
            "client_secret": "\(self.clientSecret)" ,
            "object": "user",
            "aspect": "media",
            "verify_token": "\(subscriptionVerificationToken)",
            "callback_url":"\(self.callbackPostUrl)" ]
        
        KituraRequest.request(.post,
                              "https://api.instagram.com/v1/subscriptions/",
                              parameters: params,
                              encoding: URLEncoding.default).response {
                                request, response, data, error in
                                // do something with data
                                guard error == nil  else {
                          sendErrorResponse(outerresponse, status: 501, message: "INSTAGRAM SAYS subscriptionPostCallback \(subscriptionVerificationToken) was unsuccessful )")
                                    return
                                }
                                guard  let data = data else {
                                   sendErrorResponse(outerresponse, status: 502, message:"INSTAGRAM SAYS subscriptionPostCallback \(subscriptionVerificationToken) returned with no data")
                                    return
                                }
                                let rez = try! Config.jsonDecoder.decode(Instagramm.MetaResponse.self, from: data)
                              
                                guard rez.meta.code == 200 else {
                                   sendErrorResponse(outerresponse, status: 503, message:"INSTAGRAM SAYS subscriptionPostCallback \(subscriptionVerificationToken) was unsuccessful meta \(rez.meta.code) \(rez.meta.error_message)")
                                    return
                                }
                                sendOKResponse(outerresponse,data:["reason" :" INSTAGRAM SAYS  subscriptionPostCallback \(subscriptionVerificationToken) successful"])
        }// response from immediate post
    }
    //}
}
//// these methods need to run on a different server so they can call and return within a blocking IG call from the main server
//// fortunately they are essentially static and have their own routes

extension LoginController  {
    func setupIGPostCallbackRoutes(router:Router) {
        
        router.get("/postcallback" ) {
            request, response, next in
            self.handle_igsubscribe_challenge_callback(LoginController.igVerificationToken,request: request,response: response)
            //next()
        }
        
        router.post("/postcallback") {
            request, response, next in
            self.handle_igsubscribe_post_callback(request,response: response)
            //next()
        }
    }
}
extension LoginController {
    
    open func handle_igsubscribe_post_callback (_ request: RouterRequest, response: RouterResponse) {
        /// parse out the callback we are getting back, its json
        var userid = "notfound"
        let t = "\(String(describing: request.body))" // stringify this HORRIBLE
        let a = t.components(separatedBy:"\"object_id\" = ")
        if a.count > 1 {
            let b = a[1].components(separatedBy:";")
            if b.count  > 1 {
                userid = b[0]
            }
        }
        Log.error("---->>>>  post handle_igsubscribe_post_callback for user  \(userid)")
        // member must have access token for instagram api access
        //       MembersCache.getTokenFromID(id: userid) { token in
        //        self.rest_make_worker_for(id: userid, token: token!) {_ in
        //            print("rest make worker for \(userid) \(token!) ")
        //        }
        //        }
    }
    
    /// the get is called in the middle of the post verification
    open func handle_igsubscribe_challenge_callback (_ subscriptionVerificationToken:String ,request: RouterRequest, response: RouterResponse) {
        
        
        /// strip out the challenge parameter and return with this only
        let ps = request.originalURL.components(separatedBy: "?")
        // make dictionary
        var d: [String:String] = [:]
        if ps.count >= 2 {
            let pairs = ps[1].components(separatedBy: "&")
            for pair in pairs {
                let p = pair.components(separatedBy: "=")
                if p.count >= 2 {
                    d[p[0]] = p[1]
                }
            }
            Log.error("---->>>>  get callback for subscriptionVerificationToken  \(subscriptionVerificationToken) dict \(d)")
            
            if d["hub.mode"] ==  "subscribe" {
                if d["hub.verify_token"] == subscriptionVerificationToken {
                    if  let reply = d["hub.challenge"] {
                        response.headers["Content-Type"] = "text/plain; charset=utf-8"
                        let r = response.status(HTTPStatusCode.OK)
                        do {
                            let _ =   try r.send(reply).end()
                            print("-------did send verify response to Instagram")
                            Log.error("------did send verify response to Instagram")
                        }
                        catch {
                            Log.error("could not send verify response to Instagram")
                        }
                        Log.info("Post register GET callback replying with challenge \(reply)")
                        return
                    }
                }
            }
        } // >=2
        else { 
            Log.error("---->>>>  get callback for subscriptionVerificationToken  \(subscriptionVerificationToken) has no ? args")
        }
    }// get  callbac
}
