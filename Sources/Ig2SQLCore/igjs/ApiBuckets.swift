//
//  ApiBuckets.swift
//  sql4ig
//
//  Created by william donner on 8/24/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation



// there is one APICounters Struct for each user in the Items.users array
struct NonPersistentObjs {
    var backoffs:[Int]
    init(count:Int) {
      backoffs = []
        for  _ in 0..<count { backoffs.append(0) }
    }
}

struct APIBuckets : Codable {
    var totalcount : Int = 0
    var countPerMinute = [Int] (repeating: 0, count: 60)
    var lastwritten : Int = -1
    var ratelimit : Int = 0
    var remaining : Int = 0
    var lastapistatus : Int = 0
    
    mutating func xrated(limit: Int,remaining: Int ,apistatus: Int) {
        self.lastapistatus =  apistatus
        self.remaining = remaining
        self.ratelimit = limit
    }
    
    func dumpbuckets() {
        let date = Date()
        let minute = Calendar.current.component(.minute, from: date) // get bkt
        
        func within (index a:Int,before b:Int) -> Bool {
            if minute + a < b {
                return true
            }
            return false
        }
        var s5=0,s15=0,s60=0
//        0...........................59
//           |                               minute=3
//        xxx|                        xx     s5
//        xxx|                  xxxxxxxx     s15
//                 |                         minute=10
//            xxxxx|                         s5
//         xxxxxxxx|                 xxx     s15
        
        for idx in 0..<minute {
            if   idx > minute-5 { s5 +=  countPerMinute [idx] }
            if   idx > minute-15 { s15 += countPerMinute [idx] }
            if   idx > minute-60 { s60 += countPerMinute [idx] }
        }
        for idx in minute..<60 {
            if  idx > 60-5 { s5 += countPerMinute [idx] }
            if  idx > 60-15  { s15 += countPerMinute [idx] }
            if  idx > 60-60 { s60 += countPerMinute [idx] }
        }
        
        
        
        let countall = countPerMinute.reduce(0,{ $0 + $1} )
        NSLog("-\(Persistence.igUserID) apiops:\(totalcount) last 5min:\(s5) 15min:\(s15) 60min:\(s60) hr:\(countall)")
    }
    func sumbkts(from a:Int,to b:Int)  -> Int {
        /*
         from == A
         to == B
         
         case A < B // in this case clean between A+1 and B then add in
         
         case A == B  // same bucket, just add in to bucketA
         
         case A > B  // in this case clean between A+1 and 60, then 0 upto B
         
         */
        var sum = 0
        if a < b  {
            for idx in a+1 ..< b {
                sum += countPerMinute[idx]
            }
        } else if a > b {
            for idx in a+1 ..< 60 {
                sum += countPerMinute[idx]
            }
            for idx in 0 ..< b {
                sum +=  countPerMinute[idx]
            }
            
        } else {
            
            //==
            sum +=  countPerMinute[a]
        }
        return sum
        
    }
    
    mutating func cleanbkts(from a:Int,to b:Int) {
        /*
         from == A
         to == B
         
         case A < B // in this case clean between A+1 and B then add in
         
         case A == B  // same bucket, just add in to bucketA
         
         case A > B  // in this case clean between A+1 and 60, then 0 upto B
         
         */
        if a < b  {
            for idx in a+1 ..< b {
                countPerMinute[idx] = 0
            }
        } else if a > b {
            for idx in a+1 ..< 60 {
                countPerMinute[idx] = 0
            }
            for idx in 0 ..< b {
                countPerMinute[idx] = 0
            }
            
        } else {
            
            //==
        }
        
        
    }
    mutating func apicount(_ count:Int=1) {
        let date = Date()
        let minute = Calendar.current.component(.minute, from: date) // get bkt
        
        cleanbkts(from:lastwritten,to:minute)
        // now update
        
        lastwritten = minute
        countPerMinute[minute] += count
        totalcount += count
    
    }
}



