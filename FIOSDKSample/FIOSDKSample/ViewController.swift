//
//  ViewController.swift
//  FIOWalletSampleApp
//
//  Created by shawn arney on 10/5/18.
//  Copyright © 2018 Dapix, Inc. All rights reserved.
//

import UIKit
import FIOSDK

class ViewController: UIViewController {

    @IBOutlet weak var receiveAddress: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
             
        FIOSDK.sharedInstance(accountName: "exchange1111", privateKey: "5KDQzVMaD1iUdYDrA2PNK3qEP7zNbUf8D41ZVKqGzZ117PdM5Ap", url:"http://52.14.221.174:8889/v1").getAddressByFioName(fioName: "shanapi.brd", currencyCode: "ETH", completion: { results, error in ()
          
            print("get Address by FIO Name")
            
            if (error?.kind == FIOError.ErrorKind.Success){
                DispatchQueue.main.async {
                    self.receiveAddress.text = results.address
                }
            }
            else{
                DispatchQueue.main.async {
                    self.receiveAddress.text = error?.localizedDescription
                }
            }

        })
        
        if (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test.brd")){
            print("invalid - but should be valid")
        }

        if (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test.brd.brd")){
            print("invalid - and should be invalid")
        }
        
        if (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test#!.brd")){
            print("invalid - and should be invalid")
        }
        
        if (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test1234567890123456.brd")){
            print("invalid - but should be valid")
        }
        
        if (!FIOSDK.sharedInstance().isFioNameValid(fioName: "test12345678901234567.brd")){
            print("invalid - and should be invalid")
        }
        
        let receiveAddress:String = "0xc39b2845E3CFAdE5f5b2864fe73f5960B8dB483B"
        let publicReceiveAddresses:Dictionary<String,String> = [receiveAddress:"ETH"]
        FIOSDK.sharedInstance().registerFioName(fioName: "shanapi.brd", publicReceiveAddresses: publicReceiveAddresses, completion: {error in ()
            print("Register FIO Name")
        })
        
        FIOSDK.sharedInstance().getFioNameByAddress(publicAddress: receiveAddress, currencyCode: "ETH", completion:  {result, error in ()
            print ("Get FIO Name by Key")
            print (result.name)
            
        })

    }
}
