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
    override func viewDidLoad() {
        super.viewDidLoad()
        // 新しく追加したい処理を書く
    }
    // 仮のボタン
    @IBAction func example(_ sender: Any) {
//        let mainViewController = self.storyboard?.instantiateViewController(withIdentifier: "main") as! ViewController
        print("-------------------------------------")
//        print(mainViewController)
        ViewController().mapView.mapType = .satellite // mapViewでnilが見つかると言われる。
    }
}
