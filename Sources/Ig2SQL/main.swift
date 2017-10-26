//
//  Created by william donner on 8/19/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation
import Ig2SQLCore

/**
 
 8070 - adminserver
 8080 - loginserver
 8090 - reportserver
 
 socialmaxx.xyz  -  96.250.76.158:9070 =>  192.168.2.2:8070
 socialmaxx.net  -  96.250.76.158:9080 =>  192.168.2.2:8080
 socialmaxx.info -  96.250.76.158:9090 =>  192.168.2.2:8090
 
*/

////// main here //////////

if let tt = CommandHandler.processargs( argv: CommandLine.arguments) {
    cliMain( tt)
    sleep(60*60*24*7) // let background stuff happen for up to one week:)
}

