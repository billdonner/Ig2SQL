//
//  bootReportWebService
//  igtosql
//
//  Created by william donner on 9/15/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation
import Kitura 
import LoggerAPI

func bootAdminWebService() {
    let adminserviceDescription:[String:String] = ["framework":"Ig2SQLWebAdminService",
                                                    "applicationName": "IG2SQL",
                                                    "company": "PurplePeople",
                                                    "organization": "DonnerParties",
                                                    "location" : "New York, NY"]
    
    // Create a new router
    let router = Router()
    // Dont Handle HTTP GET requests to /
    
    // JSON Get request
    router.get("/json") { request, response, next in
        sendOKResponse(response, data:  adminserviceDescription)
        next()
    }
    
    router.get("/postcallback" ) {
        request, response, next in
        handle_igsubscribe_challenge_callback(Config.igVerificationToken,request: request,response: response)
        //next()
    }
    
    router.post("/postcallback") {
        request, response, next in
        handle_igsubscribe_post_callback(request,response: response)
        //next()
    }
    
    ///
    // MARK:- Handle any errors that get set
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
    
    Log.error("Smaxx WebAdmin Service started on port \(Config.webadmin_port)")
    // Add an HTTP server and connect it to the router
    let srv = Kitura.addHTTPServer(onPort: Config.webadmin_port, with: router)
    
    srv.started {
        //self.controllerIsFullyStarted()
        Log.info("--Server \(globalData.serverip)   WebAdmin Service started on port \(Config.webadmin_port)")
    }
    srv.failed {status in
        Log.error("--Server \(globalData.serverip)   WebAdmin Service FAILED TO START   status \(status)   ")
        exit(1)
    }
}

//// these methods need to run on a different server so they can call and return within a blocking IG call from the main server
//// fortunately they are essentially static and have their own routes


public func handle_igsubscribe_post_callback (_ request: RouterRequest, response: RouterResponse) {
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
public func handle_igsubscribe_challenge_callback (_ subscriptionVerificationToken:String ,request: RouterRequest, response: RouterResponse) {
    
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
                    let r = response.status(.OK)
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
}
