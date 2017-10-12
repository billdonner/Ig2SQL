
#ig4sql

* ig4sql  export -dModelPath -xExportTopFolderPath // no db needed, generates mysql import file

* ig4sql  create [-force] // makes tables, if -force then drops them first

* ig4sql  poller  -dModelTopFolderPath -uUserCredsFilePath  [-c=600] [ -insert=1] // default is to insert records repeatedly

* ig4sql  once  -dModelTopFolderPath  -uUserCredsFilePath [ -insert=1] // default is to insert records repeatedly

* ig4sql status


