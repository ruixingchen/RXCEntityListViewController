//
//  ApiRequestResultV2.swift
//  CoolMarket
//
//  Created by ruixingchen on 9/19/19.
//  Copyright © 2019 CoolApk. All rights reserved.
//

import Foundation

///请求结果封装
public struct ApiRequestResultV2<T> {
    public var error: ApiRequestErrorV2?
    public var data:T?
    ///服务器返回的原始请求，一般是Alamofire的Response对象
    public var originResponse:AnyObject?

    public init(error:ApiRequestErrorV2) {
        self.error = error
    }

    public init(data:T) {
        self.data = data
        self.error = nil
    }

    public func isSuccess()->Bool {
        return self.data != nil
    }

    var result:Swift.Result<T, ApiRequestErrorV2> {
        if self.isSuccess() {
            return Result.success(self.data!)
        }else {
            return Result.failure(self.error!)
        }
    }

}
