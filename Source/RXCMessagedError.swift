//
//  RXCMessagedError.swift
//  CoolMarket
//
//  Created by ruixingchen on 9/18/19.
//  Copyright © 2019 CoolApk. All rights reserved.
//

import Foundation

///一个可以容纳一些字符串信息的Error对象
struct RXCMessagedError: Error, LocalizedError, CustomStringConvertible, CustomDebugStringConvertible {

    var message: String
    var debugMessage: String?
    var userInfo:[AnyHashable:Any]?

    var errorDescription: String? {return self.message}
    var description: String {return self.message}

    var debugDescription: String {
        return self.message + (self.debugMessage ?? "") + (self.userInfo?.description ?? "")
    }

    init(message:String) {
        self.message = message
    }

    init(message:String, debugMessage:String?) {
        self.message = message
        self.debugMessage = debugMessage
    }

}
