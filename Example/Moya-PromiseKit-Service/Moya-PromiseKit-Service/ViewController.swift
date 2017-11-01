//
//  ViewController.swift
//  Moya-PromiseKit-Service
//
//  Created by Can Sahin on 01/11/2017.
//  Copyright © 2017 Can Sahin. All rights reserved.
//

import UIKit
import PromiseKit
class ViewController: UIViewController {
    let dataService = CarDataService()
    let customCarService = CustomCarDataService()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getCar1(){
 
        
        dataService.getCar("someId").then{carString in
            print(carString)
        }.catch{error in
            // Custom error handling
            if let err = error as? CustomError{
                if case .Unauthorized = err{
                    print("Not authorized")
                }
            }
            print(error)
        }.always {
            //UIActivityIndicatorView.stopAnimating()
        }
    }
    func getCar2(){
        dataService.getCarItem("someId").then{carItem in
            print(carItem.Name)
        }.catch{error in
            print(error)
        }.always {
            //UIActivityIndicatorView.stopAnimating()
        }
    }
    
    func getCarAndCancel(){
        let getCar = dataService.getCarAsCancellableRequest("someId")
        getCar.then{carString in
            print(carString)
        }.catch{error in
            print(error)
        }.always {
            //UIActivityIndicatorView.stopAnimating()
        }
        
        PromiseKit.after(seconds: 1).then{getCar.cancel()}
    }
    
    func getCar3(){
        customCarService.getCar("someId").then{carString in
            print(carString)
        }.catch{error in
            print(error)
        }.always {
            //UIActivityIndicatorView.stopAnimating()
        }
    }
    
    func readMeExamples(){
        DefaultDataService().request(target: CarTarget.Car("carId")).asStrin().then{carString in
            print(carString)
        }.catch{error in
            print(error)
        }
        
        let carDataService = CarDataService()
        carDataService.getCarItem("carId").then{carItem in
            print(carItem.Name)
        }.catch{error in
            print(error)
        }
        
        public class CarDataService: DefaultDataService<CarTarget>{
            public func getCarItem(_ id:String) -> Promise<DummyCarItem>  {
                return self.request(target: CarTarget.Car(id)).asParsedObject()
            }
            public func getDriver(_ carId:String ) -> Promise<String>  {
                return self.request(target: CarTarget.Driver(carId)).asString()
            }
        }
    }
}

