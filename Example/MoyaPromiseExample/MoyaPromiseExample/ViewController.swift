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
    
    @IBAction func networkCall1() {
        self.getCarWithRetryAndCancel()
    }
    @IBAction func networkCall2() {
        self.getCar2()
    }
    
    func getCar1(){
        dataService.getCar("someId").done{carString in
            print(carString)
        }.catch{error in
            // Custom error handling
            if let err = error as? CustomError{
                if case .Unauthorized = err{
                    print("Not authorized")
                }
            }
            print(error)
        }.finally {
            //UIActivityIndicatorView.stopAnimating()
        }
    }
    func getCar2(){
        dataService.getCarItem("someId").done{carItem in
            print(carItem.Name)
        }.catch{error in
            print(error)
        }.finally {
            //UIActivityIndicatorView.stopAnimating()
        }
    }
    
    func getCarAndCancel(){
        let getCar = dataService.getCarAsCancellableRequest("someId")
        getCar.promise.done{carString in
            print(carString)
        }.catch(policy: CatchPolicy.allErrors){error in
            print(error)
        }.finally {
            //UIActivityIndicatorView.stopAnimating()
        }
        
        PromiseKit.after(seconds: 1).done{getCar.cancel()}
    }
    func getCarWithRetryAndCancel(){
        let getCar = dataService.getCarWithRetryPolicy("someId")
        getCar.promise.done{carString in
            print(carString)
        }.catch(policy: CatchPolicy.allErrors){error in
            print(error)
        }.finally {
            //UIActivityIndicatorView.stopAnimating()
        }
        
        
        PromiseKit.after(seconds: 5).done{
            getCar.cancel()
        }
    }


    
    func getCar3(){
        customCarService.getCar("someId").map{carString in
            print(carString)
        }.catch{error in
            print(error)
        }.finally {
            //UIActivityIndicatorView.stopAnimating()
        }
    }
}

