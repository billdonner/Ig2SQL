# Ig2SQL

### cli commands
* Ig2SQL  export  -dModelPath -xExportTopFolderPath // no db needed, generates mysql import file
* Ig2SQL  create  // makes tables,unless they already exists
* Ig2SQL  force   // makes tables, drops them first
* Ig2SQL  poller  -dModelTopFolderPath -uUserCredsFilePath  [-c=600] [ -insert=1] // default is to insert records
* Ig2SQL  once    -dModelTopFolderPath  -uUserCredsFilePath [ -insert=1] // default is to insert records repeatedly
* Ig2SQL  status
* Ig2SQL  report   -iUIDfor -rNameofReport
* Ig2SQL  reportsrv // kitura starts on 8090
* Ig2SQL  loginsrv // kitura starts on 8080

### remote access to login server
* http://localhost:8080/login[?smtoken=xxx]
if a valid token is supplied you can access instagramm apis (e.g.reports)
Otherwise, you are presented with an Instragramm login screen
* http://localhost:8080/logout?smtoken=xxx
log the user out of instagramm

### remote access to reports server
* http://localhost:8090/report/:id/:name/?smtoken=xxx
supply the instagramm userID and the token returned by login
