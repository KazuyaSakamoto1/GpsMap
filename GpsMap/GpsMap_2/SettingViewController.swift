//
//  ViewController2.swift
//  GpsMap_2
//
//  Created by 樋口裕翔 on 2021/09/17.
//

import Foundation
import UIKit
import MapKit

class SettingsViewController: UIViewController, MKMapViewDelegate {
//    @IBOutlet weak var switchLabel: UILabel!
    
    
    @IBOutlet weak var sendEmail: UITextField!
    @IBOutlet weak var passEmail: UITextField!
    @IBOutlet weak var receiveEmail: UITextField!
    let mailController = SendMail()
    
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
    
    // 送信側メールアドレス
    @IBAction func sendClick(_ sender: Any) {
        
        let viewController = self.presentingViewController as! ViewController
        sendEmail.endEditing(true)
        
        if sendEmail.text == "" {
            return
        }
        
        viewController.sendAdress = self.sendEmail.text!
        
        let str = sendEmail.text
        let result = str!.range(of: "@")
        
        if let theRange = result {
            let afterStr = str![theRange.upperBound...]
            
            self.sendDomain = "\(afterStr)"
            self.sendEmailAdress = "\(String(describing: sendEmail.text))"
            
            viewController.domain = self.sendDomain
            
            print("メールアドレスが入力されました。")
            
        } else {
            print("\(str)：正しく入力してください")
            sendEmail.text = ""
            
            return
        }
        
    }
    
    // 送信側パスワード
    @IBAction func passClick(_ sender: Any) {
    
        let viewController = self.presentingViewController as! ViewController
        
        passEmail.endEditing(true)
        
        if passEmail.text == "" {
            return
        }
        
        self.password = passEmail.text!
        
        passEmail.text = ""
        
        viewController.sendPass = self.password
    print("パスワードを入力しました。")
        
    }
    
    // 受信側メールアドレス
    @IBAction func receiveClick(_ sender: Any) {
        let viewController = self.presentingViewController as! ViewController
        
        receiveEmail.endEditing(true)
        
        if receiveEmail.text == "" {
            return
        }
        
        viewController.receiveAdress = receiveEmail.text!
        
        print("\(self.receiveEmailAdress)")
        print("メールアドレスが入力されました。")

    }

}
