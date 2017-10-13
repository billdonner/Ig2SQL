//
//  CyclicalTasks.swift
//  igpolling
//
//  Created by william donner on 9/1/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation

public struct CommandHandler {
    
    private static func badform() -> Argstuff? {
        print("ig4sql  export  -dModelPath -xExportTopFolderPath // no db needed, generates mysql import file");
        print("ig4sql  create  // makes tables,unless they already exists");
        print("ig4sql  force   // makes tables, drops them first");
        print("ig4sql  poller  -dModelTopFolderPath -uUserCredsFilePath  [-c=600] [ -insert=1] // default is to insert records");
        print("ig4sql  once    -dModelTopFolderPath  -uUserCredsFilePath [ -insert=1] // default is to insert records repeatedly");
        print("ig4sql  status");
        print("ig4sql  report   -iUIDfor -rNameofReport");
        print("ig4sql  kitura");
        return nil
    }
    
   public static func processargs(argv:[String])  -> Argstuff? {
        var args = Argstuff()
        //1
        let argCount = argv.count
        guard argCount > 1 else {  return badform() }
        
        
        switch argv[1]   {
            
        case "status": args.doop = .status; return args;
        case "kitura": args.doop = .bootkitura; return args;
        case "once"   : args.doop = .once;
        guard argCount > 3 else {  return badform() }
        guard argv[2].hasPrefix("-d") else { return badform() }
        args.modelDirURL = URL.init(fileURLWithPath: String(argv[2].dropFirst(2)))
        guard argv[3].hasPrefix("-u") else { return badform()  }
        args.usersFileURL = URL.init(fileURLWithPath:  String(argv[3].dropFirst(2)))
        args.cycleSeconds =  0
        args.apiFlow =  .instagramm
        return args;// -dModelTopFolderPath  -uUserCredsFilePath [ -insert=1]
            
        case "poller" : args.doop = .poller;
        guard argCount > 3 else {  return badform() }
        guard argv[2].hasPrefix("-d") else { return badform() }
        args.modelDirURL = URL.init(fileURLWithPath: String(argv[2].dropFirst(2)))
        guard argv[3].hasPrefix("-u") else { return badform()  }
        args.usersFileURL = URL.init(fileURLWithPath:  String(argv[3].dropFirst(2)))
        // optionals
        if argCount > 4 {
            guard argv[4].hasPrefix("-c=") else {
                return badform()
            }
            args.cycleSeconds = Int(argv[4].dropFirst(3)) ?? 0
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
        args.modelDirURL = URL.init(fileURLWithPath: String(argv[2].dropFirst(2)))
        guard argv[3].hasPrefix("-x") else { return badform() }
        args.exportDirURL = URL.init(fileURLWithPath: String(argv[3].dropFirst(2)))
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
public enum Doop  {
    case status
    case once   // -dModelTopFolderPath  -uUserCredsFilePath [ -insert=1]
    case poller // -dModelTopFolderPath -uUserCredsFilePath  [-c=600] [ -insert=1]
    case create // [-force]
    case force // [-force]
    case export // -dModelPath -xExportTopFolderPath
    case report // UIDfor NameofReport
    case bootkitura
}
// parse command line, return anything anyone might want in a single  struct
public struct Argstuff {
    public var cycleSeconds = 0
    public var usersFileURL : URL?
    public var sqlDirURL : URL?
    public var exportDirURL : URL?
    public var modelDirURL : URL?
    public var apiFlow: APIFlow = .instagramm // tweaked to instagram only if cyceSeconds > 99 to prevent ig from getting pissed
    public  var wantsforce: Bool = false
    public var doop: Doop = .status
    public  var userID: String = ""
    public var reportName: ReportKind = .samples
    public  var bootKitura = false
    
    public init() {
        
    }
    
}

/// each user has a dedicated TasksForUser
/// the Background Manager round robins between tasks until hitting an API quota limit at which point it moves on to the next user
/// within the limitations of the api quota, the cycle funcs are executed sequentially until all are completed, then the task sleeps until sufficient time has passed for the quota limit to pass

class  PerUserInfo {
    let userid: String 
    //var apiBuckets  = APIBuckets() // must be multiplexed as we switch tasks
    
    // runIndex points to task to run
    //  nil - there is none
    //  -1 all tasks are run
    // +n - running task n
    
    private var runIndex: Int?  = nil
    
    func makeIdle() {
        runIndex = nil
    }
    func makeReady( ) {
        runIndex = -1
    }
    func makeBusy(step:Int) {
        runIndex = step
    }
    func isReady()->Bool {
        return  runIndex == -1
    }
    func isIdle()->Bool {
        return  runIndex == nil
    }
    func isBusy()->Bool {
        return  runIndex != nil && runIndex != -1
    }
    init (userid:String){
        self.userid = userid
    }
    func countApi() {
        // self.apiBuckets.apicount(1)
        globalBuckets.apicount(1)
    }
}
