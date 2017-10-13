//
//  bootkitura.swift
//  igtosql
//
//  Created by william donner on 9/15/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation
import Kitura

struct ResponseModel:Codable {
    let userid:String
    let reportname:String
    let elapsed:TimeInterval
    let queryParameters:[String:String]
    let reportHeaders: [ String]
    let reportData: [[String]]
}
struct WrappedResponse:Codable {
    let status: Int
    let time: Date
    let response: ResponseModel
}
func generateResponse (id:String,kind:ReportKind,qparams:[String:String], finally:((WrappedResponse)->())) {
    let _ = rk.anyreport(id ,name:kind,callback: { reportheaders, reportdata, elapsed in
     let rm =  ResponseModel(userid: id,reportname: "\(kind)", elapsed:elapsed,
        queryParameters:qparams, reportHeaders:reportheaders, reportData:  reportdata )
        let wr = WrappedResponse(status: 200, time: Date(), response: rm)
        finally(wr) // call back with response
    })
}

func bootKitura() {
    // Create a new router
    let router = Router()
    
    // Handle HTTP GET requests to /

    router.get("/report/:id/:name/") {
        request, response, next in
        if let id = request.parameters["id"],
            let name = request.parameters["name"],
            let reportKind = ReportKind.freport(s: name){
         generateResponse(id: id,kind:reportKind, qparams: request.queryParameters) { wrappedresponse in
            //let reportData = responseModel.reportData
            let jsondata = try! Config.jsonEncoder.encode(wrappedresponse)
            response.status(.OK).send(data: jsondata)
        }
       
        
        } else {
            let jsondata = try Config.jsonEncoder.encode(["error":"badrequest"])
            response.status(.badRequest).send(data: jsondata)
        }
        next()
    }
    router.get("/") {
        request, response, next in
        response.status(.OK).send("Greetings from Ig2SQL Kitura Web Application Service")
        next()
    }
    
    // Add an HTTP server and connect it to the router
    Kitura.addHTTPServer(onPort: 8080, with: router)
    
    // Start the Kitura runloop (this call never returns)
    Kitura.run()
}
