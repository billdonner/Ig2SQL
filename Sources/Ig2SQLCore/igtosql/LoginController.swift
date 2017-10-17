
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

import Foundation
import Kitura
import KituraNet

import KituraRequest
//import KituraSession

import SwiftyJSON
import LoggerAPI

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
struct SessionState {
    
}
struct Session {
    
}
import Foundation
import Kitura
import KituraNet
import KituraRequest
import LoggerAPI
import Dispatch

public enum RemoteCallType {
    case tURLSession
    case tKituraSynch
    case tKituraRequest
    case tContentsOfFile
}

public let remoteCallType = RemoteCallType.tKituraSynch




//    open var port: Int {
//        get { return configMgr.port }
//    }
//
//    open var url: String {
//        get { return configMgr.url }
//    }
    
    // routes setup down below
    
    //check usage by mans



public func qrandom(max:Int) -> Int {
    #if os(Linux)
        return Int(rand()) % Int(max)
    #else
        return Int(arc4random_uniform(UInt32(max)))
    #endif
}



public extension String {
    
    public func leftPadding(toLength: Int, withPad character: Character) -> String {
        
        let newLength = self.characters.count
        
        if newLength < toLength {
            
            return String(repeatElement(character, count: toLength - newLength)) + self
            
        } else {
            return String(self[index(self.startIndex, offsetBy: newLength - toLength)...])
            ///return self.substring(from: index(self.startIndex, offsetBy: newLength - toLength))
            
        }
    }
    
}

///////////
///////////
///////////
///////////
///////////

struct TraceLog {
    static var buffer :[String] = []
    static func bufrd_clear( ) {
        buffer = []
    }
    static func bufrd_print(_ s:String) {
        buffer += [s]
    }
    static func bufrd_print(_ s:[String]) {
        buffer += s
    }
    static func bufrd_contents()->[String] {
        return buffer
    }
}
public struct ApiCounters {
    public  var getIn = 0
    public   var getOut = 0
    public   var postIn = 0
    public   var postOut = 0
    public   func counters()->[String:Int] {
        return ["get-in":getIn,"get=out":getOut,"post-in":postIn,"post-out":postOut]
    }
}
open class GlobalData {
    open var localConfig:[String:Any] = [:]
    open var apic = ApiCounters()
    open var usersLoggedOn : [Int:[String:Any]] = [:]
    
    public init () {
        
    }
}


public struct Fetch {
    
    public static func get (_ urlstr: String, session:URLSession?,use:RemoteCallType,
                            completion:@escaping (Int,Data?) ->()){
        
        func fetchViaURLSession (_ urlstr: String,_ session:URLSession?,completion:@escaping (Int,Data?) ->()){
            let url  = URL(string: urlstr)!
            let request = URLRequest(url: url)
            
            // now using a session per datatask so it hopefully runs better under linux
            
            //fatal error: Transfer completed, but there's no currect request.: file Foundation/NSURLSession/NSURLSessionTask.swift, line 794
            
            //https://github.com/stormpath/Turnstile/issues/31
            let task = session?.dataTask(with: request) {data,response,error in
                if let httpResponse = response as? HTTPURLResponse  {
                    let code = httpResponse.statusCode
                    guard code == 200 else {
                        print("remoteHTTPCall to \(url) completing with error \(code)")
                        completion(code,nil) //fix
                        return
                    }
                }
                guard error == nil  else {
                    
                    print("remoteHTTPCall to \(url) completing  error \(String(describing: error))")
                    completion(529,nil) //fix
                    return
                }
                
                // handle response
                
                completion(200,data)
            }
            task?.resume ()
        }
        
        
        func fetchViaContentsOfFile(_ urlstr: String, _ session:URLSession?,completion:@escaping (Int,Data?) ->()) {/// makes http request outbund
            do {
                if  let nurl = URL(string:urlstr) {
                    let  data =  try Data(contentsOf: nurl)
                    completion (200,data) 
                }
            }
            catch {
                completion (527, nil)
            }
        }
        
        func fetchViaKituraRequest(_ urlstr: String, _ session:URLSession?,completion:@escaping (Int,Data?) ->()) {
            KituraRequest.request(.get, urlstr).response {
                request, response, data, error in
                guard error == nil  else {
                    
                    print("remoteHTTPCall to \(urlstr) completing  error \(String(describing: error))")
                    
                    completion(529,nil) //fix
                    return
                }
                guard let data = data else {
                    completion(527,nil)
                    return
                }
                completion(200,data)
            }
        }
        
        func fetchViaKitura(_ urlstr: String, _ session:URLSession?,completion:@escaping (Int,Data?) ->()) {/// makes http request outbund
            func innerHTTP( requestOptions:inout [ClientRequest.Options],completion:@escaping (Int,Data?) ->()) {
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
            var requestOptions: [ClientRequest.Options] = ClientRequest.parse(urlstr)
            let headers = ["Content-Type": "application/json"]
            requestOptions.append(.headers(headers))
            innerHTTP(requestOptions: &requestOptions,completion:completion)
        }
        
        let remoteCallType:RemoteCallType = use
        
        switch remoteCallType {
            
        case RemoteCallType.tURLSession:
            fetchViaURLSession(urlstr, session, completion: completion)
        case RemoteCallType.tKituraSynch:
            fetchViaKitura(urlstr, session, completion: completion)
        case RemoteCallType.tKituraRequest:
            fetchViaKituraRequest(urlstr, session, completion: completion)
        case RemoteCallType.tContentsOfFile:
            fetchViaContentsOfFile(urlstr, session, completion: completion)
        }
    }
}
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
            self.callbackUrl =  "http://96.250.76.158:9090/authcallback"
            self.callbackPostUrl = "http://igblu.mybluemix.net"
            
    
        
    }// init
    
    //MARK: - ///////////// HANDLERS ////////////////////////
    

    
    /**
     * Handler for getting an application/json response.
     */

    

    func sendCallAgainSoon(_ response: RouterResponse) {
        response.headers["Content-Type"] = "application/json; charset=utf-8"
        do {
            
            let jsonResponse : [String : Any] = ["status":500 ,"results":"initializing - try again soon","timenow":"\(Date())"]
            let data = try JSONSerialization.data(withJSONObject:jsonResponse, options:.prettyPrinted )
            
            try response.status(.OK).send(data:data).end() } catch {
                Log.error("can not send response in getJSON")
        }
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
                    response.headers["Content-Type"] = "application/json; charset=utf-8"
                    let edict = ["fetchedStatus":status ,"status":status ,"payload":dict,"serverURL":serverip,"time-of-report":"\(Date())"] as [String : Any]
                    let jsonResponse = try JSONSerialization.data(withJSONObject:edict, options:.prettyPrinted )
                    
                    try response.status(.OK).send(data: jsonResponse).end()
                }
                catch{
                    print("sloRunningWebService json try failed")
                    
                }
                return
            }
            //        case "plain" :
            //            sloRunningWebService(id: userid, token: token){status,html,dict in
            //                do {
            //                    response.headers["Content-Type"] = "text/html"
            //                    let html = MasterTasks.htmlDynamicPageDisplay(baseurl: self.url)
            //                    try response.status(.OK).send(html).end()
            //
            //                }
            //                catch {
            //                    print("sloRunningWebService plain try failed")
            //                }
            //                return
        //            }
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
            if let data = data {
                
                let jsonBody = JSON(data: data)
                if let ip = jsonBody["ip"].string {
                    completion(ip )
                }
                else {
                    fatalError("no ip address for this Kitura Server instance, status is \(String(describing: error))")
                }
            }
        }
    }
    
    ////
    //MARK: Configuration process starts right here:::
  
    
    func unknownOP(_ response:RouterResponse) {
        response.headers["Content-Type"] = "application/json; charset=utf-8"
        var jsonResponse = JSON(["status":405 ,"results":"unknown OP"])
        jsonResponse["timenow"].stringValue = "\(Date())"
        try? response.status(.notAcceptable).send(json: jsonResponse).end()
    }
    
    
    

    
    
    
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
        let cburl = self.callbackUrl //+ "?nonce=112332123"
        let loc = "https://api.instagram.com/oauth/authorize/?client_id=\(clientId)&redirect_uri=\(cburl)&response_type=code&scope=\(LoginController.appscope)"
        Log.error("STEP_ONE redirecting to Instagram authorization \(loc)")
        // Log in
        do {
            try response.redirect( loc)
            //completion?(300)
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
            /// OK UP TO THIS POINT
            
            //let param = "?client_id=\(clientId)&redirect_uri=\(cburl)&grant_type=authorization_code&client_secret=\(clientSecret)&code=\(code)"
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
                  
                    
                    let jsonBody = JSON(data: data!)
                    if let token = jsonBody["access_token"].string,
                        let userid = jsonBody["user"]["id"].string,
                        let pic = jsonBody["user"]["profile_picture"].string,
                        let title = jsonBody["user"]["username"].string {
                        Log.info("STEP_TWO Instagram sent back \(token) and \(title)")
                        /// stash these, creating new object if needed
                        
                        let smtoken =  (userid + token).hashValue
                        
                        
//                        request.session?["userid"].string = userid
//                        request.session?["smtoken"].string = smtoken
//                        request.session?["token"].string = token
//                        request.session?["title"].string = title
//                        request.session?["pic"].string = pic
                         do {
                        try zh.setLoginCredentials(smaxxtoken: smtoken, igtoken: token, iguserid: userid, name: title, pic: pic)
                        }
                         catch {
                            
                            Log.error("STEP_TWOBEE  processInstagramResponse could not set logincredentials")// \(request.session)")
                        }
                        Log.error("STEP_TWOBEE  processInstagramResponse")// \(request.session)")
                        // w.start(userid,request,response)
                        // see if we can go somewhere interesting
                        
                        let vv:[String:Any] = ["userid":userid,"smtoken":smtoken,"token":token]
                        self.globalData.usersLoggedOn[smtoken] = vv
                        ///TODO: when done debugging, dont include userid and token in here, the client has no need
                        let tk = "/unwindor?token=\(token)&userid=\(userid)&smaxx-token=\(smtoken)&smaxx-name=\(title)&smaxx-pic=\(pic)"
                        do {
                            Log.info("STEP_TWOBEE redirect back to client with \(tk)")
                            try response.redirect(tk)  }
                        catch {
                            Log.error("STEP_TWOBEE   Could not redirect to client \(tk)")
                        }
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
    

    
    
    public func badSub(_ response:RouterResponse,reason:String) {
        Log.error(reason)
        response.headers["Content-Type"] = "application/json; charset=utf-8"
        var jsonResponse = JSON(["status":500 ,"results":reason])
        
        //jsonResponse["serverURL"].stringValue = appEnv.url
        
        jsonResponse["timenow"].stringValue = "\(Date())"
        try? response.status(.notAcceptable).send(json: jsonResponse).end()
    }
    
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
                self.badSub(outerresponse,reason:"INSTAGRAM SAYS subscriptionPostCallback \(subscriptionVerificationToken) was unsuccessful )")
                                    return
                                }
                                guard  let data = data else {
                                    self.badSub(outerresponse,reason:"INSTAGRAM SAYS subscriptionPostCallback \(subscriptionVerificationToken) returned with no data")
                                    return
                                }
                                
                                let jsonBody = JSON(data: data)
                                let metacode = jsonBody["meta"]["code"].intValue
                                guard metacode == 200 else {
                                    let mess = jsonBody["meta"]["error_message"].stringValue
                                    self.badSub(outerresponse,reason:"INSTAGRAM SAYS subscriptionPostCallback \(subscriptionVerificationToken) was unsuccessful meta \(metacode) \(mess)")
                                    return
                                }
                                self.badSub(outerresponse,reason:"* INSTAGRAM SAYS  subscriptionPostCallback \(subscriptionVerificationToken) successful")
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
