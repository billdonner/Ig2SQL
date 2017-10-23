//
//  CommandHandler
//  igpolling
//
//  Created by william donner on 9/1/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation

public struct CommandHandler {
    
    private static func badform() -> Argstuff? {
        print("Ig2SQL  export  -dModelPath -xExportTopFolderPath // no db needed, generates mysql import file");
        print("Ig2SQL  create  // makes tables,unless they already exists");
        print("Ig2SQL  force   // makes tables, drops them first");
        print("Ig2SQL  poller  -dModelTopFolderPath  [-c=600] [ -insert=1] // default is to insert records");
        print("Ig2SQL  once    -dModelTopFolderPath   [ -insert=1] // default is to insert records repeatedly");
        print("Ig2SQL  status");
        print("Ig2SQL  report   -iUIDfor -rNameofReport");
        print("Ig2SQL  reportsrv // kitura starts on 8090");
        print("Ig2SQL  loginsrv // kitura starts on 8080");
        print("Ig2SQL  adminsrv // kitura starts on 8070");
        return nil
    }
    
   public static func processargs(argv:[String])  -> Argstuff? {
        var args = Argstuff()
        //1
        let argCount = argv.count
        guard argCount > 1 else {  return badform() }
    
        switch argv[1]   {
            
        case "status": args.doop = .status; return args;
            
        case "reportsrv": args.doop = .reportService; return args;
            
        case "adminsrv": args.doop = .adminService; return args;
            
        case "loginsrv": args.doop = .loginService; return args;
            
        case "once"   : args.doop = .once;
        guard argCount > 2 else {  return badform() }
        guard argv[2].hasPrefix("-d") else { return badform()  }
        args.modelstoreURL = URL.init(fileURLWithPath:  String(argv[2].dropFirst(2)))
        args.cycleSeconds =  0 /// forced
        args.apiFlow =  .instagramm
        return args;// -dModelTopFolderPath  -uUserCredsFilePath [ -insert=1]
            
        case "poller" : args.doop = .poller;
        guard argCount > 2 else {  return badform() }
        guard argv[2].hasPrefix("-d") else { return badform()  }
        args.modelstoreURL = URL.init(fileURLWithPath:  String(argv[2].dropFirst(2)))
        // optionals
        if argCount > 3 {
            guard argv[3].hasPrefix("-c=") else {
                return badform()
            }
            args.cycleSeconds = Int(argv[3].dropFirst(3)) ?? 0
            args.apiFlow = args.cycleSeconds > 99 ? .instagramm : .debug
        }
        return args;// -dModelTopFolderPath -uUserCredsFilePath  [-c=600] [ -insert=1]
            
        case "create" :args.doop = .create
        if argCount > 2 {
            args.wantsforce =  argv[2].hasPrefix("-force")
            args.doop = .force
        }
        print("create \(args.wantsforce)")
        return args;// [-force]
            
        case "export" :args.doop = .export;
        guard argCount > 3 else {  return badform() }
        guard argv[2].hasPrefix("-d") else { return badform() }
        args.modelstoreURL = URL.init(fileURLWithPath: String(argv[2].dropFirst(2)))
        guard argv[3].hasPrefix("-x") else { return badform() }
        args.exportstoreURL = URL.init(fileURLWithPath: String(argv[3].dropFirst(2)))
        return args;// -dModelPath -xExportTopFolderPath
            
        case "report" :args.doop = .report;
        guard argCount > 3 else {  return badform() }
        guard argv[2].hasPrefix("-i") else { return badform() }
        args.userID = String(argv[2].dropFirst(2))
        guard argv[3].hasPrefix("-r") else { return badform() }
        
        guard let rpt =  ReportKind.make(s:String(argv[3].dropFirst(2)))
            else { return badform() }
        args.reportName = rpt
        return args;// -dModelPath -xExportTopFolderPath
            
        default: return badform();
        }
    }
    
}

