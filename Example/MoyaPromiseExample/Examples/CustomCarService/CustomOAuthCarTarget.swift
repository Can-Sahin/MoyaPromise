//
//  CustomOAuthCarTarget.swift
//  Moya-PromiseKit-Service
//
//  Created by Can Sahin on 01/11/2017.
//  Copyright © 2017 Can Sahin. All rights reserved.
//

import Foundation
import Alamofire
import Moya

public protocol CustomCarTargetType: TargetType{
    var someExtraFieldForAllCarTarget: String {get}
}

public protocol OAuth2CarAPI: CustomCarTargetType,TargetConvertible{}


public protocol OAuth2TargetWrapped: CustomCarTargetType{
    var oAuthToken: String? {get set}
}

public struct OAuth2Target<T: OAuth2CarAPI> : OAuth2TargetWrapped, TargetWrapable{
    public typealias WrappedType = T
    public var target: WrappedType
    
    public init(from: WrappedType) {
        target = from
    }
    
    public var oAuthToken: String?
    
    public var someExtraFieldForAllCarTarget: String{
        return target.someExtraFieldForAllCarTarget
    }
}

extension CarAPI: OAuth2CarAPI{
    public typealias ConvertibleTo = OAuth2Target<CarAPI>
    /// Generates a new object that is not limited by enum. In other words, that can have stored properties like OAuthToken that will be added during the request.
    public func wrap() -> ConvertibleTo{
        return OAuth2Target(from: self)
    }
    
    public var someExtraFieldForAllCarTarget: String {
        switch self {
        default:
            return ""
        }
        
    }
}
