//
//  ViewController.swift
//  GpsMap_2
//
//  Created by hiroto on 2021/08/12.
//

import UIKit
import CoreLocation
import MapKit //地図表示のプログラム

class ViewController: UIViewController , CLLocationManagerDelegate{
    var myLock = NSLock()
    let goldenRatio = 1.618
    
    @IBOutlet var mapView: MKMapView!
    var locationManager : CLLocationManager!
    
    
    //拡大のボタン
    @IBAction func ZoomIn(_ sender: Any) {
        print("[DBG]clickZoomin")
        myLock.lock()
        if (0.005 < mapView.region.span.latitudeDelta / goldenRatio) {
                print("[DBG]latitudeDelta-1 : " + mapView.region.span.latitudeDelta.description)
                var regionSpan:MKCoordinateSpan = MKCoordinateSpan()
                regionSpan.latitudeDelta = mapView.region.span.latitudeDelta / goldenRatio
                mapView.region.span = regionSpan
                print("[DBG]latitudeDelta-2 : " + mapView.region.span.latitudeDelta.description)
        }
        myLock.unlock()
    }
    
    
    //縮小のボタン
    @IBAction func ZoomOut(_ sender: Any) {
        print("[DBG]clickZoomout")
        myLock.lock()
        if (mapView.region.span.latitudeDelta * goldenRatio < 150.0) {
                print("[DBG]latitudeDelta-1 : " + mapView.region.span.latitudeDelta.description)
                var regionSpan:MKCoordinateSpan = MKCoordinateSpan()
                regionSpan.latitudeDelta = mapView.region.span.latitudeDelta * goldenRatio
        regionSpan.latitudeDelta = mapView.region.span.longitudeDelta * goldenRatio
                mapView.region.span = regionSpan
                print("[DBG]latitudeDelta-2 : " + mapView.region.span.latitudeDelta.description)
            }
        myLock.unlock()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        locationManager = CLLocationManager(); //変数を初期化
        locationManager.delegate = self
        
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
        mapView.showsUserLocation = true
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations:[CLLocation]){
        let longitude = (locations.last?.coordinate.longitude.description)!
        let latitude = (locations.last?.coordinate.latitude.description)!

        print("[DBG]longitude : " + longitude)
        print("[DBG]longitude : " + latitude)
        
        myLock.lock()
        mapView.setCenter((locations.last?.coordinate)!, animated: true) // 現在の位置情報を中心に表示（更新）
        myLock.unlock()
    }
    


}
