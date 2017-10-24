//
//  sqlar.swift
//  igloginsolo
//
//  Created by william donner on 9/11/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation

enum SMaxxResponseCode: Int {
    case success = 200
    case workerNotActive = 538
    case duplicate = 539
    case badMemberID = 533
    case noData = 541
    case waiting = 542
    case noToken = 545
}
public struct BitsOfMySQL {
    
    /*"proto":(
     """
     create
     """,
     "select * from proto ",
     "INSERT INTO proto (a,b) VALUES(?,?)"
     ),*/
    static let eachrow:[String:(String,String)] =
        [
            
            "smaxxmodels": (
                """
CREATE TABLE smaxxmodels (
iguserid   VARCHAR (255),
created_time   VARCHAR (255),
jsonblob   TEXT,
 INDEX modelid (iguserid,created_time)
);
""","INSERT INTO smaxxmodels ( iguserid,created_time,jsonblob ) VALUES(?,?,?)"
            
            ),
            "smaxxusers":(
                """
CREATE TABLE smaxxusers (
igtoken   VARCHAR (255),
iguserid   VARCHAR (255),
name   VARCHAR (255),
pic   VARCHAR (255),
smaxxtoken INT PRIMARY KEY
);
""",
                "INSERT INTO smaxxusers (igtoken,iguserid,name,pic,smaxxtoken ) VALUES(?,?,?,?,?)"
            ),
            
            "mediadatablocks":(
                """
CREATE TABLE mediadatablocks
  (
     mediaid              VARCHAR (255) PRIMARY KEY,
     filter               VARCHAR (255),
     type                 VARCHAR (255),
     link                 VARCHAR (255),
     countcomments        INT,
     countlikes           INT,
     user_has_liked       TINYINT, 
     caption_text         VARCHAR(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
     caption_created_time VARCHAR (255),
     caption_id           VARCHAR (255),
     caption_from_id      VARCHAR (255),
     location_id          INT,
     iguserid             VARCHAR (255),
     created_time           INT
  ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
""",
                "INSERT INTO mediadatablocks (mediaid,filter,type,link,countcomments,countlikes,user_has_liked,caption_text,caption_created_time,caption_id,caption_from_id,location_id,iguserid,created_time) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
            ),
            
            "likesdatablocks":(
                """
CREATE TABLE likesdatablocks
  (
     mediaid              VARCHAR (255) PRIMARY KEY,
     filter               VARCHAR (255),
     type                 VARCHAR (255),
     link                 VARCHAR (255),
     countcomments        INT,
     countlikes           INT,
     user_has_liked       TINYINT,
     caption_text         VARCHAR(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
     caption_created_time VARCHAR (255),
     caption_id           VARCHAR (255),
     caption_from_id      VARCHAR (255),
     location_id          INT,
     iguserid             VARCHAR (255),
     created_time           INT
  ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
""",
                "INSERT INTO likesdatablocks (mediaid,filter,type,link,countcomments,countlikes,user_has_liked,caption_text,caption_created_time,caption_id,caption_from_id,location_id,iguserid,created_time) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)"
            ),
            
            
            "likersofmedia":(
                """
CREATE TABLE likersofmedia
  (
     mediaid  VARCHAR (255),
     userid   VARCHAR(255),
     iguserid VARCHAR (255)
  );
""",
                "INSERT INTO likersofmedia (mediaid, userid, iguserid) VALUES(?,?,?)"
            ),
            
            
            
            "commentsofmedia":(
                """
  CREATE TABLE commentsofmedia
  (
     mediaid  VARCHAR (255),
     comment VARCHAR(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
     userid   VARCHAR(255),
     created_time VARCHAR(255),
     iguserid VARCHAR (255)
  ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
""",
                "INSERT INTO commentsofmedia (mediaid,comment,userid,created_time,iguserid) VALUES(?,?,?,?,?)"
            ),
            
            "mediatagged":(
                """
     CREATE TABLE mediatagged
  (
     mediaid  VARCHAR (255),
     tag      VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
     iguserid VARCHAR (255)
  ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
""",
                "INSERT INTO mediatagged (mediaid,tag,iguserid) VALUES(?,?,?)"
            ),
            
            "mediaimages":(
                
                """
  CREATE TABLE mediaimages
   (
     mediaid  VARCHAR (255)  PRIMARY KEY,
     userid          VARCHAR(255) ,
     url      VARCHAR(255),
     width    INT,
     height   INT,
     iguserid VARCHAR (255)
  );
""",
                "INSERT INTO mediaimages    (mediaid,url,width,height,iguserid) VALUES(?,?,?,?,?)"
            ),
            
            "mediavideos":(
                
                """
  CREATE TABLE mediavideos
   (
     mediaid  VARCHAR (255) PRIMARY KEY,
     url      VARCHAR(255),
     width    INT,
     height   INT,
     iguserid VARCHAR (255)
  );
""",
                "INSERT INTO mediavideos    (mediaid,url,width,height,iguserid) VALUES(?,?,?,?,?)"
            ),
            
            "requestedbyblocks":(
                
                """
CREATE TABLE requestedbyblocks(
                userid   VARCHAR(255),
                iguserid VARCHAR (255)
            );
""",
                """
INSERT INTO requestedbyblocks (userid,iguserid) VALUES(?,?)
"""),
            "userposition":(
                
                """
CREATE TABLE userposition (
     mediaid  VARCHAR (255),
     userid   VARCHAR(255),
     x        FLOAT,
     y        FLOAT,
     iguserid VARCHAR (255)
  );
""",
                "INSERT INTO userposition (mediaid,userid,x,y,iguserid) VALUES(?,?,?,?,?)"
            ),
            
            "iguser":(
                
                """
CREATE TABLE iguser  (
     bio             VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
     username        VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
     full_name       VARCHAR(255),
     profile_picture VARCHAR(255),
     website         VARCHAR(255),
     iguserid        VARCHAR (255) PRIMARY KEY
  ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
""",
                "INSERT INTO iguser (bio,username,full_name,profile_picture,website,iguserid) VALUES(?,?,?,?,?,?)"
            ),
            
            "userblocks":(
                
                """
CREATE TABLE userblocks (
     userid          VARCHAR(255) PRIMARY KEY,
     username        VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
     full_name       VARCHAR(255),
     profile_picture VARCHAR(255),
     iguserid        VARCHAR (255)
  ) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
""",
                "INSERT INTO userblocks (userid,username,full_name,profile_picture,iguserid) VALUES(?,?,?,?,?)"
            ),
            
            
            "followerblocks":(
                
                """
CREATE TABLE followerblocks(
                userid   VARCHAR(255),
                iguserid VARCHAR (255)
            );
""",
                """
INSERT INTO followerblocks (userid,iguserid) VALUES(?,?)
""")  ,
            
            "followingblocks": (
                
                """
CREATE TABLE followingblocks(
                userid   VARCHAR(255),
                iguserid VARCHAR (255)
            );
"""   ,       
                """
INSERT INTO followingblocks (userid,iguserid) VALUES(?,?)
""")
            
    ]
}
fileprivate func dump () {
    print("-----------------------------------------")
    BitsOfMySQL.eachrow.forEach { key,val in
        // let (create,_,_) = val
        print(val.0)
    }
    BitsOfMySQL.eachrow.forEach {
        // let (_,select,_) = val
        print($1.1)
    }
    BitsOfMySQL.eachrow.forEach { key,val in
        let (_,insert) = val
        print(insert)
    }
    
    print("-------------------------------------------")
}


public struct ZH {
    
    static let con = MySQL.Connection()
    
    public static func openigbase() throws {
        // open a new connection
        try  ZH.con.open("localhost", user: "root", passwd: "")
        try  conuse(Config.dbname)
    }
    public  static func createigbase() throws {
        // open a new connection
        try openigbase()
        createallTables()
    }
    public  static func conuse(_ s:String) throws {
        //print("u:" + s)
        try ZH.con.use(s)
    }
    public  static func conexec(_ s:String) throws {
        //print("x:" + s)
        try ZH.con.exec(s)
    }
    public  static func conprepare(_ s:String) throws -> MySQL.Statement {
        //print("p:" + s)
        return try ZH.con.prepare(s)
    }
    public  static func freshdb(_ db_name:String) throws {
        // create a new database for tests, use exec since we don't expect any results
        try conexec("DROP DATABASE IF EXISTS " + db_name)
        try conexec("CREATE DATABASE IF NOT EXISTS " + db_name)
        print("----------FRESHDB----\(db_name)-----------------------")
        // select the database
        try conuse(db_name)
    }
    public  static func opendb(_ db_name:String) throws {
        print("----------OPENDB----\(db_name)-----------------------")
        // select the database
        try conuse(db_name)
    }
    private  static func createtable(_ table:String) throws {
        //print("create \(table)")
        if let s = BitsOfMySQL.eachrow[table]?.0 {
            //print(s)
            try conexec(s)
            
        }
    }
    public  static func insertinto(_ table:String,args:[Any]) throws {
        if let s = BitsOfMySQL.eachrow[table]?.1 {
            let a = try conprepare(s)
            //print("a:" + "\(s)")
            try a.exec(args)
            // assert ( con.affectedRows == 1)
        }
    }
    public  static func deletefrom(_ table:String,key:Any,val:Any) -> Bool {
        let s = "delete from \(table) where \(key) = '\(val)'"
        do {
            let a = try ZH.con.prepare(s)
            let _ = try a.query( [] )
        }
        catch {
            return false
        }
        return true
    }
    

    
    public  static func iselectfrom(_  s:String,args:[Any],each:(MySQL.ResultSet)->()) throws {
        
        let a = try ZH.con.prepare(s)
        do {
            // send query
            let res = try a.query( args )
            //read all rows from the resultset
            if let rows = try res.readAllRows() {
                // print the rows
                if rows.count == 0    {
                    print("<<<<<<<< no rows in table  >>>>>>>>")
                } else {
                    for row in rows {
                        each(row)
                    }
                }
            }
        }//do
        catch (let err) {
            // if we get a error print it out
            print(err)
        }
        // }
    }
    enum CredentialsError: Error {
        case smaxxnotfound
    }


     static func createallTables() {
        BitsOfMySQL.eachrow.forEach({ (table,_) in
            do {
                try createtable(table)
            }
            catch{
                print("Could not create table \(table)")
            }
        })
    }
    
    
}// end ZH

