//
//  ViewController2.swift
//  GpsMap_2
//
//  Created by 樋口裕翔 on 2021/09/17.
//

import Foundation
import UIKit

class ViewController2: UIViewController {
    @IBOutlet weak var switchLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        // 新しく追加したい処理を書く
    }
    @IBAction func rotateSwitch(_ sender: UISwitch) {
        if sender.isOn {
            self.switchLabel.text = "ON"
            //https://developer.apple.com/documentation/mapkit/mkmapview/1452274-isrotateenabled
            //            self.mapView.isRotateEnabled = true
        } else {
            self.switchLabel.text = "OFF"
        }
    }
}
