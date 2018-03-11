//
//  DataService + Default.swift
//
//  Created by Can Sahin on 28/06/2017.
//  Copyright © 2017 Can Sahin. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import Moya

public struct DataServiceProperties{
    public static var RequestSampleDataOnFail = false
    public static var SaveAllAsSampleData = false
}

/// Concrete class for default implementations
open class DefaultDataService<Target: TargetType> : DataServiceProtocol {
    public typealias MoyaTarget = Target

    public var moyaProvider: MoyaProvider<Target>
    
    init(){
        self.moyaProvider = MoyaProvider<Target>()
    }
    init(moyaProvider: MoyaProvider<Target>){
        self.moyaProvider = moyaProvider
    }
}

/// Protocol for every DataService types
public protocol DataServiceProtocol{
    associatedtype MoyaTarget: TargetType
    var moyaProvider: MoyaProvider<MoyaTarget> { get set}
    var retryPolicy: RetryPolicy? {get set}
//    var retrievePolicy: RetrievePolicy? {get set}
    //Override this when writing a custom DataService
    func makeRequest(target: MoyaTarget,queue: DispatchQueue?,progress: Moya.ProgressBlock?) -> MoyaCancellablePromise<Moya.Response>
}

// Default implementations for the protocol
public extension DataServiceProtocol{
    public var retryPolicy: RetryPolicy?{ get{return nil} set{}}
//    public var retrievePolicy: RetrievePolicy?{ get{return nil} set{}}

    public func cancelAllTasks(){
        moyaProvider.manager.session.getTasksWithCompletionHandler { dataTasks, uploadTasks, downloadTasks in
            dataTasks.forEach { $0.cancel() }
            uploadTasks.forEach { $0.cancel() }
            downloadTasks.forEach { $0.cancel() } }
    }
    
    
    public func request(target: MoyaTarget,
                            retryPolicy: RetryPolicy? = nil,
                            queue: DispatchQueue? = nil,
                            progress: Moya.ProgressBlock? = nil) -> MoyaCancellablePromise<Moya.Response>{
//        var changedRetryPolicy = retryPolicy
//        var changedRetrievePolicy = retrievePolicy

//        #if DEBUG
//            if DataServiceProperties.RequestSampleDataOnFail{
//                changedRetryPolicy = RetryPolicy.sampleDataOnFailure
//            }
//            if DataServiceProperties.SaveAllAsSampleData {
//                changedRetrievePolicy = RetrievePolicy.storeAsSampleData
//            }
//        #endif
        if let policy = pickNonNil(retryPolicy, self.retryPolicy){
            return retry(policy: policy, target: target) { 
                return self.makeRequest(target: target, queue: queue, progress: progress).completeWithRetrievePolicy(target: target)
            }
        }
        else{
            return makeRequest(target: target, queue: queue, progress: progress).completeWithRetrievePolicy(target: target)
        }

    }


    public func makeRequest(target: MoyaTarget,
                                       queue: DispatchQueue? = nil,
                                       progress: Moya.ProgressBlock? = nil) -> MoyaCancellablePromise<Moya.Response>{
        return self.makeRequestWithPromise(target: target, queue: queue, progress: progress)
    
    }
    public func makeRequestWithPromise(target: MoyaTarget,
                                         queue: DispatchQueue? = nil,
                                         progress: Moya.ProgressBlock? = nil) ->  MoyaCancellablePromise<Moya.Response>{
        return self.moyaProvider.requestPromise(target: target, queue: queue, progress: progress)
        
    }

    
    @discardableResult
    private func retry(policy retryPolicy : RetryPolicy?, target targetToRetry: MoyaTarget, _ body: @escaping () -> MoyaCancellablePromise<Moya.Response>) -> MoyaCancellablePromise<Moya.Response> {
        
        guard let policy = retryPolicy else{
            return body()
        }
        
        switch policy {
//        case .sampleDataOnFailure:
//            #if DEBUG
//                return retryWithSampleData(target: targetToRetry, body)
//            #else
//                return body()
//            #endif
        case .requestRetry(let moyaPolicy):
            return retryRequest(p: moyaPolicy, body)
        }
    
    }
//    @discardableResult
//    private func retryWithSampleData(target targetToRetry: MoyaTarget, _ body: @escaping () -> MoyaCancellablePromise<Moya.Response>) -> MoyaCancellablePromise<Moya.Response> {
//
//        return body().recover(policy: CatchPolicy.allErrorsExceptCancellation) { error, token -> MoyaCancellablePromise<Moya.Response> in
//            let p: MoyaCancellablePromise<Moya.Response> = MoyaCancellablePromise{(f, r) in
//                SampleDataService().makeSampleRequest(target: SampleDataTarget.Get(targetToRetry)).then{ (rsp) -> Void in
//                    print("Sample Data is found")
//                    f(rsp)
//                }.catch{errorLast in
//                    if let moyaError = errorLast as? MoyaError, moyaError.isStatusCodeError(code:404).0{
//                        print("Sample data cannot be found! ")
//                    }
//                    else{
//                        print("Cannot get sample data: " + errorLast.localizedDescription)
//                    }
//                    r(error)
//                }
//            }
//            if let cancelToken = token{
//                p.cancelToken = cancelToken
//            }
//            return p
//        }
//    }
    @discardableResult
    private func retryRequest(p policy : RequestMoyaRetryPolicy, _ body: @escaping () -> MoyaCancellablePromise<Moya.Response>) -> MoyaCancellablePromise<Moya.Response> {
   
        var retryCounter = 0
        let times = policy.retryCount
        let coolDown = policy.coolDownInterval
        
        func attempt() -> MoyaCancellablePromise<Moya.Response> {
            return body().recover(policy: CatchPolicy.allErrorsExceptCancellation) { error, token , setTokenFunction -> Promise<Moya.Response> in
                retryCounter += 1
                guard retryCounter <= times else {
                    throw error
                }
                if !policy.errorClosure(error){
                    throw error
                }
                let promise =  PromiseKit.after(seconds: coolDown).then{_ -> Promise<Moya.Response> in
                    if token?.isCancelled ?? false {
                        throw PMKError.cancelled
                    }
                    let result = attempt()
                    setTokenFunction(result.cancelToken)
                    return result.promise
                }
                return promise
            }
        }
        
        return attempt()
    }

}
extension MoyaCancellablePromise where T: Moya.Response{
    func completeWithRetrievePolicy(target: TargetType) -> Self{
        //Retrieve Policy is unimplemented for now
        return self
//        guard let retrievePolicy = policy else{
//            return self
//        }
//        if retrievePolicy == .storeAsSampleData{
//            return storeAsSampleData(target: target)
//        }
//        return self
    }
//    private func storeAsSampleData(target: TargetType) -> Self{
//        #if DEBUG
//        self.thenWith { moyaResponse in
//            moyaResponse.responseString().then{data -> Void in
//                SampleDataService().makeSampleRequest(target: SampleDataTarget.Put(target,data)).catch{error in
//                    print("Cannot write sample data: " + error.localizedDescription)
//                }
//            }
//        }.catch{_ in}
//        #endif
//        return self
//    }
}

extension MoyaCancellablePromise where T: Moya.Response{
    public func asParsedObject<T:Codable>() -> MoyaCancellablePromise<T>{
        return MoyaCancellablePromise<T>(promise: self.promise.then(on: DispatchQueue.global(qos: .background)) { moyaResponse in
            return moyaResponse.responseObject()
        }, cancelToken: self.cancelToken);
    }
    
    public func asString() -> MoyaCancellablePromise<String>{
        return MoyaCancellablePromise<String>(promise: self.promise.then { moyaResponse in
            return moyaResponse.responseString()
        }, cancelToken: self.cancelToken);
    }
    public func asData() -> MoyaCancellablePromise<Data>{
        return MoyaCancellablePromise<Data>(promise: self.promise.then { moyaResponse in
            return moyaResponse.responseData()
        }, cancelToken: self.cancelToken);
    }
    public func asJson() -> MoyaCancellablePromise<Any>{
        return MoyaCancellablePromise<Any>(promise: self.promise.then { moyaResponse in
            return moyaResponse.responseJSON()
        }, cancelToken: self.cancelToken);
    }
    public func asJsonDictionary() -> MoyaCancellablePromise<[String: Any]>{
        return MoyaCancellablePromise<[String: Any]>(promise: self.promise.then { moyaResponse in
            return moyaResponse.responseJsonDictionary()
        }, cancelToken: self.cancelToken);
    }
}

