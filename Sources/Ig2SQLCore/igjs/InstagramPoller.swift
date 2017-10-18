 //
 //  InstagramPoller.swift
 //  igjs
 //
 //  Created by william donner on 7/14/17.
 //  Copyright © 2017 midnightrambler. All rights reserved.
 //
 
 //TODO: integrate endofcycle
 import Foundation
 //cyclesign( uid:String,  _ finally:@escaping UseridStatusCompletionHandler)
 typealias CompletionHandler =  (Int)->()
 typealias UseridStatusCompletionHandler  = (String,Int)->()
 typealias TaggedStatusRepeatingFunc = (String,Int)->()
 typealias TaskFunc =  (@escaping  UseridStatusCompletionHandler)->() 
 
 // this is a singleton class only  because we are making just one of these
 // once per second, all tasks are examined, and any executable tasks are run
 // in practice we ensure there is only one runnable task which completely reduces parallelism and instead we rely on
 // running separate background managers as separate processes, possibbly on multiple servers
 
 func dbgprint(_ s:String) {
    if !s.hasPrefix("*****") {
        // DispatchQueue.main.async {
        
        NSLog(s) // prints with timestamp
    }
    // }
 }
 
 ///
 /// How It Works:
 
 /**
  
  The singleton Background Manager manages an array of Tasks for each User under its control, as if it were a
  
  %%  U X T sparse array
  
  At any time there is only
  
  %% 1 Active Task
  
  CurrentIndexForUserTasks is always valid and points to a group of Tasks for this user, each of which is executed serially
  
  %% to achieve this there is a a once per second wakeup timer and various counter variables
  
  when all of the tasks for one User are done, the outermost completion callback is finally executed and we move on to the next user on the
  */
 
 
 final  class InstagramPoller {
    
    enum MoveOutcome {
        case movedToNextTaskSoExecuteNow
        case didMoveToNextUserAndExecuteNow
        case didMoveToNextUserButDontExecute
        case didNotMove
    }
    struct Cntrs :Codable {
        var pollcount = 0
        var cycleSecsDowncounter = 0
        var secsPerpetualUpCounter = 0
        var apiCountThisCycle = 0
    }
    struct UsersOnDiskModel:Codable {
        
        struct UserCreds :Codable {
            let name:String
            let id:String
            let token:String
        }
        let description:String
        let users:[UserCreds]
    }
    deinit {
        timer?.cancel()
        timer = nil
    }
    var timer: DispatchSourceTimer?
    let baseCycleTime:Int
    
    var isRunning = false
    var cyclestarttime = Date()
    var cnt = Cntrs()
    var apiCycle : APICycle?
    
    var model: InstagrammModel!
    //var scratchmem : NonPersistentObjs!
    var usersOnDisk : UsersOnDiskModel!
    private var perUserTasks: [PerUserInfo] = []
    private var thisUserTask : PerUserInfo
    private var currentUserIndex = -1 {
        didSet {
            // print("Index for Current TaskForUser now \(indexForCurrentTaskForUser)")
        }
    }
    var uid : String = "" // changes
    var context:String = ""
    let timerqueue = DispatchQueue(label: "com.midnightrambler.timer", attributes:.concurrent)
    var finalcomphandler: UseridStatusCompletionHandler
    var usersFileURL:  URL?
    var modelDirURL: URL?
    var sqlDirURL:  URL?
    var exportDirURL: URL?
    
    // let funcs:[TaskFunc]
    func delay(_ delay: Double, closure:@escaping (() -> Void)) {
        timerqueue.asyncAfter(deadline:  .now() + delay) {
            closure()
        }
    }
 
    // count runnable tasks, there should be only one
    func countRunnable()->Int {
        var runnable = 0
        perUserTasks.forEach(){task  in
            runnable += task.isIdle() ? 0 : 1
        }
        return runnable
    }
    
 
    func bitterend(_ status:Int, _ finally:@escaping UseridStatusCompletionHandler) {
        self.model.lastApiStatus = status
        self.model.cyclestart = self.cyclestarttime
        self.model.cycleelapsed =   Date().timeIntervalSince(self.cyclestarttime)
        self.model.cyclenumber += 1
        let elapsed = String(format:"%0.2f",(self.model.cycleelapsed))
        let expstarttime = Date()
        self.saveModelAndExportAtBitterEnd(uid)
        
        let savetime = String(format:"%0.2f",Date().timeIntervalSince(expstarttime))
        
        dbgprint("  - \(uid) cycle finished status: \(status) apicount: \(globalBuckets.totalcount - cnt.apiCountThisCycle) elpased: \(elapsed) \(savetime) ")
        
        thisUserTask.makeIdle() // otherwise mark me as idle
            finally(uid,status)
            if self.currentUserIndex < self.usersOnDisk.users.count - 1 { // if not last
                self.cnt.cycleSecsDowncounter = 0 // force immediate
            }
    }
    // cycles around to next user, reading model off disk if possible, returns TRUE if last item
    private func setupUserAtIndex(_ idx:Int )  {
        
        // assert(countRunnable() == 0, "setupUserAtIndex should have no running task  on exit")
        // the ig api infrastructure expects these to be set up
        let item = usersOnDisk.users[idx]
        Persistence.igToken =  item.token
        Persistence.igUserID =  item.id
        //
        
        let furl = modelDirURL!.appendingPathComponent(item.id, isDirectory: true).appendingPathComponent("model").appendingPathExtension("json")
        
        do {
            let data = try Data(contentsOf: furl)
            model = try  Config.jsonDecoder.decode(InstagrammModel.self, from: data)
            dbgprint("  - \(item.id) cycle start  \(item.name) by reloading  \(idx):\(usersOnDisk.users.count) ")
        }
        catch {
            // if cant find model, make new
            let user = usersOnDisk.users[idx]
            print ("creating new model because couldnt find modelforuser   modelDirURL: \(furl)")
            model = InstagrammModel() // start clean
            let succ =    InstagrammModel.verifyThenSave (model,tag:  user.id )
            if !succ {
                dbgprint("completed \(succ ? "pass":"fail") exportVerifiedModel Model-\( user.id) in \(Date().timeIntervalSince(cyclestarttime))secs")
            }
        }//catch
        thisUserTask = self.perUserTasks[idx]
        
        //restore counters
        //globalBuckets = thisUser.apiBuckets
        //self.model.globalBuckets =   thisUser.apiBuckets
    } // setupuseratindex
    
    
    
    init?( tag:String,
           cycleTime:Int,
           usersFileURL:  URL?,
           modelDirURL: URL?,
           sqlDirURL:  URL?,
           exportDirURL: URL?,
           finalcomphandler: @escaping UseridStatusCompletionHandler) {
        self.context = tag
        // self.funcs = funcs
        self.usersFileURL =  usersFileURL
        self.modelDirURL = modelDirURL
        self.sqlDirURL = sqlDirURL
        self.exportDirURL = exportDirURL
        self.baseCycleTime = cycleTime
        self.finalcomphandler = finalcomphandler
        
        do {
            let ufu = try Data.init(contentsOf:usersFileURL!)
            self.usersOnDisk = try Config.jsonDecoder.decode(UsersOnDiskModel.self, from: ufu)
            //self.scratchmem = NonPersistentObjs(count:self.usersOnDisk.users.count)
        }
        catch {
            print ("couldnt setup InstagramPoller check usersFileURL: \(usersFileURL!)")
            return nil
        }
        do {
            // setup tasks array
            for user in usersOnDisk.users {
                perUserTasks.append(PerUserInfo(userid: user.id))
            }
            // move to furst user
            thisUserTask =  perUserTasks.last!
            currentUserIndex = usersOnDisk.users.count - 1
        }
    }
    func apiCountUp () {
        thisUserTask.countApi()
    }
    
    private func scanforNextUserTask ( ) -> PerUserInfo? {
        ///we dont really need to scan, the item at current index is what we are working on
        /// right now, there should always be at most one runnable task
        
        if thisUserTask.isBusy()   {return nil} // do nothing if Im busy
        
        // if im not busy step forward
         currentUserIndex = ( currentUserIndex + 1) % usersOnDisk.users.count   // go round in circle between all users
        
        thisUserTask =  perUserTasks[ currentUserIndex]
        uid = thisUserTask.userid
        if thisUserTask.isIdle()  || thisUserTask.isReady()  {
            // poked for a fresh start in here
            
            setupUserAtIndex( currentUserIndex)
            thisUserTask.makeBusy(step: 0)
            
            return thisUserTask
        } else
        {
            fatalError("bad rindex value")
        }
        return nil
    }// end scanTaskTable
    
    func perpetualCycle(apiCycle: APICycle, repeating:@escaping TaggedStatusRepeatingFunc) {
        DispatchQueue.global().async {
     
        self.apiCycle = apiCycle // remeber
        
        self.currentUserIndex = -1 // start with first user IMP
        if !self.isRunning {
            // note: at first, nothing is setup so cant get to model.user.id
            // once only
            self.isRunning = true
            self.cnt.cycleSecsDowncounter = 0 // START NOW
            
            self.timer?.cancel()        // cancel previous timer if any
            self.timer = DispatchSource.makeTimerSource(queue: self.timerqueue)
            self.timer?.schedule(deadline: .now(), repeating: .seconds(1))
            //self.timer?.schedule(deadline: .now() , repeating: .seconds(1) )
            self.timer?.setEventHandler { //[weak self] in
                
                /// here each second
                
                /// incidiental functions periopdically
                self.cnt.secsPerpetualUpCounter += 1
                if self.cnt.secsPerpetualUpCounter % 10 == 0 {
                    // every second
                    // dbgprint(sec % 60 == 0 ? "!" : "-",  terminator:"" )
                }
                if self.cnt.secsPerpetualUpCounter % 120 == 0 {
                    // every few minutes
                    //globalBuckets.dumpbuckets()
                }
                ////
                self.cnt.cycleSecsDowncounter -= 1
                if self.cnt.cycleSecsDowncounter < 0 {
                    // reset counter
                    self.cnt.cycleSecsDowncounter = self.baseCycleTime - 1
                    //// here every cycle secs
                    self.cnt.apiCountThisCycle =  globalBuckets.totalcount
                    self.cnt.pollcount += 1
                    // figure out what to do, and if anything
                    
                    let task = self.scanforNextUserTask ()
                    if let _ = task {
                        self.cyclestarttime = Date()
                            // dbgprint("***** 1.1 - \(thisuser) about to executeFullCycleForOneUser \(ix)")
                            apiCycle.main!() { uid, status in
                          
                                self.model.lastApiStatus = status
                                if status == 200 {
                                    // keep track of whenever we complete successfully
                                    self.model.cyclelastcompleted = Date()
                                }
                                dbgprint("***** 1.2 - \(uid) finshed  functocall   status \(status)")
                                repeating (uid,status)
                            }
                    }
                    // reset counter
                    //dont reset self.cnt.cycleSecsDowncounter = self.baseCycleTime
                }
            }
            self.timer?.resume()
        } // never inited
        else {
            // already running in background, so just print
            print ("CALLING runStandardcycle more than once!!!")
        }
        }
    }
 }
