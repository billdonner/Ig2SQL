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

func bootLoginWebService() {
    
    //print("booting LoginWebService on port \(Config.login_port)")
    // Create a new router
    let router = Router()
    do {
        lc = try LoginController(tag: "loginsvc")
    }
    catch {
        fatalError("couldnt create logincontroller")
    }
    
    // Dont Handle HTTP GET requests to /
    
    // JSON Get request
    router.get("/json") {
        request, response, next in
        let data :[String:String] =
            ["framework":"Ig2SQLLoginService",
             "applicationName": "IG2SQL",
            "company": "PurplePeople",
            "organization": "DonnerParties",
            "location" : "New York, NY"]
        sendOKResponse(response, data: data)
        
    }
    
 
    
    // MARK: Callback GETs and POSTs from IG come here
    ///
    router.get("/logout")  { request, response, next in
        
        guard let lc = lc else { return }
        guard let smtokeni = request.queryParameters["smtoken"]  else {
            return  missingID(response)
        }
        guard let smtoken = Int(smtokeni) else {
            return  missingID(response)
        }
       
        zh.getLoginCredentials (smaxxtoken: smtoken,atend: {isloggedon, _,name,pic,igid,_ in
            if isloggedon {
             //let loggedOnData =  lc.globalData.usersLoggedOn[smtoken]
            zh.deleteLoginCredentials(smaxxtoken: smtoken)
            lc.globalData.usersLoggedOn[smtoken] = nil
                sendOKResponse(response, data:["desc":"logged out from here"])
              
        }
            sendErrorResponse(response, status: 402, message: "notloggedon")
            
        })
    }
    
    // This should get the ball rolling
    router.get("/login")  { request, response, next in
        
        guard let lc = lc else { return }
        guard let smtokenstr =  request.queryParameters["smtoken"] else {
            // if no token passed in then just go for full login
            lc.globalData.apic.getIn += 1
            lc.STEP_ONE(response) // will redirect to IG
            return
        }
        if let smtoken = Int(smtokenstr) {
            // call sql service to read record keyed by 'smtoken'
            zh.getLoginCredentials (smaxxtoken: smtoken,atend: {isloggedon, _,name,pic,igid,_ in
          
                if isloggedon {
                 // if already logged on send back existing record 
                    let jsondata = try!  Config.jsonEncoder.encode(SmaxxResponse(status: 203, igid: igid, pic: pic, smaxxtoken: smtoken, name: name))
                    sendOKPreEncoded(response,data:jsondata)
                  
                }
                else
                {
                    // not logged on, so go to step one
                    
                    lc.globalData.apic.getIn += 1
                    lc.STEP_ONE(response) // will redirect to IG
                }
            })
        } else { // ill-formed smtoken
         return   missingID(response)
        }
    
    }
    
    router.get("/authcallback" ) { request, response, next in
        //Log.error("************* /authcallback will authenticate ")
        lc?.STEP_TWO (request, response: response ) { status in
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
            let data = try  Config.jsonEncoder.encode(dict)
           sendOKPreEncoded(response, data: data)
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
        
        guard let who = request.parameters["who"] else { return   missingID(response)  }
        
        //        guard let token = request.parameters["token"] else { return  missingID(response)  }
        //        guard let rid = request.parameters["id"] else { return  missingID(response)  }
        
        let ix = lc.usersHack[who]
        guard let x = ix else {
            return   missingID(response)
        }
        
        guard let _ = x["userid"], let token = x["apitoken"] else {
            return   missingID(response)
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
     
    // Add an HTTP server and connect it to the router
    let srv = Kitura.addHTTPServer(onPort: Config.login_port, with: router)
    srv.started {
        Log.info("--Server \(serverip)   LoginService started on port \(Config.login_port) ")
    }
    srv.failed {status in
        Log.error("--Server \(serverip)   LoginService FAILED TO START   status \(status)   ")
        exit(1)
    }
}


