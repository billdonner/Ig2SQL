//
//  Persistence.swift
//  igjs
//
//  Created by william donner on 7/14/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation
/// keeps small persistent values in NSUserDefaults

class Persistence {
    
    private struct Config {
        //these values reflect the currently logged on user
        static let igToken = "igTokenKey"
        static let igUserID = "igUserIDKey"
        
        //these values are stored uniquely for each separate user of the app
       // static let lastPollTime = "lastPollTimeKey\(Config.igUserID)"
       // static let pollCount = "pollCountKey\(Config.igUserID)"
    }
    /// authtoken is persisted so we dont have to login
    class var igToken : String? {
        get {return UserDefaults.standard.string(forKey:Config.igToken)}
        set {UserDefaults.standard.setValue(newValue, forKey:Config.igToken)}
    }
    class var igUserID : String {
        get {return UserDefaults.standard.string(forKey:Config.igUserID) ?? "invalidUserID"}
        set {UserDefaults.standard.setValue(newValue, forKey:Config.igUserID)}
    }
    
//    class var lastPollTime: String? {
//        get {return UserDefaults.standard.string(forKey:Config.lastPollTime)}
//        set {UserDefaults.standard.setValue(newValue, forKey:Config.lastPollTime)}
//    }
//    class var pollCount: String? {
//        get {return UserDefaults.standard.string(forKey:Config.pollCount)}
//        set {UserDefaults.standard.setValue(newValue, forKey:Config.pollCount)}
//    }
    
    
}// persistence class
