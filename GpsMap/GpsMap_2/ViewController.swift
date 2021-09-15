//
//  ViewController.swift
//  GpsMap_2
//
//  Created by hiroto on 2021/08/12.
//

import UIKit
import CoreLocation //位置情報を取得するためのフレームワーク
import MapKit //地図表示のプログラム

class ViewController: UIViewController , CLLocationManagerDelegate, UITextFieldDelegate, UISearchBarDelegate,MKMapViewDelegate{
    
    // class クラス名:スーパークラス名,プロトコル１,プロトコル
    
    var myLock = NSLock()
    let up_goldenRatio = 1.618
    let down_goldenRatio = 2.0
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet weak var serchBar: UISearchBar!
    var locationManager : CLLocationManager!
    var compassButton : MKCompassButton!
    
    var manager : CLLocationManager = CLLocationManager()
    
    var searchAnnotationArray = [MKPointAnnotation]()
    var searchAnnotationTitleArray = [String]()
    var searchAnnotationLatArray = [String]()
    var searchAnnotationLonArray = [String]()
    
    var userLocation: CLLocationCoordinate2D!
    var destLocation: CLLocationCoordinate2D!
    
    
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
        print("-----------------確認------------")
        
        
    }
    
    
    
    
    //位置情報の取得
    override func viewDidLoad() {
        super.viewDidLoad()
        print("-----------------VIEWDIDLOAD--------------------------------")
        locationManager = CLLocationManager(); //変数を初期化
        
        //ユーザーのトラッキングと向きを出力
        self.mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true)
        
        locationManager.delegate = self // delegateとしてself(自インスタンス)を設定
        
        serchBar.delegate = self
        locationManager.startUpdatingLocation() //GPSの使用を開始する
        locationManager.requestWhenInUseAuthorization()// 位置情報取得の許可を得る
        mapView.showsUserLocation = true //ユーザーの位置を可視化
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation //ナビゲーションアプリのための高い精度と追加のセンサーも使用する
        mapView.delegate = self
        //initMap() //画面の初期設定
        
        self.initMap()
        
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
    
    
    //検索ボタンがクリックされた際の処理内容
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        //キーボードを閉じる。
        serchBar.resignFirstResponder()
        // self.mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true)
        //検索条件を作成する。
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchBar.text
        
        //検索範囲はマップビューと同じにする。
        searchRequest.region = mapView.region
        
        //ローカル検索を実行する。
        let localSerch : MKLocalSearch = MKLocalSearch(request:  searchRequest)
        localSerch.start(completionHandler: LocalSearchCompHandler(response:error:))
        
    }
    
    
    
    
    
    
    
    // start(completionHandler:)の引数
    func LocalSearchCompHandler(response: MKLocalSearch.Response?, error: Error?) -> Void {
        
        //検索バーに何も入力されない時の処理
        if response == nil {
            print("-----------------------検索バーに入力なし-------------------")
            serchBar.resignFirstResponder()
           // self.initMap()
            displaySearch(goalLatitude: locationManager.location!.coordinate.latitude, goalLongitude: locationManager.location!.coordinate.longitude, parm: 1000000)
            return
        }
        
        mapView.removeAnnotations(searchAnnotationArray) //現在刺されているピンの削除
        self.mapView.removeOverlays(self.mapView.overlays) //現在表示されているルートを削除
        
        //検索バーに文字が入力された時の処理
        for searchLocation in (response?.mapItems)! {
            print("-----------------------ピンを表示。----------------------------------")
            
            if error == nil {
                let searchAnnotation = MKPointAnnotation() //ピンの生成
                // ピンの座標
                let center = CLLocationCoordinate2DMake(searchLocation.placemark.coordinate.latitude, searchLocation.placemark.coordinate.longitude) //座標インスタンスの生成
                
                
                //表示範囲の設定
                print("------------------------search-----------------------")
                displaySearch(goalLatitude: searchLocation.placemark.coordinate.latitude, goalLongitude: searchLocation.placemark.coordinate.longitude,parm: 100000)
                
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
    
    
    
    
    //目的地までのルートを取得
    func getRoute(goalCoordinate:CLLocationCoordinate2D!)
    {
        self.mapView.removeOverlays(self.mapView.overlays)
        print("-----------------------ピンを押しました。----------------------------------")
        
        
        
        // 現在地と目的地のMKPlacemarkを生成
        let fromPlacemark = MKPlacemark(coordinate:locationManager.location!.coordinate, addressDictionary:nil)
        print(fromPlacemark)
        let toPlacemark   = MKPlacemark(coordinate:goalCoordinate, addressDictionary:nil)
        print(toPlacemark)
        // MKPlacemark から MKMapItem を生成
        let fromItem = MKMapItem(placemark:fromPlacemark)
        let toItem   = MKMapItem(placemark:toPlacemark)
        
        // MKMapItem をセットして MKDirectionsRequest を生成
        let request = MKDirections.Request()
        
        
        request.source = fromItem
        request.destination = toItem
        request.requestsAlternateRoutes = false // 単独の経路を検索
        request.transportType = MKDirectionsTransportType.any
        
        let directions = MKDirections(request:request)
        
        
        directions.calculate() { response, error in
            
            //   response?.routes.count
            if (error != nil || response!.routes.isEmpty) {
                print(error!)
                return
            }
            print("-------------------------succeed--------------------")
            
            let route: MKRoute = response!.routes[0] as MKRoute
            print("------------------------------")
            print(response!.routes)
            // 経路を描画
            print(route)
            self.mapView.addOverlay(route.polyline)
            print("------------------")
            print(route.polyline)
            
            // 現在地と目的地を含む表示範囲を設定する
            self.showUserAndDestinationOnMap(goalCoordinate:goalCoordinate)
           
            
        }
        
        //displaySearch(goalLatitude: locationManager.location!.coordinate.latitude, goalLongitude: locationManager.location!.coordinate.longitude,parm: 100000)
        
    }
    
    // 地図の表示範囲を計算
    func showUserAndDestinationOnMap(goalCoordinate:CLLocationCoordinate2D!)
    {
        print("-------------地図範囲を出す")
        // 現在地と目的地を含む矩形を計算
        let maxLat:Double = fmax(locationManager.location!.coordinate.latitude,  goalCoordinate.latitude)
        let maxLon:Double = fmax(locationManager.location!.coordinate.longitude, goalCoordinate.longitude)
        let minLat:Double = fmin(locationManager.location!.coordinate.latitude,  goalCoordinate.latitude)
        let minLon:Double = fmin(locationManager.location!.coordinate.longitude, goalCoordinate.longitude)
        
        // 地図表示するときの緯度、経度の幅を計算
        let mapMargin:Double = 1.5;  // 経路が入る幅(1.0)＋余白(0.5)
        let leastCoordSpan:Double = 0.005;    // 拡大表示したときの最大値
        let span_x:Double = fmax(leastCoordSpan, fabs(maxLat - minLat) * mapMargin);
        let span_y:Double = fmax(leastCoordSpan, fabs(maxLon - minLon) * mapMargin);
        
        
        let _:MKCoordinateSpan = MKCoordinateSpan.init(latitudeDelta: span_x, longitudeDelta: span_y);
        
        // 現在地を目的地の中心を計算
        let center:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: (maxLat + minLat) / 2, longitude: (maxLon + minLon) / 2);
        let region:MKCoordinateRegion = MKCoordinateRegion(center:center,latitudinalMeters: 5000,longitudinalMeters: 7500);
        
        mapView.setRegion(mapView.regionThatFits(region), animated:true);
    }
    
   
    
    //仮の表示範囲を出す関数
    func displaySearch(goalLatitude:Double,goalLongitude:Double,parm:Double){
        let userLatitude : Double = locationManager.location!.coordinate.latitude
        let userLongitude : Double = locationManager.location!.coordinate.longitude
        
        let Center:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude : userLatitude , longitude : userLongitude);
        
        let region:MKCoordinateRegion = MKCoordinateRegion(center:Center,latitudinalMeters:fabs((userLatitude-goalLatitude)*parm),longitudinalMeters:fabs((userLongitude-goalLongitude)*parm));
        
        mapView.setRegion(mapView.regionThatFits(region), animated:true);
        
    }
    
  
    
    //ピンがタップされた際の処理
    func mapView(_ mapView:MKMapView, didSelect view: MKAnnotationView){
        
        print(view.annotation!.coordinate)
        print(view.annotation!.title as Any)
        print(view.annotation!.subtitle as Any)
        getRoute(goalCoordinate:view.annotation!.coordinate)
        print("-----------------表示範囲を変更--------------------")
        displaySearch(goalLatitude: view.annotation!.coordinate.latitude, goalLongitude: view.annotation!.coordinate.longitude, parm: 500)
        
    }
    
    // 経路を描画するときの色や線の太さを指定
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let polylineRenderer = MKPolylineRenderer(polyline: polyline)
            polylineRenderer.strokeColor = .blue
            polylineRenderer.lineWidth = 6.0
            return polylineRenderer
        }
        return MKOverlayRenderer()
    }
    
    
    
    
}


