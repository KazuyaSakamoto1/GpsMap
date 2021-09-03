//
//  ViewController.swift
//  GpsMap_2
//
//  Created by hiroto on 2021/08/12.
//

import UIKit
import CoreLocation //位置情報を取得するためのフレームワーク
import MapKit //地図表示のプログラム

class ViewController: UIViewController , CLLocationManagerDelegate, UITextFieldDelegate, UISearchBarDelegate{
    
    // class クラス名:スーパークラス名,プロトコル１,プロトコル
    
    var myLock = NSLock()
    let up_goldenRatio = 1.618
    let down_goldenRatio = 2.0
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet weak var serchBar: UISearchBar!
    var locationManager : CLLocationManager!
   
    var manager : CLLocationManager = CLLocationManager()
    
    var searchAnnotationArray = [MKPointAnnotation]()
    var searchAnnotationTitleArray = [String]()
    var searchAnnotationLatArray = [String]()
    var searchAnnotationLonArray = [String]()
    
    //画面の初期位置の設定
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
        
        serchBar.delegate = self
        locationManager.startUpdatingLocation() //GPSの使用を開始する
        locationManager.requestWhenInUseAuthorization()// 位置情報取得の許可を得る
        mapView.showsUserLocation = true //ユーザーの位置を可視化
        
        initMap() //画面の初期設定
        
    
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

    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        //キーボードを閉じる。
        serchBar.resignFirstResponder()
        
        //検索条件を作成する。
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchBar.text
        
        //検索範囲はマップビューと同じにする。
        searchRequest.region = mapView.region
        
        //ローカル検索を実行する。
        let localSerch : MKLocalSearch = MKLocalSearch(request:  searchRequest)
        localSerch.start(completionHandler: LocalSearchCompHandler(response:error:))
            
        }
        

    func LocalSearchCompHandler(response: MKLocalSearch.Response?, error: Error?) -> Void {
        
        mapView.removeAnnotations(searchAnnotationArray)
        
        for searchLocation in (response?.mapItems)! {
            
            
            if error == nil {
                let searchAnnotation = MKPointAnnotation() //ピンの生成
                // ピンの座標
                let center = CLLocationCoordinate2DMake(searchLocation.placemark.coordinate.latitude, searchLocation.placemark.coordinate.longitude) //座標インスタンスの生成
                searchAnnotation.coordinate = center // ピンに座標を代入

               //  タイトルに場所の名前を表示
                searchAnnotation.title = searchLocation.placemark.name
                // ピンを立てる
                mapView.addAnnotation(searchAnnotation)

                // 配列にピンをセット
                searchAnnotationArray.append(searchAnnotation)
                // 配列に場所の名前をセット
                searchAnnotationTitleArray.append(searchAnnotation.title ?? "")

            } else {
                print("error")
            }
            
        }
    
        
        
    }
    
    
        
    
    
    


}
