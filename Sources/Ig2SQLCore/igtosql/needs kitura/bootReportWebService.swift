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


func bootReportWebService() {

    func jsonresp () -> Ig2SQLStatus {
        let now = Date()
  
                return Ig2SQLStatus(  servertitle:  "Ig2SQLReportService",  applicationName:"IG2SQL", dbName:"igbase",description: "1/1 instance",  company: "PurplePeople", organization: "DonnerParties", location: "New York, NY", version: Config.version,  serverurl: globalData.serverip, serverport: globalData.serverport,uptime: now.timeIntervalSince(globalData.boottime), timenow: now, httpgets:  globalData.apic.getIn,status:200 )
    }

    // Create a new router
    let router = Router()
    
    
    // Dont Handle HTTP GET requests to /
    // EXIT_SUCCESS Get request
    router.get("/exit") {
        request, response, next in
        DebugExitPath.sayGoodnight(response)
    }
    // JSON Get request
    router.get("/json") {
        request, response, next in
        let jsondata = try! GlobalData.jsonEncoder.encode( jsonresp() )
        sendOKPreEncoded(response,data:jsondata) 
        next()
    }
    
    
    router.get("/report/:id/:name/") {
        request, response, next in
        
        func generateReport (id:String,kind:ReportKind,qparams:[String:String], finally:((ReportResponseWrapped)->())) {
            let _ = ReportKind.anyreport(id ,name:kind,callback: { reportheaders, reportdata, elapsed in
                let rm =  ReportResponse(userid: id,reportname: "\(kind)", elapsed:elapsed,
                                         queryParameters:qparams, reportHeaders:reportheaders, reportData:  reportdata )
                let wr = ReportResponseWrapped(status: 200, time: Date(), response: rm)
                finally(wr) // call back with response
            })
        }
        
        
        if let id = request.parameters["id"],
            let name = request.parameters["name"],
            let reportKind = ReportKind.make(s: name) {
            guard let smtokenstr =  request.queryParameters["smtoken"] else {
                return   missingID(response)
            }
            if let smtoken = DDInt64(smtokenstr) {
                // call sql service to read record keyed by 'smtoken'
                SQLMaker.getLoginCredentials (smaxxtoken: smtoken,atend: {isloggedon, logincreds in
                    if isloggedon {
                        // if already logged on send back existing record
                        // make report, call closure when finished
                        generateReport(id: id,kind:reportKind, qparams: request.queryParameters) { wrappedresponse in
                            let encoder = GlobalData.jsonEncoder
                            //encoder.dateEncodingStrategy = .iso8601
                            let jsondata = try! encoder.encode(wrappedresponse)
                            sendOKPreEncoded(response,data:jsondata)
                            
                        }// generate closure
                        
                    } // logged on
                    else
                    {
                        sendErrorResponse(response, status: 400, message: "smtokenmismatch")
                        next()
                        return
                    } // not logged on
                })
            } else {
                //token did not convert
                sendErrorResponse(response, status: 400, message: "badtokenfmt")
                next()
                return
            }
        } // name is valid
        else {
            //reportnameinvalid  
            sendErrorResponse(response, status: 400, message: "reportnameinvalid")
            next()
            return
        }
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
    
    //Log.error("Smaxx Report Service started on port \(Config.report_port)")
    // Add an HTTP server and connect it to the router
    let srv = Kitura.addHTTPServer(onPort: Config.report_port, with: router)
    
    srv.started {
        //self.controllerIsFullyStarted()
        Log.info("--Server \(globalData.serverip)   ReportService started on port \(Config.report_port)")
    }
    srv.failed {status in
        Log.error("--Server \(globalData.serverip)   ReportService FAILED TO START   status \(status)   ")
        exit(1)
    }
}


