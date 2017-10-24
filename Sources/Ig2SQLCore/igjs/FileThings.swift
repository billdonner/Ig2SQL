//
//  FileThings.swift
//  igpolling
//
//  Created by william donner on 8/31/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation

extension InstagrammModel {
 
    static let df = DateFormatter()
    
  static func datawrite(tag:String,data:Data?) {
        // write to disk only if there
        
//        if let data = data,
//            let dir = igPoller?.modelstoreURL?.appendingPathComponent(tag, isDirectory: true){
//            let furl = dir.appendingPathComponent("model").appendingPathExtension("json")
//            do {
//                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: [:])
//                try data.write(to: furl, options:[])
//                
//            }
//            catch {
//                print("Could not persist file \(furl) error \(error)")
//            }
//        }
    }
    public  static func verifyThenSave<T:Codable>(_ m:T,tag:String) -> Bool {
        let e = T.self 
        do {
            let encodedMaster = try GlobalData.jsonEncoder.encode(m)
             datawrite(tag:tag,data: encodedMaster)
            let _ = try  GlobalData.jsonDecoder.decode(e, from: encodedMaster)
        }
        catch {
            // print ("Coudnt encode/decode \(e)")
            return false
        }
        return true
    }
}
extension InstagramPoller {
 
    func xpo(exportURL:URL?) {
        // gather up all top level models and pass them in
        let sqlm = SQLMaker(models:[self.model])
        sqlm.executeNativeSql() { temptableSQL in
            print()
            print("Created all tables and did native mysql inserts ")
            print()
        }
        
        sqlm.generateNativeSql( ){ createSQL, insertSQL , temptableSQL in
            let spacer = "\n--\n"
            let dropmake = "DROP DATABASE IGBASE; CREATE DATABASE IGBASE; USE IGBASE;"
            let jumboSQL = dropmake + spacer + createSQL + spacer + insertSQL + spacer + temptableSQL + spacer
            
            if let xurl = exportURL {
                let xd = xurl.appendingPathComponent(uid, isDirectory: true)
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
                }
                catch {
                    print ("could not write sql files error \(error)")
                }
            }
        }
    }
    func saveModelAndExportAtBitterEnd(_ uid:String){
        let expstarttime = Date()
        let succ =    InstagrammModel.verifyThenSave(self.model,tag: uid)
        
            NSLog("completed \(succ ? "pass":"fail") exportVerifiedModel Model-\(uid) in \(Date().timeIntervalSince(expstarttime))secs")
        }
}
// MARK: - not generic  static funcs
extension Instagramm { // not generic static funcs
    public static   func getKeysDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0].appendingPathComponent("keys", isDirectory: true)
        try? FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: false, attributes: nil)
        return documentsDirectory
    }
    
    public static   func getQueriesDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0].appendingPathComponent("stablequeries", isDirectory: true)
        try? FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: false, attributes: nil)
        return documentsDirectory
    }
    public static   func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0].appendingPathComponent("stuff", isDirectory: true)
        try? FileManager.default.createDirectory(at: documentsDirectory, withIntermediateDirectories: false, attributes: nil)
        return documentsDirectory
    }
    
    public static  func getDirContentsForUser(_ userid:String) -> [URL] {
        
        var urls: [URL] = []
        do {
            var dirContents = try FileManager.default.contentsOfDirectory(at: Instagramm.getDocumentsDirectory() , includingPropertiesForKeys: nil)
            dirContents.sort() { $0.lastPathComponent > $1.lastPathComponent }
            for url in dirContents {
                
                let pathext = url.pathExtension
                guard pathext == "json" else {break}
                let pieces = url.deletingPathExtension().lastPathComponent.components(separatedBy: "-")
                let puserid =  pieces[2]
                if userid == puserid {
                    urls.append(url)
                }
            }// for
            return urls
        } catch {
            
        }
        return []
    }
}
