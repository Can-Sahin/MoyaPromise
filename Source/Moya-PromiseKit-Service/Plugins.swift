//
//  Plugins.swift
//  GarentaPro
//
//  Created by Can Sahin on 10/08/2017.
//  Copyright © 2017 Mehmet Cakir. All rights reserved.
//

import Foundation
import Moya
import PromiseKit
import enum Result.Result

// Custom plugins

/// Plugin for extending the range of valid codes of Alamofire, since Moya layer doesn't allow further than the boolean flag 'validate'.
/// Make sure you set 'validate' to FALSE in Target
public struct AcceptableCodesPlugin: PluginType {
    
    fileprivate static var defaultCodes: [Int] { return Array(200..<300) }
    
    private var acceptableStatusCodes: [Int]
    public init(_ codes: [Int]) {
        acceptableStatusCodes = AcceptableCodesPlugin.defaultCodes + codes
    }
    
    public func process(_ result: Result<Response, MoyaError>, target: TargetType) -> Result<Response, MoyaError> {
        if target.validate{
            return result
        }
        
        switch result {
        case let .success(response):
            if acceptableStatusCodes.contains(response.statusCode) {
                return .success(response)
            }
            else{
                let reason: AFError.ResponseValidationFailureReason = .unacceptableStatusCode(code: response.statusCode)
                return .failure(MoyaError.underlying(AFError.responseValidationFailed(reason: reason),nil))
            }
        case .failure(_):
            return result
        }
        
    }
}

/// Simple network console logger for debug mode
public struct DebugNetworkLoggerPlugin: PluginType{
    private let logResponseData: Bool
    init(_ logResponseData: Bool = false) {
        self.logResponseData = logResponseData
    }
    public func willSend(_ request: RequestType, target: TargetType) {
        #if DEBUG
            print("- Outgoing Network Request -")
            
            print("Request: " + (request.request?.description ?? "(invalid request)"))

            if let headers = request.request?.allHTTPHeaderFields {
                print("Headers: " + headers.description)
            }
            if let body = request.request?.httpBody, let stringOutput = String(data: body, encoding: .utf8) {
                print("Request Body: " + stringOutput)
            }
            print("")

        #endif
    }
    
    public func didReceive(_ result: Result<Moya.Response, MoyaError>, target: TargetType) {
        #if DEBUG
            if case .success(let rsp) = result {
                guard let response = rsp.response else {
                    print("Received empty network response for \(target).")
                    return
                }
                print("- Incoming Network Response -")
                print("Url: " + target.baseURL.appendingPathComponent(target.path).absoluteString)
                print("Response: " + response.description)
                if self.logResponseData, let stringData = String(data: rsp.data, encoding: String.Encoding.utf8) {
                    print("Data: " + stringData)
                }
            } else {
                print("- Incoming Network Response FAILED!! - \n")
                print("Url: " + target.baseURL.appendingPathComponent(target.path).absoluteString)

            }
            print("")

        #endif
    }
}
