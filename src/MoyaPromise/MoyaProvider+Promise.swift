//
//  MoyaProvider+Promise.swift
//
//  Created by Can Sahin on 28/06/2017.
//  Copyright © 2017 Can Sahin. All rights reserved.
//

import Foundation
import PromiseKit
import Moya


// Copy of Moya.CancellableWrapper class. Moya made it internal so this is the identical copy for the module
internal class CancellableWrapper: Cancellable {
    internal var innerCancellable: Cancellable = SimpleCancellable()
    
    var isCancelled: Bool { return innerCancellable.isCancelled }
    
    internal func cancel() {
        innerCancellable.cancel()
    }
}
// Copy of Moya.SimpleCancellable class. Moya made it internal so this is the identical copy for the module
internal class SimpleCancellable: Cancellable {
    var isCancelled = false
    func cancel() {
        isCancelled = true
    }
}

/// Simply a 'custom' Promise holding a cancellable token
public class MoyaCancellablePromise<T>{
    private let corePromise: Promise<T>
    var cancelToken: Cancellable = SimpleCancellable()
    
    public func cancel(){
        cancelToken.cancel()
    }
    
    public var isCancelled: Bool { return cancelToken.isCancelled}
    
    public init(promise: Promise<T>) {
        self.corePromise = promise
    }
    public init(promise: Promise<T>, cancelToken: Cancellable?) {
        self.corePromise = promise
        if let token = cancelToken{
            self.cancelToken = token
        }
    }
    
    public init(value: T) {
        self.corePromise = Promise.value(value);
    }

    public init(error: Swift.Error) {
        self.corePromise = Promise.init(error: error);
    }
//
    public var promise: Promise<T>{
        return self.corePromise;
    }
    
    /// 'Recover' implementation with CancelledError check
    internal func recover(on q: DispatchQueue = .main, policy: CatchPolicy = .allErrorsExceptCancellation, execute body: @escaping (Swift.Error, Cancellable?, @escaping (Cancellable) -> Void) throws -> Promise<T>) -> MoyaCancellablePromise<T>{
        let recoveredPromise = self.corePromise.recover(on: q, policy: policy) { (error) -> Promise<T> in
            if self.isCancelled{
                throw PMKError.cancelled
            }
            return try body(error, self.cancelToken) {token in
                // Pass it as nested object so the top level object (firstly created MoyaRequest) can still access the cancel token after many tries
                if let cancelWrapper = self.cancelToken as? CancellableWrapper{
                    cancelWrapper.innerCancellable = token
                }
                else{
                    self.cancelToken = token
                }
            }
        }
        return MoyaCancellablePromise<T>(promise: recoveredPromise, cancelToken: self.cancelToken)
    }
}

public extension MoyaProvider {
    
    /// Promise value of moya request
    func requestPromise(target: Target,
                        queue: DispatchQueue? = nil,
                        progress: Moya.ProgressBlock? = nil) -> MoyaCancellablePromise<Moya.Response>{
        
        let token = CancellableWrapper()
        
        let p:Promise<Moya.Response> = Promise {seal in
            token.innerCancellable = self.request(target, callbackQueue: queue, progress: progress, completion: { (result) in
                switch result {
                case let .success(response):
                    seal.fulfill(response)
                case let .failure(error):
                    if error.isCancelledError{
                        seal.reject(PMKError.cancelled)
                    }
                    else{
                        seal.reject(error)
                    }
                }
            })
        }
        let moyaPromise = MoyaCancellablePromise(promise: p, cancelToken: token)
        return moyaPromise
    }

}

