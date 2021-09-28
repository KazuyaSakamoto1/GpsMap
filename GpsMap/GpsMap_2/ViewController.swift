//
//  ViewController.swift
//  GpsMap_2
//
//  Created by hiroto on 2021/08/12.
//

import UIKit
//　位置情報を取得するためのフレームワーク
import CoreLocation
// 地図表示のプログラム
import MapKit
//　音声用のフレームワーク
import Speech
// class クラス名:スーパークラス名,プロトコル１,プロトコル
class ViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate, UISearchBarDelegate, MKMapViewDelegate {
    var myLock = NSLock()
    @IBOutlet var mapView: MKMapView!
    @IBOutlet weak var serchBar: UISearchBar!
    var locationManager: CLLocationManager!
    var compassButton: MKCompassButton!
    var manager: CLLocationManager = CLLocationManager()
    var searchAnnotationArray = [MKPointAnnotation]()
    var searchAnnotationTitleArray = [String]()
    var searchAnnotationLatArray = [String]()
    var searchAnnotationLonArray = [String]()
    var userLocation: CLLocationCoordinate2D!
    var destLocation: CLLocationCoordinate2D!
    var camera: MKMapCamera = MKMapCamera()
    var count = 0
    @IBAction func mapChangeButton(_ sender: Any) {
        count += 1
        switch count%5 {
        case 0:
            self.mapView.mapType = .standard
        case 1:
            self.mapView.mapType = .hybrid
        case 2:
            self.mapView.mapType = .satellite
        case 3:
            self.mapView.mapType = .hybridFlyover
        case 4:
            self.mapView.mapType = .satelliteFlyover
        default:
            print("ERROR")
        }
    }
    // 現在地ボタン
    @IBOutlet weak var currentLocation: UIImageView!
    @IBAction func currentLocationButton(_ sender: Any) {
        self.mapView.userTrackingMode = .followWithHeading
    }
    // マイクの変数
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    // 位置情報の取得
    override func viewDidLoad() {
        super.viewDidLoad()
        // 変数を初期化
        locationManager = CLLocationManager()
        camera = MKMapCamera()
        // ユーザーのトラッキングと向きを出力
        self.mapView.userTrackingMode = .followWithHeading
        print(self.mapView.userTrackingMode)
        // delegateとしてself(自インスタンス)を設定
        locationManager.delegate = self
        // 何度動いたら更新するか（デフォルトは1度）
        locationManager.headingFilter = kCLHeadingFilterNone
//        locationManager.headingOrientation = CLDeviceOrientation
        serchBar.delegate = self
        // GPSの使用を開始する
        locationManager.startUpdatingLocation()
        // 位置情報取得の許可を得る
        locationManager.requestWhenInUseAuthorization()
        // ユーザーの位置を可視化
        mapView.showsUserLocation = true
        // ヘディングイベントの開始
        locationManager.startUpdatingHeading()
        // ナビゲーションアプリのための高い精度と追加のセンサーも使用する
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        mapView.delegate = self
        // 画面の初期設定
        self.initMap()
        speechRecognizer.delegate = self // マイクのデリゲード
        self.mapView.showsTraffic = true
    }

    // アプリへの場所関連イベントの配信を開始および停止するために使用する
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let longitude = (locations.last?.coordinate.longitude.description)! // 経度
        let latitude = (locations.last?.coordinate.latitude.description)!   // 緯度
        print("[DBG]longitude : " + longitude)
        print("[DBG]longitude : " + latitude)
    }
//    // 磁気センサからユーザーの角度を取得
//    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
//        let camera: MKMapCamera = self.mapView.camera
//        camera.heading = newHeading.magneticHeading
//        print("カメラ角度")
//        print(mapView.camera.heading)
//        print("-------------------------------------")
//        print(self.mapView.userTrackingMode)
//        self.mapView.setCamera(camera, animated: true)
//    }
    // 角度に関する関数
    func rotateManager(heading: CLLocationDirection) {
        self.mapView.camera.heading = heading
    }
    // 画面の初期位置の設定
    func initMap() {
        // 縮尺を設定
        var region: MKCoordinateRegion = mapView.region
        region.span.latitudeDelta = 0.005
        region.span.longitudeDelta = 0.005
        mapView.setRegion(region, animated: true)
    }
    // 検索ボタンがクリックされた際の処理内容
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // トラッキングモードを無効化
        self.mapView.userTrackingMode = .none
        // 現在表示されているルートを削除
        self.mapView.removeOverlays(self.mapView.overlays)
        // キーボードを閉じる。
        serchBar.resignFirstResponder()
        // 検索条件を作成する。
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchBar.text
        // 検索範囲はマップビューと同じにする。
        searchRequest.region = mapView.region
        // ローカル検索を実行する。
        let localSerch: MKLocalSearch = MKLocalSearch(request: searchRequest)
        localSerch.start(completionHandler: localSearchCompHandler(response:error:))
    }
    // start(completionHandler:)の引数
    func localSearchCompHandler(response: MKLocalSearch.Response?, error: Error?) -> Void {
        // 検索バーに何も入力されない時の処理
        if response == nil {
            serchBar.resignFirstResponder()
            return
        }
        // 現在刺されているピンの削除
        mapView.removeAnnotations(searchAnnotationArray)
        // 現在表示されているルートを削除
        self.mapView.removeOverlays(self.mapView.overlays)
        // 緯度と軽度の情報を格納する配列
        var longitude: [Double] = []
        var latitude: [Double] = []
        // 検索バーに文字が入力された時の処理
        for searchLocation in (response?.mapItems)! {
            if error == nil {
                let searchAnnotation = MKPointAnnotation() // ピンの生成
                // ピンの座標
                // 座標インスタンスの生成
                let center = CLLocationCoordinate2DMake(searchLocation.placemark.coordinate.latitude, searchLocation.placemark.coordinate.longitude)
                let lat = searchLocation.placemark.coordinate.latitude
                let long = searchLocation.placemark.coordinate.longitude
                // 表示範囲の設定
                searchAnnotation.coordinate = center // ピンに座標を代入
                //  タイトルに場所の名前を表示
                searchAnnotation.title = searchLocation.placemark.name
                // ピンを立てる
                mapView.addAnnotation(searchAnnotation)
                // 配列にピンをセット
                searchAnnotationArray.append(searchAnnotation)
                // 配列に場所の名前をセット
                searchAnnotationTitleArray.append(searchAnnotation.title ?? "")
                // 緯度と経度の座標を格納
                longitude.append(long)
                latitude.append(lat)
                if longitude.count == 13 && latitude.count == 13 {
                    break
                }
            } else {
                print("error")
            }
        }
        var minLat: Double = 9999.0
        var maxLat: Double = -9999.0
        var minLong: Double = 9999.0
        var maxLong: Double = -9999.0
        for long in longitude {
            // 経度の最大最小を求める
            if minLong > long {
                minLong = long
            }
            if maxLong < long {
                maxLong = long
            }
        }
        for lat in latitude {
            // 緯度の最大最小を求める
            if minLat > lat {
                minLat = lat
            }
            if lat > maxLat {
                maxLat = lat
            }
        }
        let point: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: (maxLat + minLat)/2, longitude: (maxLong + minLong)/2)
        let region: MKCoordinateRegion = MKCoordinateRegion(center: point, latitudinalMeters: fabs((maxLat-minLat)), longitudinalMeters: fabs((maxLong-minLong))*100000)
        // 横・縦
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    // 目的地までのルートを取得
    func getRoute(goalCoordinate: CLLocationCoordinate2D!) {
        self.mapView.removeOverlays(self.mapView.overlays)
        // 現在地と目的地のMKPlacemarkを生成
        let fromPlacemark = MKPlacemark(coordinate: locationManager.location!.coordinate, addressDictionary: nil)
        let toPlacemark   = MKPlacemark(coordinate: goalCoordinate, addressDictionary: nil)
        // MKPlacemark から MKMapItem を生成
        let fromItem = MKMapItem(placemark: fromPlacemark)
        let toItem   = MKMapItem(placemark: toPlacemark)
        // MKMapItem をセットして MKDirectionsRequest を生成
        let request = MKDirections.Request()
        request.source = fromItem
        request.destination = toItem
        request.requestsAlternateRoutes = false // 単独の経路を検索
        request.transportType = MKDirectionsTransportType.walking
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            //   response?.routes.count
            if error != nil || response!.routes.isEmpty {
                print(error!)
                return
            }
            print("-------------------------succeed--------------------")
            let route: MKRoute = response!.routes[0] as MKRoute
            // 経路を描画
            self.mapView.addOverlay(route.polyline)
            // 現在地と目的地を含む表示範囲を設定する
            self.displaySearch2(goalLatitude: goalCoordinate!.latitude, goalLongitude: goalCoordinate!.longitude, parm: 250000)
        }
    }
    // 検索後の表示範囲を出す関数(ユーザー中心)
    func displaySearch(goalLatitude: Double, goalLongitude: Double, parm: Double) {
        let userLatitude: Double = locationManager.location!.coordinate.latitude
        let userLongitude: Double = locationManager.location!.coordinate.longitude
        let point: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: userLatitude, longitude: userLongitude)
        let region: MKCoordinateRegion = MKCoordinateRegion(center: point, latitudinalMeters: fabs((userLatitude-goalLatitude)*parm), longitudinalMeters: fabs((userLongitude-goalLongitude)*parm))
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    // 目的地をタップ後の表示範囲を出す関数(ユーザーと目的地の中央)
    func displaySearch2(goalLatitude: Double, goalLongitude: Double, parm: Double) {
        let userLatitude: Double = locationManager.location!.coordinate.latitude
        let userLongitude: Double = locationManager.location!.coordinate.longitude
        let point: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: (userLatitude + goalLatitude)/2, longitude: (userLongitude + goalLongitude)/2)
        let region: MKCoordinateRegion = MKCoordinateRegion(center: point, latitudinalMeters: fabs((userLatitude-goalLatitude)*parm), longitudinalMeters: fabs((userLongitude-goalLongitude)*parm))
            mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    // ピンがタップされた際の処理
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        getRoute(goalCoordinate: view.annotation!.coordinate)
        displaySearch(goalLatitude: view.annotation!.coordinate.latitude, goalLongitude: view.annotation!.coordinate.longitude, parm: 500)
        self.mapView.userTrackingMode = .followWithHeading
    }
    // 経路を描画するときの色や線の太さを指定
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let polylineRenderer = MKPolylineRenderer(polyline: polyline)
            polylineRenderer.strokeColor = .blue
            polylineRenderer.lineWidth = 4.0
            return polylineRenderer
        }
        return MKOverlayRenderer()
    }
    // setting画面遷移のコード
    @IBAction func nextSetting(_ sender: Any) {
        let storyboard: UIStoryboard = self.storyboard!
        // ②遷移先ViewControllerのインスタンス取得
        let nextView = storyboard.instantiateViewController(withIdentifier: "settingID") as? Setting
        // ③画面遷移
        self.present(nextView!, animated: true, completion: nil)
    }
}
// マイクに関する処理
extension ViewController: SFSpeechRecognizerDelegate {
    // 認証の処理（ここで関数が呼び出されている）
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // requestRecognizerAuthorization()
    }
}
