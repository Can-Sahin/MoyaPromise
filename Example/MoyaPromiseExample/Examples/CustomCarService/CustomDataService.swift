//
//  CustomDataService.swift
//  Moya-PromiseKit-Service
//
//  Created by Can Sahin on 01/11/2017.
//  Copyright © 2017 Can Sahin. All rights reserved.
//

import Foundation
import PromiseKit
import Moya
import MoyaPromise

/*
 You can create custom data service to modiy the operational steps outside of the application layer
 */

public class CustomDataService<T:OAuth2TargetWrapped> : DataServiceProtocol{
    public typealias MoyaTarget = T
    
    public var moyaProvider: MoyaProvider<MoyaTarget>
    
    private let authTokenEndPointClosure = { (target: MoyaTarget) -> Endpoint in
        let defaultEndpoint = MoyaProvider.defaultEndpointMapping(for: target)
        if let token = target.oAuthToken{
            return defaultEndpoint.adding(newHTTPHeaderFields: ["Authorization ": "Bearer \(token)"])
        }
        else{
            return defaultEndpoint
        }
        
    }
    init(){
        self.moyaProvider = MoyaProvider<MoyaTarget>(endpointClosure: authTokenEndPointClosure, plugins:[NetworkLoggerPlugin()])
    }
    
    
    // Override makeRequest
    public func makeRequest(target: MoyaTarget,
                            queue: DispatchQueue? = nil,
                            progress: Moya.ProgressBlock? = nil) -> MoyaCancellablePromise<Moya.Response>{
        return self.makeCustomRequest(target: target, queue: queue, progress: progress)
    }
    
    
    public func makeCustomRequest(target: MoyaTarget,
                                          queue: DispatchQueue? = nil,
                                          progress: Moya.ProgressBlock? = nil) -> MoyaCancellablePromise<Moya.Response>{
        // Implement a custom logic for your request.
        // Here is an dirty example of getting a OAuth token and making a request with it.
        
        let cancelWrapper = CancellableWrapper()

        let promise = YourOAuthLibraryGetTokenFunction().then {token -> Promise<Moya.Response> in
            if token == "someToken"{
                throw CustomError.Unauthorized
            }
            var modifiedTarget = target
            modifiedTarget.oAuthToken = token
            let cancellablePromise = self.makeRequestWithPromise(target: modifiedTarget, queue: queue, progress: progress)

            cancelWrapper.innerCancellable = cancellablePromise.cancelToken
            return cancellablePromise.promise
            
        }
        let p = MoyaCancellablePromise(promise: promise, cancelToken: cancelWrapper)
        return p
    }
    
    // A dummy function. Use real one to get your token :)
    private func YourOAuthLibraryGetTokenFunction() -> Promise<String>{
        return Promise.value("someToken")
    }
  
}

public enum CustomError: Swift.Error{
    case Unauthorized
}


