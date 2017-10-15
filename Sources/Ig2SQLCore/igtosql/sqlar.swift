//
//  sqlar.swift
//  igloginsolo
//
//  Created by william donner on 9/11/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation

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
    
    let con = MySQL.Connection()
    
public func openigbase() throws {
    // open a new connection
    try  con.open("localhost", user: "root", passwd: "")
    try  conuse(Config.dbname)
}
public func createigbase() throws {
    // open a new connection
    try openigbase()
    createallTables()
}
public func conuse(_ s:String) throws {
    //print("u:" + s)
    try con.use(s)
}
public func conexec(_ s:String) throws {
    //print("x:" + s)
    try con.exec(s)
}
public func conprepare(_ s:String) throws -> MySQL.Statement {
    //print("p:" + s)
    return try con.prepare(s)
}
public func freshdb(_ db_name:String) throws {
    // create a new database for tests, use exec since we don't expect any results
    try conexec("DROP DATABASE IF EXISTS " + db_name)
    try conexec("CREATE DATABASE IF NOT EXISTS " + db_name)
    print("----------FRESHDB----\(db_name)-----------------------")
    // select the database
    try conuse(db_name)
}
public func opendb(_ db_name:String) throws {
    print("----------OPENDB----\(db_name)-----------------------")
    // select the database
    try conuse(db_name)
}
private func createtable(_ table:String) throws {
    //print("create \(table)")
    if let s = BitsOfMySQL.eachrow[table]?.0 {
        //print(s)
        try conexec(s)
        
    }
}
private func insertinto(_ table:String,args:[Any]) throws {
    if let s = BitsOfMySQL.eachrow[table]?.1 {
        let a = try conprepare(s)
        //print("a:" + "\(s)")
        try a.exec(args) 
       // assert ( con.affectedRows == 1)
    }
}
public func printcounts(_ table:String,args:[Any]) throws {
    
    try iselectfrom("select count(*)from \(table)", args: args) { row in
        let r = row[0]
        let (_,t) = r.first!
        print ("\(table) - \(t)")
    }
}

public func iselectfrom(_  s:String,args:[Any],each:(MySQL.ResultSet)->()) throws {
    
        let a = try con.prepare(s)
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
func createallTables() {
    BitsOfMySQL.eachrow.forEach({ (table,_) in
        do {
            try createtable(table)
        }
        catch{
            print("Could not create table \(table)")
        }
    })
}
func likesdatablocksInsert(mediaid  a:String, filter b:String, type c:String,link d:String,countcomments  e:Int, countlikes f:Int,user_has_liked g:Int,  caption_text h:String,caption_created_time i:String,caption_id j:String,caption_from_id k:String,location_id l:UInt64,iguserid m:String,created_time n:String) {
    
    let args:[Any] = [a,b,c,d,e,f,g,h,i,j,k,l,m,n ]
    do {
        
        try insertinto("likesdatablocks",args:args)
    }
    catch {
        print("likesdatablocksInsert w args \(args) failed \(error)")
    }
}

func mediadatablocksInsert(mediaid  a:String, filter b:String, type c:String,link d:String,countcomments  e:Int, countlikes f:Int,user_has_liked g:Int,  caption_text h:String,caption_created_time i:String,caption_id j:String,caption_from_id k:String,location_id l:UInt64,iguserid m:String,created_time n:String) {
    
    let args:[Any] = [a,b,c,d,e,f,g,h,i,j,k,l,m,n ]
    do {
        
        try insertinto("mediadatablocks",args:args)
    }
    catch {
        print("mediadatablocksInsert w args \(args) failed \(error)")
    }
}

func likersofmediaInsert(mediaid a:String,userid b:String,iguserid c:String) {
    
    let args:[Any] = [a,b,c ]
    do {
        
        try insertinto("likersofmedia",args:args)
    }
    catch {
        print("likersofmediaInsert w args \(args) failed \(error)")
    }
}
func commentsofmediaInsert(mediaid a:String,comment b:String,userid c:String, created_time d :String, iguserid e:String) {
    let args:[Any] = [a,b,c,d,e]
    do {
        try insertinto("commentsofmedia",args:args)
    }
    catch {
        print("commentsofmediaInsert w args \(args) failed \(error)")
    }
}
func mediaTaggedInsert(mediaid a:String,tag b:String,iguserid c:String) {
    
    let args:[Any] = [a,b,c ]
    do {
        try insertinto("mediatagged",args:args)
    }
    catch {
        print("mediaTaggedInsert w args \(args) failed \(error)")
    }
}
func mediaVideosInsert(mediaid a:String,url b:String,width c:Int,height d:Int,iguserid e:String) {
    
    let args:[Any] = [a,b,c,d,e]
    do {
        try insertinto("mediavideos",args:args)
    }
    catch {
        print("mediavideosInsert w args \(args) failed \(error)")
    }
}
func mediaImagesInsert(mediaid a:String,url b:String,width c:Int,height d:Int,iguserid e:String) {
    
    let args:[Any] = [a,b,c,d,e]
    do {
              try insertinto("mediaimages",args:args)
    }
    catch {
        print("mediaimagesInsert w args \(args) failed \(error)")
    }
}
func userpositionInsert(mediaid a:String,userid b:String,x c:Float,y d:Float,iguserid e:String) {
    
    let args : [Any] = [a,b,c,d,e]
    do {
              try insertinto("userposition",args:args)
    }
    catch {
        print("userpositionInsert w args \(args) failed \(error)")
    }
}
func userblocksInsert(userid a:String,username b:String,full_name c:String,profile_picture d:String,iguserid e:String) {
    
    let args = [a,b,c,d,e]
    do {
        try insertinto("userblocks",args:args)
    }
    catch {
        print("userblocksInsert w args \(args) failed \(error)")
    }
}
func iguserInsert(bio a:String,username b:String,full_name c:String,profile_picture d:String,website  e:String, iguserid f:String) {
    
    let args = [a,b,c,d,e,f]
    do {
        try insertinto("iguser",args:args)
    }
    catch {
        print("iguserInsert w args \(args) failed \(error)")
    }
}
func followingblocksInsert(userid a:String,iguserid b:String) {
    
    let args = [a,b ]
    do {
        try insertinto("followingblocks",args:args)
    }
    catch {
        print("followingblocksInsert w args \(args) failed \(error)")
    }
}
func followerblocksInsert(userid a:String,iguserid b:String) {
    
    let args = [a,b ]
    do {
        try insertinto("followerblocks",args:args)
    }
    catch {
        print("followerblocksInsert w args \(args) failed \(error)")
    }
}
func requestedbyblocksInsert(userid a:String,iguserid b:String) {
    
    let args = [a,b ]
    do {
        try insertinto("requestedbyblocks",args:args)
    }
    catch {
        print("requestedbyblocksInsert w args \(args) failed \(error)")
    }
}

}// end ZH

