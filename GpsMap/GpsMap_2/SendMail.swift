//
//  SendMail.swift
//  ブラインドマップ
//
//  Created by 樋口裕翔 on 2021/12/18.
//

import Foundation
import UIKit
import SwiftSMTP
import CoreLocation

class SendMail {
        
    // メールを自動で送信する関数(到着時間を過ぎた時用)
    @objc func sendAttentionMail(_ sender: UIButton){
        print("メールの送信を行います")
        let smtp = SMTP(
//            hostname: "smtp.gmail.com",     // SMTP server address
            hostname: "smtp.",     // SMTP server address
            email: "",        // 送信側メールアドレスを入力
            password: ""            // 送信側パスワード
        )
        
        let drLight = Mail.User(name: "テストユーザ１", email: "")
        let megaman = Mail.User(name: "テストユーザ２", email: "")

        let mail = Mail(
            from: drLight,
            to: [megaman],
            subject: "Humans and robots living together in harmony and equality.",
            text: "到着予定時間を超えています。安否確認を行ってください"
        )

        smtp.send(mail){ (error) in
            if let error = error {
                print("エラーがおきました\(error)")
                return
            }
        }
    }
    
    // メールを自動で送信する関数 https://github.com/Kitura/Swift-SMTP
    func sendArrivedMail(text: String, domain: String, sendAdress: String, pass: String, toAdress: String) {
        
        print("メールの送信を行います")
        let smtp = SMTP(
            hostname: "smtp.\(domain)",     // SMTP server address
            email: "\(sendAdress)",        // 送信側メールアドレスを入力
            password: "\(pass)"            // 送信側パスワード
        )

        let drLight = Mail.User(name: "テストユーザ１", email: "\(sendAdress)")
        let megaman = Mail.User(name: "テストユーザ２", email: "\(toAdress)")
        
        let mail = Mail(
            from: drLight,
            to: [megaman],
            subject: "Humans and robots living together in harmony and equality.",
            text: "目的地\(text)へ到着しました。"
        )

        smtp.send(mail) { (error) in
            if let error = error {
                print("エラーがおきました\(error)")
                return
            }
        }

    }
    
    // メールを自動で送信する関数(衝撃検知)
    func sendFallMail(coordinate: CLLocationCoordinate2D, domain: String, sendMail: String, pass: String, toMail: String) {
        print("メールの送信を行います")
        let smtp = SMTP(
            hostname: "smtp.\(domain)",     // SMTP server address
            email: "\(sendMail)",        // メールアドレスを入力
            password: "\(pass)"            // password to login
        )
        
        let drLight = Mail.User(name: "テストユーザ１", email: "\(sendMail)")
        let megaman = Mail.User(name: "テストユーザ２", email: "\(toMail)")

        let mail = Mail(
            from: drLight,
            to: [megaman],
            subject: "Humans and robots living together in harmony and equality.",
            text: "端末が衝撃を検知しました。安全確認のため連絡を行ってください。(緯度:\(coordinate.latitude),経度:\(coordinate.longitude)"
        )

        smtp.send(mail) { (error) in
            if let error = error {
                print("エラーがおきました\(error)")
                return
            }
        }
    }
    
}
