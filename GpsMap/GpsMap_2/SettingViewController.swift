//
//  ViewController2.swift
//  GpsMap_2
//
//  Created by 樋口裕翔 on 2021/09/17.
//

import Foundation
import UIKit
import MapKit
import SwiftUI

class SettingsViewController: UIViewController, MKMapViewDelegate {
//    @IBOutlet weak var switchLabel: UILabel!
    
    
    @IBOutlet weak var sendEmail: UITextField!
    @IBOutlet weak var passEmail: UITextField!
    @IBOutlet weak var receiveEmail: UITextField!
    var sendDomain = ""
    var sendEmailAdress = ""
    
    var password = ""
    
    var receiveEmailAdress = ""
    //hiroto.0927.123@gmail.com

    override func viewDidLoad() {
        super.viewDidLoad()
        // 新しく追加したい処理を書く
        
        passEmail.textColor = .clear
        
    }
    
    @IBAction func sendClick(_ sender: Any) {
        
        if sendEmail.text == "" {
            return
        }
        
        let str = sendEmail.text
        let result = str!.range(of: "@")
        
        if let theRange = result {
            let afterStr = str![theRange.upperBound...]
            print("@\(afterStr)")
            
            self.sendDomain = "@\(afterStr)"
            self.sendEmailAdress = "\(String(describing: sendEmail.text))"
            
        } else {
            print("\(str)：正しく入力してください")
            
            return
        }
        
    }
    
    
    @IBAction func passClick(_ sender: Any) {
    
        if passEmail.text == "" {
            return
        }
        
        self.password = passEmail.text!
        
        passEmail.text = ""
        
        print(self.password)
    
    }
    
    
    @IBAction func receiveClick(_ sender: Any) {
        
        if receiveEmail.text == "" {
            return
        }
        
        self.receiveEmailAdress = receiveEmail.text!
        
    }

}
