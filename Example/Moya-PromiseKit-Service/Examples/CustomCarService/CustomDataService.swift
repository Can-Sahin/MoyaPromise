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

/*
 You can create custom data service to modiy the operational steps outside of the application layer
 */

public class CustomDataService<T:OAuth2TargetWrapped> : DataServiceProtocol{
    public typealias MoyaTarget = T
    
    public var moyaProvider: MoyaProvider<MoyaTarget>
    
    private let authTokenEndPointClosure = { (target: MoyaTarget) -> Endpoint<MoyaTarget> in
        let defaultEndpoint = MoyaProvider.defaultEndpointMapping(for: target)
        if let token = target.oAuthToken{
            return defaultEndpoint.adding(newHTTPHeaderFields: ["Authorization ": "Bearer \(token)"])
        }
        else{
            return defaultEndpoint
        }
        
    }
    init(){
        // Some example initialization that accepts 400 as valid response.
        self.moyaProvider = MoyaProvider<MoyaTarget>(endpointClosure: authTokenEndPointClosure, plugins:[NetworkLoggerPlugin(), AcceptableCodesPlugin([400])])
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

        let promise: Promise<Moya.Response> = YourOAuthLibraryGetTokenFunction().then{ token in
            if token == "someToken"{
                throw CustomError.Unauthorized
            }
            var modifiedTarget = target
            modifiedTarget.oAuthToken = token
            let cancellablePromise = self.makeRequestWithPromise(target: modifiedTarget, queue: queue, progress: progress)
            cancelWrapper.innerCancellable = cancellablePromise.cancelToken
            return cancellablePromise
        }
        let p = MoyaCancellablePromise.FromPromise(promise: promise)
        p.cancelToken = cancelWrapper
        return p
    }
    
    // A dummy function. Use real one to get your token :)
    private func YourOAuthLibraryGetTokenFunction() -> Promise<String>{
        return Promise(value: "someToken")
    }
  
}

public enum CustomError: Swift.Error{
    case Unauthorized
}


