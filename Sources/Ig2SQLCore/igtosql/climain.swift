//
//  igmain.swift
//  igtosql
//
//  Created by william donner on 9/15/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation
struct Config {
    static let maxMediaCount = 6 // is ignored in sandbox anyway
    static let dbname = "igbase"
    static  let jsonDecoder = JSONDecoder()
    static  let jsonEncoder = JSONEncoder()
}


var rk : ReportKind  = .samples

var igPoller : InstagramPoller?

let con = MySQL.Connection()

public func cliMain(_ argcv:Argstuff) {
    
    // processed args passed in
    
    try! openigbase()
    
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
        createallTables()
        exit(0)
        
    case .force:
        try! freshdb(Config.dbname)
        createallTables()
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
    case .bootkitura:
        print("entering bootkitura")
        bootKitura()
    }
}//theMain
