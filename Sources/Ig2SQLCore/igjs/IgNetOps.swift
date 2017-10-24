//
//  IgNetOps.swift
//  igr
//
//  Created by william donner on 7/10/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//
import Foundation



typealias URLParamsToEncode = [String: AnyObject]

typealias NetCompletionFunc = (_ status: Int, _ object: Data?) -> ()

struct SmaxxUser : Codable {
    let igtoken:String
     let iguserid:String
     let name:String
     let pic:String
    let smaxxtoken:String
}

struct SmaxxResponse: Codable {
    let status: Int
    let igid: String
    let pic:String
    let smaxxtoken: Int
    let name:String
}

struct LoginResponse:Codable {
    let userid:String
    let reportname:String
    let elapsed:TimeInterval
    let queryParameters:[String:String]
    let reportHeaders: [ String]
    let reportData: [[String]]
}
struct LoginResponseWrapped:Codable {
    let status: Int
    let time: Date
    let response: LoginResponse
}
struct ReportResponse:Codable {
    let userid:String
    let reportname:String
    let elapsed:TimeInterval
    let queryParameters:[String:String]
    let reportHeaders: [String]
    let reportData: [[String]]
}
struct ReportResponseWrapped:Codable {
    let status: Int
    let time: Date
    let response: ReportResponse
}
struct IGNetOps {


    // not public

    
    static var session: URLSession = URLSession(configuration: URLSessionConfiguration.default) // just one session
    
    static func dataTask(_ request: NSMutableURLRequest, method: String, completion: @escaping NetCompletionFunc) {
        request.httpMethod = method
        session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error)  in
            if let rul = request.url?.path,
                let response = response as? HTTPURLResponse {
                let responsecode = response.statusCode
                if let lim = response.allHeaderFields["x-ratelimit-limit"] as? String,
                let remains = response.allHeaderFields["x-ratelimit-remaining"] as? String {
                    let ratelimit = Int(lim) ?? 0
                    let rateremain = Int(remains) ?? 0
                    globalData.bkts.xrated(limit: ratelimit, remaining: rateremain, apistatus: response.statusCode)
              
                    NSLog("-\(Persistence.igUserID) dataTask \(responsecode) \(method) \(String(describing: rul)) hdrs \(ratelimit):\(rateremain)")
                } else {
                    NSLog("-\(Persistence.igUserID) dataTask \(responsecode) \(method) \(String(describing: rul)) no rate hdrs")
                }
                if 200...299 ~= response.statusCode {
                     completion(responsecode, data)
                    }  else {
                     completion(responsecode, nil)
                       }
                } 
        }) .resume()
    }

    static func post(_ request: NSMutableURLRequest, completion:@escaping NetCompletionFunc) {
        dataTask(request, method: "POST", completion: completion)
    }
    
    static func put(_ request: NSMutableURLRequest, completion:@escaping NetCompletionFunc) {
        dataTask(request, method: "PUT", completion: completion)
    }
    
    static func get(_ request: NSMutableURLRequest, completion:@escaping NetCompletionFunc) {
        dataTask(request, method: "GET", completion: completion)
    }
    
   
} // IgNetOps


