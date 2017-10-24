//
//  bootLoginWebService
//  igtosql
//
//  Created by william donner on 9/15/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//


import Foundation
import Kitura
import KituraNet
import KituraRequest
import LoggerAPI
import Dispatch


fileprivate class LoginController {
    static let serviceDescription :[String:String] =
        ["framework":"Ig2SQLLoginService",
         "applicationName": "IG2SQL",
         "company": "PurplePeople",
         "organization": "DonnerParties",
         "location" : "New York, NY",
         "version"  :  Config.version ]
    
    static let boottime = Date()
    static let appscope = "basic+likes+comments+relationships+follower_list+public_content"
    var clientId : String = ""
    var clientSecret : String = ""
    var callbackUrl : String = ""
    var callbackPostUrl : String = ""
    var fullyInitialized = false
    let boottime = Date()
    var activeRoutes:[[String:String]] = []

    
    public init?(tag:String ) throws  {
        self.clientId =  "d7020b2caaf34e13a1ca4bdf1504e4dc"
        self.clientSecret = "81b197d145c1470caeec39fc6ad0b48a"
        self.callbackUrl =  "http://96.250.76.158:9080/authcallback"
        self.callbackPostUrl = "http://igblu.mybluemix.net"
    }// init
    
    public  func sloRunningWebService(id:String, token: String,completion:(Int,Int,[String:Any])->()){
    }
    // called when fully started, load all the specials
    func controllerIsFullyStarted() {
        self.fullyInitialized = true
    }
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


extension LoginController {

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
        let loc =  Instagramm.Router.requestOauthCode(clientId,callbackUrl).makeURLRequest().url!.absoluteString
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
                    
                    let rez = try! GlobalData.jsonDecoder.decode(Instagramm.AccessTokenResponse.self, from: data!)
                    
                    Log.info("STEP_TWO Instagram sent back \(rez.access_token) and \(rez.user.id)")
                    /// stash these, creating new object if needed
                    
                    let smtoken =  (rez.user.id + rez.access_token).hashValue
                    do {
                        try SQLMaker.setLoginCredentials(smaxxtoken: smtoken, igtoken: rez.access_token, iguserid: rez.user.id, name: rez.user.username, pic: rez.user.profile_picture)
                    }
                    catch {
                        Log.error("STEP_TWOBEE  processInstagramResponse could not set logincredentials")// \(request.session)")
                    }
                    Log.error("STEP_TWOBEE  processInstagramResponse")// \(request.session)")
                    // w.start(userid,request,response)
                    // see if we can go somewhere interesting
                    
                    let vv:[String:Any] = ["userid":rez.user.id,"smtoken":smtoken,"token":rez.access_token]
                    globalData.usersLoggedOn[smtoken] = vv
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
               let params:[String:String] = [
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
                                let rez = try! GlobalData.jsonDecoder.decode(Instagramm.MetaResponse.self, from: data)
                                
                                guard rez.meta.code == 200 else {
                                    sendErrorResponse(outerresponse, status: 503, message:"INSTAGRAM SAYS subscriptionPostCallback \(subscriptionVerificationToken) was unsuccessful meta \(rez.meta.code) \(rez.meta.error_message)")
                                    return
                                }
                                sendOKResponse(outerresponse,data:["reason" :" INSTAGRAM SAYS  subscriptionPostCallback \(subscriptionVerificationToken) successful"])
        }// response from immediate post
    }
}

func bootLoginWebService() {
    
    var loginController: LoginController!
    //print("booting LoginWebService on port \(Config.login_port)")
    // Create a new router
    let router = Router()
    do {
        loginController = try LoginController(tag: "loginsvc")
    }
    catch {
        fatalError("couldnt create logincontroller")
    }
    
    // Dont Handle HTTP GET requests to /
    
    // JSON Get request
    router.get("/json") { request, response, next in
        sendOKResponse(response, data: LoginController.serviceDescription)
    } 
    // MARK: Callback GETs and POSTs from IG come here
    ///
    router.get("/logout")  { request, response, next in
        
        guard let smtokeni = request.queryParameters["smtoken"]  else {
            return  missingID(response)
        }
        guard let smtoken = Int(smtokeni) else {
            return  missingID(response)
        }
        
       SQLMaker.getLoginCredentials (smaxxtoken: smtoken,atend: {isloggedon, _,name,pic,igid,_ in
            if isloggedon {
                SQLMaker.deleteLoginCredentials(smaxxtoken: smtoken)
                globalData.usersLoggedOn[smtoken] = nil
                sendOKResponse(response, data:["desc":"logged out from here"])
                
            }
            sendErrorResponse(response, status: 402, message: "notloggedon")
        })
    }
    
    // This should get the ball rolling
    router.get("/login")  { request, response, next in
        
        guard let lc = loginController else { return }
        guard let smtokenstr =  request.queryParameters["smtoken"] else {
            // if no token passed in then just go for full login
            globalData.apic.getIn += 1
            lc.STEP_ONE(response) // will redirect to IG
            return
        }
        if let smtoken = Int(smtokenstr) {
            // call sql service to read record keyed by 'smtoken'
           SQLMaker.getLoginCredentials (smaxxtoken: smtoken,atend: {isloggedon, _,name,pic,igid,_ in
                
                if isloggedon {
                    // if already logged on send back existing record
                    let jsondata = try!  GlobalData.jsonEncoder.encode(SmaxxResponse(status: 203, igid: igid, pic: pic, smaxxtoken: smtoken, name: name))
                    sendOKPreEncoded(response,data:jsondata)
                }
                else
                {
                    // not logged on, so go to step one
                    globalData.apic.getIn += 1
                    lc.STEP_ONE(response) // will redirect to IG
                }
            })
        } else { // ill-formed smtoken
            return   missingID(response)
        }
        
    }
    
    router.get("/authcallback" ) { request, response, next in
        //Log.error("************* /authcallback will authenticate ")
        loginController?.STEP_TWO (request, response: response ) { status in
            if status != 200 { Log.error("Back from STEP_TWO status \(status) ") }
        }
        
        //next()
    }
    router.get("/unwindor" ) { request, response, next in
        
        // guard let lc = lc else { return }
        // just a means of unwinding after login , with data passed via queryparam
        
        do {
            let id = request.queryParameters["userid"] ?? "no id"
            let smtoken = Int(request.queryParameters["smaxx-token"]!) ?? 0
            let name = request.queryParameters["smaxx-name"] ?? "no smname"
            let pic = request.queryParameters["smaxx-pic"] ?? "no smpic"
            let dict = SmaxxResponse(status: 201, igid: id, pic: pic, smaxxtoken: smtoken, name: name)
            let data = try  GlobalData.jsonEncoder.encode(dict)
            sendOKPreEncoded(response, data: data)
        }
        catch {
            Log.error("Failed /authcallback redirect \(error)")
        }
        //next()
    }
    
    
    // temp
    router.get("/subscribe/:who" ){ request, response, next in
        
        guard let lc = loginController else { return }
        globalData.apic.getIn += 1
        
        guard let who = request.parameters["who"] else { return   missingID(response)  }
        
        let ix = globalData.usersHack[who]
        guard let x = ix else {
            return   missingID(response)
        }
        
        guard let _ = x["userid"], let token = x["apitoken"] else {
            return   missingID(response)
        }
        
        //
        lc.make_subscription(response,access_token: token,subscriptionVerificationToken: Config.igVerificationToken)
        
        //next()
    }
    
    ///
    // MARK:- Handles any errors that get set
    ///
    router.error { request, response, next in
        
        response.headers["Content-Type"] = "text/plain; charset=utf-8"
        do {
            let errorDescription: String
            if let error = response.error {
                errorDescription = "\(error)"
            } else {
                errorDescription = "Unknown error"
            }
            try response.send("Caught the error: \(errorDescription)").end()
        }
        catch {
            Log.error("Failed to send response \(error)")
        }
        next()
    }
    
    ///
    // MARK:- A custom Not found handler
    ///
    // A custom Not found handler
    router.all {
        request, response, next in
        if  response.statusCode == .notFound  {
            // Remove this wrapping if statement, if you want to handle requests to / as well
            //if  request.originalUrl != "/"  &&  request.originalUrl != ""  {
            
            do {
                try response.send("Route \( request.originalURL) not found  ").end()
            }
            catch {
                Log.error("Failed to send response \(error)")
            }
            //}
        }
        next()
    }
    
    // Add an HTTP server and connect it to the router
    let srv = Kitura.addHTTPServer(onPort: Config.login_port, with: router)
    srv.started {
        Log.info("--Server \(globalData.serverip)   LoginService started on port \(Config.login_port) ")
    }
    srv.failed {status in
        Log.error("--Server \(globalData.serverip)   LoginService FAILED TO START   status \(status)   ")
        exit(1)
    }
}
