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
import SwiftSMTP
import CoreMotion

class ViewController: UIViewController, CLLocationManagerDelegate, UITextFieldDelegate, MKMapViewDelegate {
    var myLock = NSLock()
    @IBOutlet var mapView: MKMapView!
    // 検索バー
    @IBOutlet weak var serchBar = UISearchBar()
    var locationManager: CLLocationManager!
    var compassButton: MKCompassButton!
    var manager: CLLocationManager = CLLocationManager()
    var searchAnnotationArray = [MKPointAnnotation]()
    var searchAnnotationTitleArray = [String]()
    var searchAnnotationLatArray = [String]()
    var searchAnnotationLonArray = [String]()
    var camera: MKMapCamera = MKMapCamera()
    var timer = Timer()
    var step: MKRoute!
    var count = 0
    var currentCoordinate = CLLocationCoordinate2D()
    let speech = AVSpeechSynthesizer()
    var stepCount = 0
    var prevCoordinateInfo: CLLocation? = nil
    // 現在地ボタン
    var currentButton = UIButton()
    let currentImage = UIImage(named: "arrow")
    // 音声テキストボタン
    var micButton = UIButton()
    let micImage = UIImage(named: "mic")
    var voiceStr = ""
    
    // マイクの変数
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    // 衝撃検知関連
    var coreManager = CMMotionManager()
    let altimeter = CMAltimeter()
    var fallFlag = false
    let impactDetection = ImpactDetection()
    var sendMail = SendMail()
    var impactTime = 0
    var accelTime = 0
    
    let directionJudge = DirectionJudge()
    @IBOutlet weak var checkLabel: UILabel!
    
    @IBOutlet weak var fallLabel: UILabel!
    
    // 領域検知用のフラグ
    var regionDetection = RegionDetection()
    var regionFlag = true
    
    // メール
    var domain = ""
    var sendAdress = ""
    var sendPass = ""
    var receiveAdress = ""
    var attentionTime = 0
    var mailFlag = true
    
    // 位置情報の取得
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fallLabel.text = "検知中"
        fallLabel.backgroundColor = .green
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
        serchBar?.delegate = self
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
        locationManager.distanceFilter = 5
        locationManager.allowsBackgroundLocationUpdates = true
        
        mapView.delegate = self
        // 画面の初期設定
        self.initMap()
        // 音声認識の初期化
        speechRecognizer.delegate = self
        
        self.mapView.showsTraffic = true
        // 検索バーのアクセシビリティ
        self.serchBar!.isAccessibilityElement = true
        self.serchBar!.accessibilityLabel = "検索フィールド"
        self.serchBar!.accessibilityHint = "目的地の検索を行う"
        
        // 現在地ボタンを作成
        self.currentButton = UIButton(type: .custom)
        self.currentButton.translatesAutoresizingMaskIntoConstraints = false
        self.currentButton.setImage(self.currentImage, for: .normal)
        self.view.addSubview(currentButton)
        self.currentButton.addTarget(self, action: #selector(self.tapButton(_ :)), for: .touchUpInside)
        self.currentButton.layer.cornerRadius = 40
        
        // 現在地ボタンのオートレイアウトの設定
        self.currentButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -120).isActive = true
        self.currentButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -30).isActive = true
        self.currentButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        self.currentButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        
        // 現在地ボタンのアクセシビリティ
        self.currentButton.isAccessibilityElement = true
        self.currentButton.accessibilityLabel = "現在地を示す"
        self.currentButton.accessibilityHint = "ボタンを押すと音声で現在地を示します。"
        //
        // 音声テキストボタンを作成
        self.micButton = UIButton(type: .custom)
        self.micButton.translatesAutoresizingMaskIntoConstraints = false
        self.micButton.setImage(self.micImage, for: .normal)
        self.view.addSubview(micButton)
        micButton.addTarget(self, action: #selector(self.recordButtonTapped(sender:)), for: .touchUpInside)
        micButton.setTitle("Start Recording", for: [])
        micButton.isEnabled = false
        
        // 音声テキストオートレイアウトの設定
        self.micButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -200).isActive = true
        self.micButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -30).isActive = true
        self.micButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        self.micButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        
        // 音声テキストボタンのアクセシビリティ
        self.micButton.isAccessibilityElement = true
        self.micButton.accessibilityLabel = "音声検索を行う"
        self.micButton.accessibilityHint = "ボタンを押した後、目的地を言ってください。その後、ボタンを再度押すと場所を検索してくれます。"
        
        // ユーザーに音声認識の許可を求める
        SFSpeechRecognizer.requestAuthorization { authStatus in
            
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    // ユーザが音声認識の許可を出した時
                    self.micButton.isEnabled = true
                    
                case .denied:
                    // ユーザが音声認識を拒否した時
                    self.micButton.isEnabled = false
                    self.micButton.setTitle("User denied access to speech recognition", for: .disabled)
                    
                case .restricted:
                    // 端末が音声認識に対応していない場合
                    self.micButton.isEnabled = false
                    self.micButton.setTitle("Speech recognition restricted on this device", for: .disabled)
                    
                case .notDetermined:
                    // ユーザが音声認識をまだ認証していない時
                    self.micButton.isEnabled = false
                    self.micButton.setTitle("Speech recognition not yet authorized", for: .disabled)
                }
            }
            
        }
        
        // 加速度センサーから値の取得
        if coreManager.isAccelerometerAvailable {
            // 加速度センサーの値取得間隔
            coreManager.accelerometerUpdateInterval = 0.1
            
            // motionの取得を開始
            coreManager.startAccelerometerUpdates(to: OperationQueue.current!, withHandler: { (data, error) in
                // 取得した値をコンソールに表示
                self.impactDetection.xAccel = (data?.acceleration.x)!
                self.impactDetection.yAccel = (data?.acceleration.y)!
                self.impactDetection.zAccel = (data?.acceleration.z)!
                
            })
        }
        // ジャイロセンサーから値の取得
        if coreManager.isGyroAvailable {
            // 加速度センサーの値取得間隔
            coreManager.deviceMotionUpdateInterval = 0.1
            
            coreManager.startDeviceMotionUpdates(
                to: OperationQueue.current!,
                withHandler: { deviceManager, error in
                    // オイラー角を取得
                    let attitude: CMAttitude = deviceManager!.attitude
                    self.impactDetection.roll = attitude.roll * 180 / Double.pi
                    self.impactDetection.pitch = attitude.pitch * 180 / Double.pi
                })
        }
        
        // 気圧センサーから値の取得
        if CMAltimeter.isRelativeAltitudeAvailable() {
            
            coreManager.gyroUpdateInterval = 0.1
            
            altimeter.startRelativeAltitudeUpdates(to: OperationQueue.current!, withHandler:
                                                    { data, error in
                if error == nil {
                    self.impactDetection.pressure = Double(truncating: data!.pressure)
                    self.impactDetection.altitude = data?.relativeAltitude as! Double
                    //                    print("pressure: \(self.pressure), altitude: \(self.altitude)")
                }
            })
        } else {
            print("not use altimeter")
        }
        
    }
    
    @objc func tapButton(_ sender: UIButton){
        self.mapView.userTrackingMode = .followWithHeading
        let location = CLLocation(latitude: self.currentCoordinate.latitude, longitude: self.currentCoordinate.longitude)
        
        print("現在のカウント\(self.stepCount)")
        if self.step != nil{
            print("経路情報のカウント\(self.step.steps.count)")
        } else {
            print("経路情報なし")
        }
        
        print("\(self.domain)/ \(self.sendAdress)/ \(self.sendPass)/ \(self.receiveAdress)")
    
                CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
                    guard let placemark = placemarks?.first, error == nil else { return }
                    let message = placemark.name
                    let speechUtterance = AVSpeechUtterance(string: message!)
                    self.speech.speak(speechUtterance)
                }
    }
    
    // アプリへの場所関連イベントの配信を開始および停止するために使用する
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else { return }
        let message = "位置情報を取得中"
        let speechUtterance = AVSpeechUtterance(string: message)
        let age = -location.timestamp.timeIntervalSinceNow
        
        if age > 10 {
            print("古い位置情報です")
            
            self.speech.speak(speechUtterance)
            return
        }
        
        if location.horizontalAccuracy < 0 {
            print("error0:無効な位置情報です。")
            
            self.speech.speak(speechUtterance)
            return
        }
        
        if location.horizontalAccuracy > 70 {
            print("error100:無効な位置情報です。")
            
            self.speech.speak(speechUtterance)
            return
        }
        
        print(location.horizontalAccuracy)
        
        // 到着予定時間を過ぎたら一度だけ実行される関数
        if self.stepCount != 0 {
            //            Timer.scheduledTimer(timeInterval: self.step.expectedTravelTime, target: self, selector: #selector(), userInfo: nil, repeats: false)
            let date = Date()
            print("---------------------")
            if attentionTime == 0 {
                self.attentionTime = Int(date.timeIntervalSince1970)
            }
            
            print("timer:\((Int(date.timeIntervalSince1970) - self.attentionTime))")
            print("expect:\(self.step.expectedTravelTime)")
            
            if (Int(date.timeIntervalSince1970) - self.attentionTime) > Int(self.step.expectedTravelTime) && mailFlag == true {
                sendMail.sendAttentionMail(coordinate: self.currentCoordinate, domain: self.domain, sendAdress: self.sendAdress, pass: self.sendPass, toAdress: self.receiveAdress)
                mailFlag = false
            }
            
        } else {
            self.attentionTime = 0
            mailFlag = true
        }
        
        self.currentCoordinate.latitude = location.coordinate.latitude
        self.currentCoordinate.longitude = location.coordinate.longitude
        
        if self.step == nil {
            return
        }
        
        // 到着時のアナウンス
        print("count: \(self.step.steps.count), selfCount: \(self.stepCount)")
        if self.step.steps.count == self.stepCount {
            self.stepCount = 0
            let message = "到着しました。お疲れさまでした。"
            let speechUtterance = AVSpeechUtterance(string: message)
            self.speech.speak(speechUtterance)
            // 現在刺されているピンの削除
            mapView.removeAnnotations(searchAnnotationArray)
            // 現在表示されているルートを削除
            self.mapView.removeOverlays(self.mapView.overlays)
            sendMail.sendArrivedMail(text: voiceStr, domain: self.domain, sendAdress: self.sendAdress, pass: self.sendPass, toAdress: self.receiveAdress)
            self.step = nil
            return
        }
        
        let nextLocation = self.step.steps[self.stepCount]
        print(self.regionFlag)
        
        print(regionDetection.distance(current: (self.currentCoordinate.latitude,self.currentCoordinate.longitude), target: (nextLocation.polyline.coordinate.latitude,nextLocation.polyline.coordinate.longitude)))
        
        // 領域の判定
        if self.regionFlag {
            
            self.regionFlag = regionDetection.regionTrueJudge(userLocation: self.currentCoordinate, targetLocation: nextLocation.polyline.coordinate)
            
            if self.regionFlag == false {
                
                let message = "まもなく \(nextLocation.instructions)　です。"
                print("領域内に侵入：\(message)")
                print(self.stepCount)
                let speechUtterance = AVSpeechUtterance(string: message)
                self.speech.speak(speechUtterance)
                
                self.stepCount += 1
            }
            
            return
            
        } else {
            
            if self.stepCount == 0 {
                return
            }
            
            self.regionFlag = regionDetection.regionFalseJudge(userLocation: self.currentCoordinate, targetLocation: self.step.polyline.coordinate)
            
            if self.regionFlag == true {
                let preLocation = self.step.steps[self.stepCount - 1]
                let message = "\(preLocation.instructions)です。その先、\(Int(nextLocation.distance))メートル先\(nextLocation.instructions)　です。"
                print("領域外に出る：\(message)")
                print(self.stepCount)
                let speechUtterance = AVSpeechUtterance(string: message)
                self.speech.speak(speechUtterance)
                
            }
            
            return
            
        }
        
    }
    
    // 磁気センサからユーザーの角度を取得
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // ユーザの向いている方向
        _ = directionJudge.degToRad(degrees: (self.mapView.camera.heading))
        let date = Date()
        
        if self.stepCount != 0 && self.mapView.userTrackingMode == .followWithHeading {
            if self.step.steps.count == self.stepCount {
                print("注意喚起機能を終了")
                return
            }
            let nextLocation = self.step.steps[self.stepCount]
            let targetRadian = directionJudge.angle(coordinate: self.currentCoordinate, coordinate2: nextLocation.polyline.coordinate)
            
            print("現在の位置座標\(self.currentCoordinate)")
            print("目標地点の座標\(self.step.steps[self.stepCount].polyline.coordinate)")
            print("ユーザの角度: \(self.mapView.camera.heading)  目標角度: \(targetRadian)")
            self.checkLabel.text = "ユーザ:\(Int(self.mapView.camera.heading))目標角度:\(Int(targetRadian))Count:\(self.stepCount)"
            
            if targetRadian + directionJudge.setAngle > 360.0 || targetRadian - directionJudge.setAngle < 0 {
                
                directionJudge.compareAngle(targetRadian: targetRadian, userRadian: self.mapView.camera.heading)
                
            } else {
                
                directionJudge.compareAngle2(targetRadian: targetRadian, userRadian: self.mapView.camera.heading)
                
            }
            
        }
        
        // 加速度の判定を行う
        fallFlag = self.impactDetection.fallDetectionAccel()
        if fallFlag == true && self.accelTime == 0 {
            self.accelTime = Int(date.timeIntervalSince1970)
        }
        
        if fallFlag == false {
            fallLabel.text = "accel: 異常なし"
            self.accelTime = 0
            return
        }
        
        if self.accelTime + 2 <= Int(date.timeIntervalSince1970) && self.accelTime != 0 {
        // ジャイロセンサの判定を行う
        fallFlag = self.impactDetection.fallDetectionGyro()
        
        if fallFlag {
                        print("Gyro: \(fallFlag)")
        } else {
            fallLabel.text = "Gyro: 異常なし"
            return
        }
        // 気圧の判定を行う
        fallFlag = self.impactDetection.fallDetectionPressure()
        
        if fallFlag {
            
            if (Int(date.timeIntervalSince1970) - impactTime) < 60 {
                return
            }
            
            // フラグの判定を元にメールを送るか否か判定する関数
            print("pressure: \(fallFlag)")
            fallFlag = false
            print("--------\(fallFlag)--------")
            sendMail.sendFallMail(coordinate: self.currentCoordinate, domain: self.domain, sendAdress: self.sendAdress, pass: self.sendPass, toAdress: self.receiveAdress)
            impactTime = Int(date.timeIntervalSince1970)
            fallLabel.text = "！！異常検知！！"
            
            return
        } else {
            fallLabel.text = "pressure: 異常なし"
            return
        }
        }
        
    }
    
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
    
    @IBAction func settingsButtonAction(_ sender: Any) {
        let settingsViewController = self.storyboard?.instantiateViewController(withIdentifier: "settingsViewController") as! SettingsViewController
        self.present(settingsViewController, animated: true, completion: nil)
    }
    
    // 録音ボタンが押されたら呼ばれる
    @objc func recordButtonTapped(sender: UIButton) {
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            micButton.isEnabled = false
            micButton.setTitle("Stopping", for: .disabled)
            
            // 録音が停止した！
            print("録音停止")
            
            let avSession = AVAudioSession.sharedInstance()
            try? avSession.setCategory(.ambient)
            
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = self.voiceStr
            self.stepCount = 0
            self.regionFlag = true
            
            // 検索範囲はマップビューと同じにする。
            searchRequest.region = mapView.region
            // ローカル検索を実行する。
            let localSerch: MKLocalSearch = MKLocalSearch(request: searchRequest)
            localSerch.start(completionHandler: localSearchCompHandler(response:error:))
            
            let message = "\(self.voiceStr)を検索しました。"
            let speechUtterance = AVSpeechUtterance(string: message)
            self.speech.speak(speechUtterance)
            
        } else {
            try? startRecording()
            micButton.setTitle("Stop recording", for: [])
            
        }
    }
    
    // 録音を開始する
    private func startRecording() throws {
        
        // Cancel the previous task if it's running.
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(AVAudioSession.Category.record)
        try audioSession.setMode(AVAudioSession.Mode.measurement)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            var isFinal = false
            
            if let result = result {
                // 音声認識の区切りの良いところで実行される。
                self.voiceStr = result.bestTranscription.formattedString
                print(result.bestTranscription.formattedString)
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.micButton.isEnabled = true
                self.micButton.setTitle("Start Recording", for: [])
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        try audioEngine.start()
    }
    
    // speechRecognizerが使用可能かどうかでボタンのisEnabledを変更する
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            micButton.isEnabled = true
            micButton.setTitle("Start Recording", for: [])
            
        } else {
            micButton.isEnabled = false
            micButton.setTitle("Recognition not available", for: .disabled)
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
