//
//  ApiRequestErrorV2.swift
//  CoolMarket
//
//  Created by ruixingchen on 9/19/19.
//  Copyright © 2019 CoolApk. All rights reserved.
//

import Foundation

///服务器传来的错误码错误
public struct ApiServerStatusError: CustomDebugStringConvertible {

    public struct Key {
        static var status:String {return "status"}
        static var message:String {return "message"}
        static var forwardUrl:String {return "forwardUrl"}
        static var messageStatus:String {return "messageStatus"}
        static var messageExtra:String {return "messageExtra"}
    }

    public var status:Int
    public var message:String?
    public var forwardUrl:String?
    public var messageStatus:String?
    public var messageExtra:String?

    public init(status:Int, message:String?) {
        self.status = status
        self.message = message
    }

    public var debugDescription: String {
        return "code:\(status), message:\(message ?? "nil"), forwardUrl:\(forwardUrl ?? "nil")"
    }

}

public enum ApiRequestErrorV2: Error, LocalizedError, CustomDebugStringConvertible, CustomStringConvertible {

    case cancelled
    ///请求没有成功
    case requestFailed(Error, [AnyHashable:Any]?)
    ///由于服务器问题，当请求成功但是没有数据的时候，我们需要特殊处理一下这个问题，单独为这个问题设置一个枚举
    case responseNoData([AnyHashable:Any]?)
    ///请求成功了但是数据解析失败
    case serializingFailed(Error, [AnyHashable:Any]?)
    ///服务器传来了错误码
    case serverStatusError(ApiServerStatusError, [AnyHashable:Any]?)
    ///未知错误
    case unknown(Error?, [AnyHashable:Any]?)

    ///返回一个文案友好的描述，可以直接用来作为显示的文案
    public var description: String {
        switch self {
        case .cancelled: return "请求被取消，请重试"
        case .requestFailed(_, _): return "请求失败，请重试"
        case .responseNoData(_): return "请求失败，请重试"
        case .serializingFailed(_, _): return "数据解析失败，请重试"
        case .serverStatusError(let error, _): return error.message ?? "暂不能处理你的请求，请稍后再试"
        case .unknown(let error, _): return error?.localizedDescription ?? "请求失败：未知错误"
        }
    }

    public var debugDescription: String {
        switch self {
        case .cancelled: return "请求被取消"
        case .requestFailed(let error, _): return "请求失败：" + error.localizedDescription
        case .responseNoData(_): return "服务器没有传Data"
        case .serializingFailed(let error, _): return "数据解析失败：" + error.localizedDescription
        case .serverStatusError(let error, _): return "statusCode错误：" + error.debugDescription
        case .unknown(let error, _): return error?.localizedDescription ?? "未知错误"
        }
    }

    public var localizedDescription: String {
        return self.description
    }

}
