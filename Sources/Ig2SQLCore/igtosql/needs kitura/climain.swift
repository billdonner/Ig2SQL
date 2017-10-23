//
//  cliMain
//  igtosql
//
//  Created by william donner on 9/15/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//


////
///
/// TODO: MySQLDriver has been copied in and should be used as package - fix or wait?
/// TODO: Cant enable KituraSession because swift package update hangs with BlueCryptor
///
///

import Foundation
/// import  MySQLDriver
import Kitura
import KituraRequest

import KituraNet
import Health
import HeliumLogger
import LoggerAPI

struct Config {
    static let maxMediaCount = 6 // is ignored in sandbox anyway
    static let dbname = "igbase"
    static let igVerificationToken = "zzABCDEFG0123456789zz"
    // verizon routr maps external addr with port 9090 to 192.168.2.2:8080
    static let report_port   = 8090
    static let login_port = 8080
    static let webadmin_port = 8070
    
}
 
open class GlobalData {
    
    static  let jsonDecoder = JSONDecoder()
    static  let jsonEncoder = JSONEncoder()
    public struct ApiCounters :Codable{
        public  var getIn = 0
        public   var getOut = 0
        public   var postIn = 0
        public   var postOut = 0
        
    }
    open var apic = ApiCounters()
    open var usersLoggedOn : [Int:[String:Any]] = [:]
    open var usersHack: [String:[String:String]] = [:]
    public init () {
        
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
    case reportService
    case loginService
    case adminService
}

// parse command line, return anything anyone might want in a single  struct
public struct Argstuff {
    public var cycleSeconds = 0
    public var sqlDirURL : URL?
    public var exportstoreURL : URL?
    public var modelstoreURL : URL?
    public var apiFlow: APIFlow = .instagramm // tweaked to instagram only if cyceSeconds > 99 to prevent ig from getting pissed
    public  var wantsforce: Bool = false
    public var doop: Doop = .status
    public  var userID: String = ""
    public var reportName: ReportKind = .samples
    
    public init() {
        
    }
    
}

/// each user has a dedicated TasksForUser
/// the Background Manager round robins between tasks until hitting an API quota limit at which point it moves on to the next user
/// within the limitations of the api quota, the cycle funcs are executed sequentially until all are completed, then the task sleeps until sufficient time has passed for the quota limit to pass

class  UserTask {
    let userid: String
    let igtoken: String
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
    init (userid:String,igtoken:String){
        self.userid = userid
        self.igtoken = igtoken
    }
    func countApi() {
        // self.apiBuckets.apicount(1)
        globalBuckets.apicount(1)
    }
}



 var reportServiceIsBooted = false
 var loginServiceIsBooted = false
 var adminServiceIsBooted = false

var serverip : String = ""
   let globalData = GlobalData()
var health = Health()

var rk : ReportKind  = .samples

var igPoller : InstagramPoller?

var zh = ZH()

var lc : LoginController?

var startdate =  Date()

var globalBuckets = APIBuckets() // scratch space

// MARK:- open db, handle command arguments


fileprivate func startPolling(_ argcv: Argstuff) {
    igPoller = InstagramPoller(tag:"started-\(Date())",
    cycleTime:argcv.cycleSeconds,   modelstoreURL:argcv.modelstoreURL,exportstoreURL:argcv.exportstoreURL ){ title,status  in
        print ("finalcomphandler for bm \(title) \(status)")
    }
    if let thebm = igPoller {
        let apicycl = APICycle(flow: argcv.apiFlow,   bm: thebm)
        thebm.perpetualCycle(apiCycle: apicycl, repeating: { tag,status  in
        } )
    } else {
        fatalError("cant start igpoller")
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
        if let furl = argcv.modelstoreURL?.appendingPathComponent("model").appendingPathExtension("json"),
            let uid = argcv.modelstoreURL?.lastPathComponent,
                let ex = argcv.exportstoreURL {
            SQLMaker.makesql(furl: furl,uid: uid, exportURL: ex)
            exit(0)
        }
        
        
    case .once,.poller:
        startPolling(argcv)

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
    case .adminService:
        HeliumLogger.use()
        
        LoginController.discoverIpAddress() { ip in
            serverip = ip
            bootAdminWebService()
            // Start the Kitura runloop (this call never returns)
            adminServiceIsBooted = true
            Kitura.run()
        }
        
    }
}//theMain


public enum RemoteCallType {
    case tURLSession
    case tKituraSynch
    case tKituraRequest
    case tContentsOfFile
}

public let remoteCallType = RemoteCallType.tKituraSynch

public func qrandom(max:Int) -> Int {
    #if os(Linux)
        return Int(rand()) % Int(max)
    #else
        return Int(arc4random_uniform(UInt32(max)))
    #endif
}

public extension String {
    
    public func leftPadding(toLength: Int, withPad character: Character) -> String {
        
        let newLength = self.characters.count
        if newLength < toLength {
            return String(repeatElement(character, count: toLength - newLength)) + self
        } else {
            return String(self[index(self.startIndex, offsetBy: newLength - toLength)...])
        }
    }
    
}

///////////
///////////
///////////
///////////
///////////


public struct Fetch {
    
    public static func get (_ urlstr: String, session:URLSession?,use:RemoteCallType,
                            completion:@escaping (Int,Data?) ->()){
        
        func fetchViaURLSession (_ urlstr: String,_ session:URLSession?,completion:@escaping (Int,Data?) ->()){
            let url  = URL(string: urlstr)!
            let request = URLRequest(url: url)
            
            // now using a session per datatask so it hopefully runs better under linux
            
            //fatal error: Transfer completed, but there's no currect request.: file Foundation/NSURLSession/NSURLSessionTask.swift, line 794
            
            //https://github.com/stormpath/Turnstile/issues/31
            let task = session?.dataTask(with: request) {data,response,error in
                if let httpResponse = response as? HTTPURLResponse  {
                    let code = httpResponse.statusCode
                    guard code == 200 else {
                        print("remoteHTTPCall to \(url) completing with error \(code)")
                        completion(code,nil) //fix
                        return
                    }
                }
                guard error == nil  else {
                    
                    print("remoteHTTPCall to \(url) completing  error \(String(describing: error))")
                    completion(529,nil) //fix
                    return
                }
                
                // handle response
                
                completion(200,data)
            }
            task?.resume ()
        }
        
        
        func fetchViaContentsOfFile(_ urlstr: String, _ session:URLSession?,completion:@escaping (Int,Data?) ->()) {/// makes http request outbund
            do {
                if  let nurl = URL(string:urlstr) {
                    let  data =  try Data(contentsOf: nurl)
                    completion (200,data)
                }
            }
            catch {
                completion (527, nil)
            }
        }
        
        func fetchViaKituraRequest(_ urlstr: String, _ session:URLSession?,completion:@escaping (Int,Data?) ->()) {
            KituraRequest.request(.get, urlstr).response {
                request, response, data, error in
                guard error == nil  else {
                    
                    print("remoteHTTPCall to \(urlstr) completing  error \(String(describing: error))")
                    
                    completion(529,nil) //fix
                    return
                }
                guard let data = data else {
                    completion(527,nil)
                    return
                }
                completion(200,data)
            }
        }
        
        func fetchViaKitura(_ urlstr: String, _ session:URLSession?,completion:@escaping (Int,Data?) ->()) {/// makes http request outbund
            func innerHTTP( requestOptions:inout [ClientRequest.Options],completion:@escaping (Int,Data?) ->()) {
                var responseBody = Data()
                let req = HTTP.request(requestOptions) { response in
                    if let response = response {
                        guard response.statusCode == .OK else {
                            _ = try? response.readAllData(into: &responseBody)
                            completion(404,responseBody)
                            return }
                        _ = try? response.readAllData(into: &responseBody)
                        completion(200,responseBody)
                    }
                }
                req.end()
            }
            var requestOptions: [ClientRequest.Options] = ClientRequest.parse(urlstr)
            let headers = ["Content-Type": "application/json"]
            requestOptions.append(.headers(headers))
            innerHTTP(requestOptions: &requestOptions,completion:completion)
        }
        
        let remoteCallType:RemoteCallType = use
        
        switch remoteCallType {
            
        case RemoteCallType.tURLSession:
            fetchViaURLSession(urlstr, session, completion: completion)
        case RemoteCallType.tKituraSynch:
            fetchViaKitura(urlstr, session, completion: completion)
        case RemoteCallType.tKituraRequest:
            fetchViaKituraRequest(urlstr, session, completion: completion)
        case RemoteCallType.tContentsOfFile:
            fetchViaContentsOfFile(urlstr, session, completion: completion)
        }
    }
}

/// standard error responses -

struct ErrResponse<T:Codable> : Codable {
    let status:Int
    let message:T
    let timenow:Date
}
func  sendErrorResponse(_ response:RouterResponse,status:Int,message:String) {
    let err = ErrResponse<String>(status: status, message:message, timenow: Date())
    let jsondata = try!  GlobalData.jsonEncoder.encode(err)
    response.headers["Content-Type"] = "application/json; charset=utf-8"
    try! response.status(.badRequest).send(data: jsondata).end()
}
func  sendOKResponse(_ response:RouterResponse, data:[String:String]) {
    let err = ErrResponse<[String:String]>(status: 200, message: data, timenow: Date())
    let data = try!  GlobalData.jsonEncoder.encode(err)
    sendOKPreEncoded(response, data: data)
}
func    sendOKPreEncoded(_ response: RouterResponse,data:Data)  {
    response.headers["Content-Type"] = "application/json; charset=utf-8"
    try! response.status(.OK).send(data:  data).end()
}

public  func missingID(_ response:RouterResponse) {
    sendErrorResponse(response,  status: 404, message: "no id" )
    
}
public   func unkownOP(_ response:RouterResponse) {
    sendErrorResponse(response, status: 403, message: "bad op")
}
