//
//  CustomCarService.swift
//  Moya-PromiseKit-Service
//
//  Created by Can Sahin on 01/11/2017.
//  Copyright © 2017 Can Sahin. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import Moya


// An example for a customized data service.
public class CustomCarDataService: CustomDataService<CarAPI.ConvertibleTo>{
    
    public func getCar(_ id:String) -> Promise<String>  {
        return self.request(target: CarAPI.Car(id).wrap()).asString()
    }
    
}
