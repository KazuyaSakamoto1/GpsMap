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
            hostname: "smtp.gmail.com",     // SMTP server address
            email: "hiroto.0927.123@gmail.com",        // メールアドレスを入力
            password: ""            // password to login
        )
        
        let drLight = Mail.User(name: "Dr. Light", email: "hiroto.0927.123@gmail.com")
        let megaman = Mail.User(name: "Megaman", email: "hiroto_0927_123@yahoo.co.jp")

        let mail = Mail(
            from: drLight,
            to: [megaman],
            subject: "Humans and robots living together in harmony and equality.",
            text: "到着予定時間を超えています。安否確認を行ってください"
        )

        smtp.send(mail){ (error) in
            if let error = error {
                print("エラーがおきました\(error)")
            }
        }
    }
    
    // メールを自動で送信する関数 https://github.com/Kitura/Swift-SMTP
    func sendArrivedMail(text :String) {
        print("メールの送信を行います")
        let smtp = SMTP(
            hostname: "smtp.gmail.com",     // SMTP server address
            email: "hiroto.0927.123@gmail.com",        // メールアドレスを入力
            password: ""            // password to login
        )

        let drLight = Mail.User(name: "テストユーザー１", email: "hiroto.0927.123@gmail.com")
        let megaman = Mail.User(name: "テストユーザー２", email: "hiroto_0927_123@yahoo.co.jp")
        
        let mail = Mail(
            from: drLight,
            to: [megaman],
            subject: "Humans and robots living together in harmony and equality.",
            text: "目的地:\(text)へ到着しました。"
        )

        smtp.send(mail) { (error) in
            if let error = error {
                print("エラーがおきました\(error)")
            }
        }

    }
    
    // メールを自動で送信する関数(衝撃検知)
    func sendFallMail(coordinate: CLLocationCoordinate2D) {
        print("メールの送信を行います")
        let smtp = SMTP(
            hostname: "smtp.gmail.com",     // SMTP server address
            email: "hiroto.0927.123@gmail.com",        // メールアドレスを入力
            password: ""            // password to login
        )
        
        let drLight = Mail.User(name: "テストユーザー１", email: "hiroto.0927.123@gmail.com")
        let megaman = Mail.User(name: "テストユーザー２", email: "hiroto_0927_123@yahoo.co.jp")

        let mail = Mail(
            from: drLight,
            to: [megaman],
            subject: "Humans and robots living together in harmony and equality.",
            text: "端末が衝撃を検知しました。安全確認のため連絡を行ってください。(緯度:\(coordinate.latitude),経度:\(coordinate.longitude)"
        )

        smtp.send(mail) { (error) in
            if let error = error {
                print("エラーがおきました\(error)")
            }
        }
    }
    
}
