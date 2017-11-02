//
//  SomeSSLPinningDataService.swift
//  Moya-PromiseKit-Service
//
//  Created by Can Sahin on 01/11/2017.
//  Copyright © 2017 Can Sahin. All rights reserved.
//

import Foundation
import Moya
import PromiseKit
import Alamofire
/*
 Make your own concrete DataService from DataServiceProtocol and implement SSL PublicKey pinning at init
 */

public class SSLPinningDataService<Target: TargetType> : DataServiceProtocol {
    public typealias MoyaTarget = Target
    
    public var moyaProvider: MoyaProvider<Target>
    
    init(){
        /*
         - Creating a certificate file of remote server using 'openssl' -
         
         Install openssl (brew recommended)
         Type the following commands (First produces .pem file then converts it to .der file)
         
         openssl s_client -showcerts -connect {HOST}:{PORT} -prexit > {FILENAME}.pem </dev/null;
         openssl x509 -outform der -in {FILENAME}.pem -out {CERTIFICATENAME}.der
         
         Import your .der file in a bundle (main bundle default) and Alamofire will look for all the public keys in all .der files. No need to specify the file's location
         */
        let HOST = "{YOUR_HOST_URL}"
        let trustPolicy = ServerTrustPolicy.pinPublicKeys(publicKeys: ServerTrustPolicy.publicKeys(), validateCertificateChain: true, validateHost: true)
        let serverTrustPolicies = [
            HOST:trustPolicy
        ]
        let policyManager = ServerTrustPolicyManager(policies: serverTrustPolicies)
        
        let manager = Manager(configuration: URLSessionConfiguration.default, delegate: SessionDelegate(),serverTrustPolicyManager:policyManager)
        
        // ALL requests that fails the pinning return NSCancelledError.
        self.moyaProvider = MoyaProvider<Target>(manager: manager)
    }
}

// Initialize from your concrete class
public class SomeSSLPinningDataService: SSLPinningDataService<CarAPI>{
    public func getSomething() -> Promise<String>{
        return self.request(target: CarAPI.Wheels).asString()
    }
}
