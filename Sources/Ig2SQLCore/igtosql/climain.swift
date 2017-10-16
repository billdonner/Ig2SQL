//
//  igmain.swift
//  igtosql
//
//  Created by william donner on 9/15/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//


////
///
/// TODO: MySQLDriver has been copied in and should be used as package - fix or wait?
/// TODO: Cant enable KituraSession because swift package update hangs with BlueCryptor
import Foundation
/// import  MySQLDriver
import Kitura
import Health
import HeliumLogger
import LoggerAPI

struct Config {
    static let maxMediaCount = 6 // is ignored in sandbox anyway
    static let dbname = "igbase"
    static  let jsonDecoder = JSONDecoder()
    static  let jsonEncoder = JSONEncoder()
    
    // verizon routr maps external addr with port 9090 to 192.168.2.2:8080
    static let report_port   = 8090
    static let login_port = 8080
    
}

public  var reportServiceIsBooted = false
public  var loginServiceIsBooted = false

var serverip : String = ""

var health = Health()

var rk : ReportKind  = .samples

var igPoller : InstagramPoller?

var zh = ZH()

var lc : LoginController?

var startdate =  Date()

/// standard error responses -

//func finishJSONStatusResponse(_ extra: [String:Any], request: RouterRequest, response: RouterResponse  , status:Int = 200, next: @escaping () -> Void) throws {
//    let now = Date()
//    let uptime = now.timeIntervalSince(startdate)
//    let prettysecs = String(format:"%0.2f",uptime)
//    var out :  [String:Any] = ["server-url":serverip,"response-status":status,"servertitle":loginServiceIsBooted ? "loginsvc":"reportsvc","description":serverConfig.description,"softwareversion":"1.0","elapsed-secs":"\(prettysecs)","up-time":uptime,"timenow":"\(Date())","httpgets":globalData.apic.getIn]
//    
//    for (key,val) in extra {
//        out[key]=val
//    }
//    
//    response.headers["Content-Type"] = "application/json; charset=utf-8"
//    let data = try JSONSerialization.data(withJSONObject:out, options:.prettyPrinted )
//    try response.status(.OK).send(data:data).end()
//}
//public   func log (request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) throws {
//    let qp = request.queryParameters
//    /// for now - just put all the query paramters into the log
//    Log.info("LOGLINE \(qp)")
//    // prepare payload
//    let out = ["logged":qp ] as [String : Any]
//    // send ack to caller
//    try finishJSONStatusResponse(out, request: request, response: response, next: next)
//    
//}

public  func missingID(_ response:RouterResponse) {
    response.headers["Content-Type"] = "application/json; charset=utf-8"
    let out:[String:Any] = ["status":404 ,"results":"no ID","timenow":"\(Date())"]
    do {
        let data = try JSONSerialization.data(withJSONObject:out, options: .prettyPrinted)
        
        try response.status(.OK).send(data:data).end() } catch {
            Log.error("can not send response in missingID")
    }
}
public   func unkownOP(_ response:RouterResponse) {
    response.headers["Content-Type"] = "application/json; charset=utf-8"
    let out:[String:Any] = ["status":404 ,"results":"no ID","timenow":"\(Date())"]
    do {
        let data = try JSONSerialization.data(withJSONObject:out, options: .prettyPrinted)
        
        try response.status(.OK).send(data:data).end() } catch {
            Log.error("can not send response in missingID")
    }
}
public func cliMain(_ argcv:Argstuff) {
    
    // processed args passed in
    
    try! zh.openigbase()
    
    switch argcv.doop {
        
    case .report:
        let _ =  rk.anyreport(argcv.userID,name:argcv.reportName ) { headers, data, elapsed  in
            
        }
        exit(0)
        
    case .status:
        print("\(Config.dbname) status: disconnected right now");
        //showstatus( )
        exit(0)
        
    case .create:
        zh.createallTables()
        exit(0)
        
    case .force:
        try! zh.freshdb(Config.dbname)
        zh.createallTables()
        exit(0)
        
    case .export:
        if let furl = argcv.modelDirURL?.appendingPathComponent("model").appendingPathExtension("json"),
            let uid = argcv.modelDirURL?.lastPathComponent{
            do {
                let data = try Data(contentsOf: furl)
                let model = try  Config.jsonDecoder.decode(Model.self, from: data)
                let sqlm = SQLMaker(models:[model ])
                sqlm.generateNativeSql( ){ createSQL, insertSQL , temptableSQL in
                    let spacer = "\n--\n"
                    let dropmake = "DROP DATABASE IGBASE; CREATE DATABASE IGBASE; USE IGBASE;"
                    let jumboSQL = dropmake + spacer + createSQL + spacer + insertSQL + spacer + temptableSQL + spacer
                    if let xd =  argcv.exportDirURL?.appendingPathComponent(uid, isDirectory: true) {
                        do {
                            try FileManager.default.createDirectory(at: xd, withIntermediateDirectories: true, attributes: [:])
                            
                            let createsqlurl = xd.appendingPathComponent("header.sql")
                            let insertsqlurl = xd.appendingPathComponent("inserts.sql")
                            let temptablesqlurl = xd.appendingPathComponent("temptables.sql")
                            let onefileurl = xd.appendingPathComponent("recreate.sql")
                            try  createSQL.write(to: createsqlurl, atomically: true, encoding: .utf8 )
                            try  insertSQL.write(to: insertsqlurl, atomically: true, encoding: .utf8 )
                            try  temptableSQL.write(to: temptablesqlurl, atomically: true, encoding: .utf8 )
                            try  jumboSQL.write(to: onefileurl, atomically: true, encoding: .utf8 )
                            print()
                            print("Exported all tables to mysql import files")
                            print()
                        }
                        catch {
                            print ("could not write sql files error \(error)")
                        }
                    }
                }
            }//do
            catch {
                print ("could not read model files error \(error)")
            }
            exit(0)
        }
        
        
    case .once:
        igPoller = InstagramPoller(tag:"started-\(Date())",
            cycleTime:0,   usersFileURL: argcv.usersFileURL! ,  modelDirURL: argcv.modelDirURL ,
            sqlDirURL: argcv.sqlDirURL ,  exportDirURL:argcv.exportDirURL ){ title,status  in
                print ("finalcomphandler for bm \(title) \(status)")
        }
        if let thebm = igPoller {
            let apicycl = APICycle(flow: argcv.apiFlow,   bm: thebm)
            thebm.perpetualCycle(apiCycle: apicycl, repeating: { tag,status  in
            } )
        }
    case .poller:
        igPoller = InstagramPoller(tag:"started-\(Date())",
            cycleTime:argcv.cycleSeconds,   usersFileURL: argcv.usersFileURL ,  modelDirURL: argcv.modelDirURL ,
            sqlDirURL: argcv.sqlDirURL ,  exportDirURL:argcv.exportDirURL ){ title,status  in
                print ("finalcomphandler for bm \(title) \(status)")
        }
        if let thebm = igPoller {
            let apicycl = APICycle(flow: argcv.apiFlow,   bm: thebm)
            thebm.perpetualCycle(apiCycle: apicycl, repeating: { tag,status  in
            } )
        }
    case .reportService:
        HeliumLogger.use()
        LoginController.discoverIpAddress() { ip in
            serverip = ip
            bootReportWebService()
            // Start the Kitura runloop (this call never returns)
            reportServiceIsBooted = true
            Kitura.run()
        }
        
    case .loginService:
        HeliumLogger.use()

        LoginController.discoverIpAddress() { ip in
            serverip = ip
            bootLoginWebService()
            // Start the Kitura runloop (this call never returns)
            loginServiceIsBooted = true
            Kitura.run()
        }
        
    }
}//theMain
