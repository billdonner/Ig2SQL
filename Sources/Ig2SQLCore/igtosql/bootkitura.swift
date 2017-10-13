//
//  bootkitura.swift
//  igtosql
//
//  Created by william donner on 9/15/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation
import Kitura
import Health
import LoggerAPI

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
var   health = Health()
func bootKitura() {
    // Create a new router
    let router = Router()
   
    
    // Handle HTTP GET requests to /
    // Serve static content from "public"
    router.all("/", middleware: StaticFileServer())
    
    
    // Basic POST request
    router.post("/hello", handler: postHello)
    
    // JSON Get request
    router.get("/json", handler: getJSON)
    
    // Basic application health check
    router.get("/health", handler: getHealthCheck)
    
    // Basic application health check
    router.get("/loopback", handler: getHealthCheck)
    
    // stawsh token stuff (temp
    router.post("/stash", handler: postHello)
    

    router.get("/report/:id/:name/") {
        request, response, next in
        if let id = request.parameters["id"],
            let name = request.parameters["name"],
            let reportKind = ReportKind.make(s: name) {
            // make report, call closure when finished
         generateResponse(id: id,kind:reportKind, qparams: request.queryParameters) { wrappedresponse in 
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

/**
 * Handler for getting a text/plain response.
 */
public func getHello(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    Log.debug("GET - /hello route handler...")
    response.headers["Content-Type"] = "text/plain; charset=utf-8"
    try response.status(.OK).send("Hello from Kitura-Starter!").end()
}

/**
 * Handler for posting the name of the entity to say hello to (a text/plain response).
 */
public func postHello(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    Log.debug("POST - /hello route handler...")
    response.headers["Content-Type"] = "text/plain; charset=utf-8"
    if let name = try request.readString() {
        try response.status(.OK).send("Hello \(name), from Kitura-Starter!").end()
    } else {
        try response.status(.OK).send("Kitura-Starter received a POST request!").end()
    }
}

/**
 * Handler for getting an application/json response.
 */
public func getJSON(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    Log.debug("GET - /json route handler...")
    response.headers["Content-Type"] = "application/json; charset=utf-8"
    var jsonResponse :[String:String] = [:]
    jsonResponse["framework"]  = "Kitura"
    jsonResponse["applicationName"]  = "IG2SQL"
    jsonResponse["company"]  = "PurplePeople"
    jsonResponse["organization"]  = "DonnerParties"
    jsonResponse["location"] = "New York, NY"
    let jsondata = try  Config.jsonEncoder.encode(jsonResponse)
    try response.status(.OK).send(data: jsondata).end()
}

/**
 * Handler for getting a text/plain response of application health status.
 */
public func getHealthCheck(request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
    Log.debug("GET - /health route handler...")
    let result = health.status.toSimpleDictionary()
    if health.status.state == .UP {
        try response.send(json: result).end()
    } else {
        try response.status(.serviceUnavailable).send(json: result).end()
    }
}

