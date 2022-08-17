//
//  ViewController2.swift
//  GpsMap_2
//
//  Created by 樋口裕翔 on 2021/09/17.
//

import Foundation
import UIKit
import MapKit

class objectswitch{
    var wall:Bool = true
    var person:Bool = true
    var block:Bool = true
    var cross:Bool = true
    var cone:Bool = true
    var car:Bool = true
}

class SettingsViewController: UIViewController, MKMapViewDelegate {
//    @IBOutlet weak var switchLabel: UILabel!
    
    
    @IBOutlet weak var sendEmail: UITextField!
    @IBOutlet weak var passEmail: UITextField!
    @IBOutlet weak var receiveEmail: UITextField!
    
    @IBOutlet weak var wallswitch: UISwitch!
    @IBOutlet weak var personswitch: UISwitch!
    @IBOutlet weak var blockswitch: UISwitch!
    @IBOutlet weak var crossswitch: UISwitch!
    @IBOutlet weak var coneswitch: UISwitch!
    @IBOutlet weak var carswitch: UISwitch!
    
    let mailController = SendMail()
    let Switch = objectswitch()
    
    var sendDomain = ""
    var sendEmailAdress = ""
    var password = ""
    var receiveEmailAdress = ""
    
    
    
    //hiroto.0927.123@gmail.com

    override func viewDidLoad() {
        super.viewDidLoad()
        // 新しく追加したい処理を書く
        passEmail.textColor = .clear
        
        self.sendEmail.layer.borderColor = UIColor.black.cgColor
        self.sendEmail.layer.borderWidth = 2.0
        
        self.passEmail.layer.borderColor = UIColor.black.cgColor
        self.passEmail.layer.borderWidth = 2.0
        
        self.receiveEmail.layer.borderColor = UIColor.black.cgColor
        self.receiveEmail.layer.borderWidth = 2.0
        
        Switch.wall   = UserDefaults.standard.bool(forKey: "wall")
        Switch.person = UserDefaults.standard.bool(forKey: "person")
        Switch.block  = UserDefaults.standard.bool(forKey: "block")
        Switch.cross  = UserDefaults.standard.bool(forKey: "cross")
        Switch.cone   = UserDefaults.standard.bool(forKey: "cone")
        Switch.car   = UserDefaults.standard.bool(forKey: "car")
        
        wallswitch.setOn(Switch.wall, animated: false)
        personswitch.setOn(Switch.person, animated: false)
        blockswitch.setOn(Switch.block, animated: false)
        crossswitch.setOn(Switch.cross, animated: false)
        coneswitch.setOn(Switch.cone, animated: false)
        carswitch.setOn(Switch.car, animated: false)
    }
    
    
    @IBAction func wallSwitch(_ sender: UISwitch) {
        let objectswitch = objectswitch()
        if(sender.isOn){
            objectswitch.wall = true
            UserDefaults.standard.set(objectswitch.wall, forKey: "wall")
        }else{
            objectswitch.wall = false
            UserDefaults.standard.set(objectswitch.wall, forKey: "wall")
        }
    }
    
    @IBAction func personSwitch(_ sender: UISwitch) {
        let objectswitch = objectswitch()
        if(sender.isOn){
            objectswitch.person = true
            UserDefaults.standard.set(objectswitch.person, forKey: "person")
        }else{
            objectswitch.person = false
            UserDefaults.standard.set(objectswitch.person, forKey: "person")
        }
    }
    
    @IBAction func blockSwitch(_ sender: UISwitch) {
        let objectswitch = objectswitch()
        if(sender.isOn){
            objectswitch.block = true
            UserDefaults.standard.set(objectswitch.block, forKey: "block")
        }else{
            objectswitch.block = false
            UserDefaults.standard.set(objectswitch.block, forKey: "block")
        }
    }
    
    
    @IBAction func crossSwitch(_ sender: UISwitch) {
        let objectswitch = objectswitch()
        if(sender.isOn){
            objectswitch.cross = true
            UserDefaults.standard.set(objectswitch.cross, forKey: "cross")
        }else{
            objectswitch.cross = false
            UserDefaults.standard.set(objectswitch.cross, forKey: "cross")
        }
    }
    
    @IBAction func coneSwitch(_ sender: UISwitch) {
        let objectswitch = objectswitch()
        if(sender.isOn){
            objectswitch.cone = true
            UserDefaults.standard.set(objectswitch.cone, forKey: "cone")
        }else{
            objectswitch.cone = false
            UserDefaults.standard.set(objectswitch.cone, forKey: "cone")
        }
    }
    
    @IBAction func carSwitch(_ sender: UISwitch) {
        let objectswitch = objectswitch()
        if(sender.isOn){
            objectswitch.car = true
            UserDefaults.standard.set(objectswitch.car, forKey: "car")
        }else{
            objectswitch.car = false
            UserDefaults.standard.set(objectswitch.car, forKey: "car")
        }
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
            print("\(str!)：正しく入力してください")
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
