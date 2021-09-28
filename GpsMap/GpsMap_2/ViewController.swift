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
class ViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate, MKMapViewDelegate {
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
    // setting画面遷移のコード
    @IBAction func nextSetting(_ sender: Any) {
        let storyboard: UIStoryboard = self.storyboard!
        // ②遷移先ViewControllerのインスタンス取得
        let nextView = storyboard.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController
        // ③画面遷移
        self.present(nextView!, animated: true, completion: nil)
//        let settingsViewController = self.storyboard?.instantiateViewController(withIdentifier: "settingsViewController") as! SettingsViewController
//        self.present(settingsViewController, animated: true, completion: nil)
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
