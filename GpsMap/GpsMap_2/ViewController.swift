//
//  ViewController.swift
//  GpsMap_2
//
//  Created by hiroto on 2021/08/12.
//

import UIKit
import CoreLocation //位置情報を取得するためのフレームワーク
import MapKit //地図表示のプログラム

class ViewController: UIViewController , CLLocationManagerDelegate{
    var myLock = NSLock()
    let up_goldenRatio = 1.618
    let down_goldenRatio = 2.0
    
    @IBOutlet var mapView: MKMapView!
    var locationManager : CLLocationManager!
    
    //拡大のボタン
    @IBAction func ZoomIn(_ sender: Any) {
        print("[DBG]clickZoomin")
        myLock.lock()
        if (0.0001 < mapView.region.span.latitudeDelta / up_goldenRatio) {
                print("[DBG]latitudeDelta-1 : " + mapView.region.span.latitudeDelta.description)
                var regionSpan:MKCoordinateSpan = MKCoordinateSpan()
                regionSpan.latitudeDelta = mapView.region.span.latitudeDelta / up_goldenRatio
                mapView.region.span = regionSpan
                print("[DBG]latitudeDelta-2 : " + mapView.region.span.latitudeDelta.description)
        }
        myLock.unlock()
    }
    
    
    //縮小のボタン
    @IBAction func ZoomOut(_ sender: Any) {
        print("[DBG]clickZoomout")
        print(mapView.region.span.latitudeDelta)
        myLock.lock()
        if (mapView.region.span.latitudeDelta * down_goldenRatio < 150.0) {
                print("[DBG]latitudeDelta-1 : " + mapView.region.span.latitudeDelta.description)
                var regionSpan:MKCoordinateSpan = MKCoordinateSpan()
                regionSpan.latitudeDelta = mapView.region.span.latitudeDelta * down_goldenRatio
                regionSpan.latitudeDelta = mapView.region.span.longitudeDelta * down_goldenRatio
                mapView.region.span = regionSpan
                print("[DBG]latitudeDelta-2 : " + mapView.region.span.latitudeDelta.description)
            }
        myLock.unlock()
    }
    
    //位置情報の取得
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager(); //変数を初期化
        locationManager.delegate = self // delegateとしてself(自インスタンス)を設定
        
        locationManager.startUpdatingLocation() //GPSの使用を開始する
        locationManager.requestWhenInUseAuthorization()// 位置情報取得の許可を得る
        mapView.showsUserLocation = true
        initMap()
        
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:[CLLocation]){
        let longitude = (locations.last?.coordinate.longitude.description)! //軽度
        let latitude = (locations.last?.coordinate.latitude.description)!   //緯度

        print("[DBG]longitude : " + longitude)
        print("[DBG]longitude : " + latitude)
        
        myLock.lock()
        mapView.setCenter((locations.last?.coordinate)!, animated: true) // 現在の位置情報を中心に表示（更新）
        myLock.unlock()
    }
    
    func initMap() {
            // 縮尺を設定
            var region:MKCoordinateRegion = mapView.region
        region.span.latitudeDelta = 0.005
        region.span.longitudeDelta = 0.005
            mapView.setRegion(region,animated:true)

            // 現在位置表示の有効化
            mapView.showsUserLocation = true
            // 現在位置設定（デバイスの動きとしてこの時の一回だけ中心位置が現在位置で更新される）
            mapView.userTrackingMode = .followWithHeading
        }
    


}
