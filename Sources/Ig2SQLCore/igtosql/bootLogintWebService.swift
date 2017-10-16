//
//  bootLoginWebService
//  igtosql
//
//  Created by william donner on 9/15/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation
import Kitura
import KituraRequest
import LoggerAPI

struct SmaxxResponse: Codable {
    let status: Int
    let igid: String
    let pic:String
    let smaxxtoken: Int
    let name:String
}
struct LoginResponse:Codable {
    let userid:String
    let reportname:String
    let elapsed:TimeInterval
    let queryParameters:[String:String]
    let reportHeaders: [ String]
    let reportData: [[String]]
}
struct LoginResponseWrapped:Codable {
    let status: Int
    let time: Date
    let response: LoginResponse
}

func bootLoginWebService() {
    
    print("booting LoginWebService on port \(Config.login_port)")
    // Create a new router
    let router = Router()
    do {
        lc = try LoginController(tag: "loginsvc")
    }
    catch {
        fatalError("couldnt create logincontroller")
    }
    
    // Handle HTTP GET requests to /
    // Serve static content from "public"
    router.all("/", middleware: StaticFileServer())
    
    // JSON Get request
    router.get("/json") {
        request, response, next in
        Log.debug("GET - /json route handler...")
        response.headers["Content-Type"] = "application/json; charset=utf-8"
        var jsonResponse :[String:String] = [:]
        jsonResponse["framework"]  = "Ig2SQLLoginService"
        jsonResponse["applicationName"]  = "IG2SQL"
        jsonResponse["company"]  = "PurplePeople"
        jsonResponse["organization"]  = "DonnerParties"
        jsonResponse["location"] = "New York, NY"
        let jsondata = try  Config.jsonEncoder.encode(jsonResponse)
        try response.status(.OK).send(data: jsondata).end()
        next()
    }
    
    // Basic application health check
    router.get("/loopback") {
        request, response, next in
        Log.debug("GET - /loopback route handler...")
        let result = health.status.toSimpleDictionary()
        if health.status.state == .UP {
            try response.send(json: result).end()
        } else {
            try response.status(.serviceUnavailable).send(json: result).end()
        }
        next()
    }
    
    router.get("/log") { request, response, next in
        
        guard let lc = lc else { return }
        let qp = request.queryParameters
        response.headers["Content-Type"] = "application/json; charset=utf-8"
        var json  :[String:String] = ["logged":"\(qp)"]
        Log.info("LOGLINE \(qp)")
        json ["timenow"]  = "\(Date())"
        let jsonResponse = try  Config.jsonEncoder.encode(json)
        try response.status(.OK).send(data: jsonResponse).end()
        
        lc.globalData.apic.getIn += 1
    }
    
    //    /// this path allows other servers to obtain the instagram goodies so they can make instagram callls instead of us
    //    /// TODO: - add more security possibly even dhecking ip addresses against a whitelist
    //
    //    router.get("/igtoken/:userid") {   request, response, next in
    //
    //        // -- standard api token userid validation
    //        guard let lc = lc else { return }
    //        guard lc.fullyInitialized else { lc.sendCallAgainSoon(response); return }
    //        guard let smtoken = Int(request.queryParameters["smtoken"]!) else { return  lc.missingID(response) }
    //        guard let loggedOnD  = lc.globalData.usersLoggedOn[smtoken]  else {  return  lc.missingID(response)  }
    //        guard let loggedOnData = loggedOnD , let userid = loggedOnData["userid"], let uid = request.parameters["userid"], uid == userid else { return  lc.missingID(response)  }
    //        // -- end standard verification
    //        guard let token = loggedOnData["token"] else { return  lc.missingID(response)  }
    //        response.headers["Content-Type"] = "application/json; charset=utf-8"
    //        var json  :[String:Any] = ["status":200 ,"ig-token":token,"ig-userid":userid]
    //        json ["timenow"]  = "\(Date())"
    //        let jsonResponse = try  Config.jsonEncoder.encode(json)
    //        try response.status(.OK).send(data: jsonResponse).end()
    //
    //        lc.globalData.apic.getIn += 1
    //
    //    }
    
    // MARK: Callback GETs and POSTs from IG come here
    ///
    router.get("/logout")  { request, response, next in
        
        guard let lc = lc else { return }
        guard let smtoken = Int(request.queryParameters["smtoken"]!) else {
            return  lc.missingID(response)
        }
        let loggedOnData =  lc.globalData.usersLoggedOn[smtoken]
        if loggedOnData != nil {
            lc.globalData.usersLoggedOn[smtoken] = nil
            response.headers["Content-Type"] = "text/plain; charset=utf-8"
            try response.send("logged out from here").end()
            return
        }
        response.headers["Content-Type"] = "text/plain; charset=utf-8"
        try response.send("not logged on").end()
    }
    
    // This should get the ball rolling
    router.get("/showlogin")  { request, response, next in
        
        guard let lc = lc else { return }
        guard let smtokenstr =  request.queryParameters["smtoken"] else {
            return  lc.missingID(response)
        }
        if let smtoken = Int(smtokenstr) {
            zh.getLoginCredentials (smaxxtoken: smtoken,atend: {isloggedon, p,q,r,s,t in
                //print("getlogin p\(p) q\(q) r\(r) s\(s) t\(t)")
                if isloggedon {
                     
                    response.headers["Content-Type"] = "application/json; charset=utf-8"
                    let jsonResponse = SmaxxResponse(status: 203, igid: s, pic: r, smaxxtoken: smtoken, name: q)
                    let jsondata = try!  Config.jsonEncoder.encode(jsonResponse)
                    try! response.status(.OK).send(data: jsondata).end()
                    next()
                    return
                }
                else
                {
                    // not logged on, so go to step one
                    
                    lc.globalData.apic.getIn += 1
                    lc.STEP_ONE(response) // will redirect to IG
                }
            })
        } else { // ill-formed smtoken
         return  lc.missingID(response)
        }
    
    }
    
    router.get("/authcallback" ) { request, response, next in
        
        guard let lc = lc else { return }
        //Log.error("************* /authcallback will authenticate ")
        lc.STEP_TWO (request, response: response ) { status in
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
            let jsonResponse = try  Config.jsonEncoder.encode(dict)
            try response.status(.OK).send(data: jsonResponse).end()
        }
        catch {
            Log.error("Failed /authcallback redirect \(error)")
        }
        //next()
    }
    
    
    // temp
    router.get("/subscribe/:who" ){ request, response, next in
        
        guard let lc = lc else { return }
        lc.globalData.apic.getIn += 1
        
        guard let who = request.parameters["who"] else { return  lc.missingID(response)  }
        
        //        guard let token = request.parameters["token"] else { return  missingID(response)  }
        //        guard let rid = request.parameters["id"] else { return  missingID(response)  }
        
        let ix = lc.usersHack[who]
        guard let x = ix else {
            return  lc.missingID(response)
        }
        
        guard let _ = x["userid"], let token = x["apitoken"] else {
            return  lc.missingID(response)
        }
        
        //
        lc.make_subscription(response,access_token: token,subscriptionVerificationToken: LoginController.igVerificationToken)
        
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
    
    Log.error("Smaxx Login Service started on port \(Config.login_port)")
    // Add an HTTP server and connect it to the router
    let srv = Kitura.addHTTPServer(onPort: Config.login_port, with: router)
    
    
    srv.started {
        //self.controllerIsFullyStarted()
        Log.info("--Server \(serverip)   LoginService started ")
    }
    srv.failed {status in
        Log.error("--Server \(serverip)   LoginService FAILED TO START   status \(status)   ")
        exit(1)
    }
}


