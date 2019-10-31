//
//  APIServiceV2.swift
//  CoolMarket
//
//  Created by ruixingchen on 9/17/19.
//  Copyright © 2019 CoolApk. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

///新的请求系统
public struct APIServiceV2 {

    static let shared = APIServiceV2()

    let sessionManager = Alamofire.SessionManager.default

    ///验证服务器传来的JSON的状态码的正确性，如果出错，返回错误对象
    public static func validateJSONStatusCode(json:SwiftyJSON.JSON)->ApiServerStatusError? {
        let status = json["status"].castInt ?? 1
        //根据亮哥所说，这里其实只要有status就可以认为是出错
        if status != 1 {
            let message:String? = json["message"].string
            let forwardUrl:String? = json["forwardUrl"].string
            let messageStatus = json["messageStatus"].string
            let messageExtra = json["messageExtra"].string
            var error = ApiServerStatusError(status: status, message: message)
            error.forwardUrl = forwardUrl
            error.messageStatus = messageStatus
            error.messageExtra = messageExtra
            return error
        }else {
            return nil
        }
    }

    ///不带表单数据的请求
    private func plainRequestWithoutMultipartForm(requestSpec:ApiRequestSpecV2, completion:@escaping ((Alamofire.DefaultDataResponse)->Void))->Alamofire.Request {
        let url = requestSpec.url
        let method = requestSpec.method.alamofireHTTPMethod
        let headers = requestSpec.headers
        let queue = requestSpec.parsingQueue

        let request:Alamofire.Request
        if let data = requestSpec.body, method == .post {
            request = sessionManager.upload(data, to: url, method: method, headers: headers).response(queue: queue, completionHandler: completion)
        }else {
            //正常请求
            request = sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers).response(queue: queue, completionHandler: completion)
        }
        return request
    }

    ///单独的上传表单数据的请求
    public func multipartFormUpload(requestSpec:ApiRequestSpecV2, completion:@escaping ((Alamofire.DefaultDataResponse)->Void)) {
        let url = requestSpec.url
        let method = requestSpec.method.alamofireHTTPMethod
        let headers = requestSpec.headers
        let queue = requestSpec.parsingQueue

        sessionManager.upload(multipartFormData: { (multipart) in
            requestSpec.multipartFormData?.appendToAlamofirePart(part: multipart)
        }, to: url, method: method, headers: headers, queue: queue) { (encodingResult) in
            switch encodingResult {
            case .failure(let error):
                //表单数据
                let error = ApiRequestErrorV2.requestFailed(error, nil)
                let response = Alamofire.DefaultDataResponse(request: nil, response: nil, data: nil, error: error)
                completion(response)
            case .success(request: let uploadRequest, streamingFromDisk: _, streamFileURL: _):
                uploadRequest.response(queue: queue, completionHandler: completion)
            }
        }
    }

    ///所有的简单请求(GET, POST)都走这个方法， 除了上传表单数据
    public func basicCoolApkApiNoBodyRequest<T>(requestSpec:ApiRequestSpecV2, completion:@escaping ((ApiRequestResultV2<T>)->Void))->Alamofire.DataRequest {
        let url = requestSpec.url
        let method = requestSpec.method.alamofireHTTPMethod
        let headers = requestSpec.headers
        let queue = requestSpec.queue
        let parsingQueue = requestSpec.parsingQueue
        let parser = requestSpec.parser
        return sessionManager.request(url, method: method, parameters: nil, encoding: URLEncoding.default, headers: headers).responseCoolApkParsedObject(queue: queue, parseQueue: parsingQueue, parser: parser, completion: completion)
    }

    ///列表页请求q走这个方法
//    public func entityListRequest<T>(requestSpec:RXCEntityListViewController.EntityListRequestSpecV2, completion:@escaping (ApiRequestResultV2<T>)->Void)-> Alamofire.DataRequest {
//        let spec = requestSpec.toApiRequestSpec()
//
//    }


}
