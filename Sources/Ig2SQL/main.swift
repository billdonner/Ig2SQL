//
//  main.swift
//  igpolling
//
//  Created by william donner on 8/19/17.
//  Copyright © 2017 midnightrambler. All rights reserved.
//

import Foundation
import Ig2SQLCore



////// main here //////////

NSLog("\(CommandLine.arguments)")
if let tt = CommandHandler.processargs( argv: CommandLine.arguments) {
    cliMain( tt)
    sleep(60*60*24*7) // let background stuff happen for up to one week:)
}

