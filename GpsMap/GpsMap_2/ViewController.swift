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
import AVFoundation
import AudioToolbox

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
    var timer = Timer()
    var step: MKRoute!
    var userCurrentLocation: [CLLocation]!
    var currentCoordinate: CLLocationCoordinate2D!
    let speech = AVSpeechSynthesizer()
    var stepCount = 0
    var prevCoordinateInfo: CLLocation? = nil
    
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
//        let longitude = (locations.last?.coordinate.longitude)!
//        let latitude = (locations.last?.coordinate.latitude)!
        
        if prevCoordinateInfo == nil {
            prevCoordinateInfo = locations.last
            print("位置情報\(prevCoordinateInfo)")
            return
        }
        if self.step == nil {
            return
        }
            // 現在地から次の地点までの目標角度
        print("count: \(self.step.steps.count)")
        if self.step.steps.count == self.stepCount {
            self.stepCount = 0
            let message = "到着しました。"
            let speechUtterance = AVSpeechUtterance(string: message)
            self.speech.speak(speechUtterance)
            return
        }
        
        let nextLocation = self.step.steps[self.stepCount]
        let targetRadian = self.angle(coordinate: locations.last!.coordinate, coordinate2: nextLocation.polyline.coordinate)
            
        // 実際に移動した角度
        let userRadian = self.angle(coordinate: prevCoordinateInfo!.coordinate, coordinate2: locations.last!.coordinate)
                // 比較の計算
                if userRadian > (targetRadian + 20) || userRadian < (targetRadian - 20) {

                    let message = "方向が違います。確認してください。"
                    print("違う")
                    let speechUtterance = AVSpeechUtterance(string: message)
                    self.speech.speak(speechUtterance)
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))

                }
        
        
    }
    // 磁気センサからユーザーの角度を取得
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // ユーザの向いている方向
        _ = self.degToRad(degrees: (self.mapView.camera.heading))
        print("カメラ角度")
        print(mapView.camera.heading)
        print("-------------------------------------")
    }
    
    // 角度に関する関数
    func rotateManager(heading: CLLocationDirection) {
        self.mapView.camera.heading = heading
    }
    
    // 角度をラジアンに変換する
    func degToRad(degrees: CGFloat) -> CGFloat {
        return degrees * CGFloat.pi / 180
    }
    
    // 各位を計算
    func angle(coordinate: CLLocationCoordinate2D, coordinate2: CLLocationCoordinate2D) -> Float {
        let currentLatitude     = degToRad(degrees: coordinate.latitude)
        let currentLongitude    = degToRad(degrees: coordinate.longitude)
        let targetLatitude      = degToRad(degrees: coordinate2.latitude)
        let targetLongitude     = degToRad(degrees: coordinate2.longitude)
        
        let difLongitude = targetLongitude - currentLongitude
        let y = sin(difLongitude)
        let x = cos(currentLatitude) * tan(targetLatitude) - sin(currentLatitude) * cos(difLongitude)
        let p = atan2(y, x) * 180 / CGFloat.pi
        
        if p < 0 {
            return Float(360 + atan2(y, x) * 180 / CGFloat.pi)
        }
        return Float(atan2(y, x) * 180 / CGFloat.pi)
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
//    @IBAction func nextSetting(_ sender: Any) {
//        let storyboard: UIStoryboard = self.storyboard!
//         // ②遷移先ViewControllerのインスタンス取得
//        let nextView = storyboard.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController
//        // ③画面遷移
//       self.present(nextView!, animated: true, completion: nil)
//        let nextVC = storyboard.instantiateViewController(withIdentifier: "SettingsViewController") as? SettingsViewController
//        navigationController?.pushViewController(nextVC! as UIViewController, animated: true)
//    }
    @IBAction func settingsButtonAction(_ sender: Any) {
        let settingsViewController = self.storyboard?.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
        self.present(settingsViewController, animated: true, completion: nil)
    }
    
    // 領域内に侵入した時
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        if self.step == nil {
            return
        }
        
        print("Enter \(self.stepCount)")
        
        if self.stepCount < self.step.steps.count {
            let currentStep = self.step.steps[stepCount]
            let message = "まもなく \(currentStep.instructions)　です。"
            let speechUtterance = AVSpeechUtterance(string: message)
            self.speech.speak(speechUtterance)
            self.stepCount += 1
        } else {
            let message = "到着しました。"
            let speechUtterance = AVSpeechUtterance(string: message)
            self.speech.speak(speechUtterance)
            
            stepCount = 0
            
            locationManager.monitoredRegions.forEach ({ self.locationManager.stopMonitoring(for: $0)})
        }
    }
    
    // 領域外に外れた時
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if self.step == nil {
            return
        }
        print("Enter \(self.stepCount)")
        
        if self.stepCount < self.step.steps.count { 
            let currentStep = self.step.steps[stepCount]
            let message = "\(round(currentStep.distance)) メートル先, \(currentStep.instructions)　です。"
            let speechUtterance = AVSpeechUtterance(string: message)
            self.speech.speak(speechUtterance)
        } else {
            let message = "到着しました。"
            let speechUtterance = AVSpeechUtterance(string: message)
            self.speech.speak(speechUtterance)
            
            stepCount = 0
            
            locationManager.monitoredRegions.forEach ({ self.locationManager.stopMonitoring(for: $0)})
        }
        
    }
}
    // マイクに関する処理
extension ViewController: SFSpeechRecognizerDelegate {
    // 認証の処理（ここで関数が呼び出されている）
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}
