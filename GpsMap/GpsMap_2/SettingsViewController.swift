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
    // 地図の表示変更
    @IBAction func satelliteButton(_ sender: Any) {
        ViewController().mapView.mapType = .satellite // mapViewでnilが見つかると言われる。
    }
    // 仮のボタン
    @IBAction func example(_ sender: Any) {
        ViewController().mapView.mapType = .satellite // mapViewでnilが見つかると言われる。
    }
}
