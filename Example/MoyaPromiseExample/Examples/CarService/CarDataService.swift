//
//  CarDataService.swift
//  Moya-PromiseKit-Service
//
//  Created by Can Sahin on 01/11/2017.
//  Copyright © 2017 Can Sahin. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import Moya

// Subclass of default
public class CarDataService: DefaultDataService<CarAPI>{
//    override init() {
//        let moyaProvider = MoyaProvider<CarAPI>(plugins: [DebugNetworkLoggerPlugin()])
//        super.init(moyaProvider: moyaProvider)
//    }
    
    /// Make the request and parse the response to string
    public func getCar(_ id:String) -> Promise<String>  {
        return self.request(target: CarAPI.Car(id)).asString().promise
    }
    
    /// Make the request and decode the response to an object
    public func getCarItem(_ id:String) -> Promise<DummyCarItem>  {
        return self.request(target: CarAPI.Car(id)).asParsedObject().promise
    }
    
    /* Not implemented for now */
    /// Get sample when the request fails
//    public func getCarItemWithSampleDataOnFail(_ id:String) -> Promise<DummyCarItem>  {
//        /*
//         To enable for all requests use
//             DataServiceProperties.RequestSampleDataOnFail = true
//         */
//        return self.request(target: CarAPI.Car(id),retryPolicy: RetryPolicy.sampleDataOnFailure).asParsedObject()
//    }
    
    /* Not implemented for now */
    /// Write as sample when the request succeeds
//    public func getCarItem_WriteAsSampleData(_ id:String) -> Promise<DummyCarItem>  {
//        /*
//         To enable for all requests use
//             DataServiceProperties.SaveAllAsSampleData = true
//         */
//        return self.request(target: CarAPI.Car(id),retrievePolicy: RetrievePolicy.storeAsSampleData).asParsedObject()
//    }
    
    /// Retry requests under some conditions
    public func getCarWithRetryPolicy(_ id:String) -> MoyaCancellablePromise<String>  {
        let p = RequestMoyaRetryPolicy(retryCount: 10, coolDownInterval: 1) { (error) -> Bool in
            print("retry")
            // Examine error and decide if you want to retry. Return false to not to retry
            return true
        }
        return request(target: CarAPI.Car(id),retryPolicy: RetryPolicy.requestRetry(p)).asString()
    }
    
    /// Get the request as cancellable
    public func getCarAsCancellableRequest(_ id:String) -> MoyaCancellablePromise<String>  {
        return request(target: CarAPI.Car(id)).asString()
    }
    
}

public class DummyCarItem:Codable{
    public var Id: String
    public var Name: String
    public var Age: Int
}
