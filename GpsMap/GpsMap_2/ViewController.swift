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
    
    let directionJudge = DirectionJudge()
    
    
    @IBOutlet weak var fallLabel: UILabel!
    
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
        self.currentButton.layer.cornerRadius = 25
        
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
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else { return }
            let message = placemark.name
            let speechUtterance = AVSpeechUtterance(string: message!)
            self.speech.speak(speechUtterance)
        }
    }
    
    // アプリへの場所関連イベントの配信を開始および停止するために使用する
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var Flag: Bool = false
        guard let location = locations.first else { return }
        
        // 到着予定時間を過ぎたら一度だけ実行される関数
        if self.step != nil {
            Timer.scheduledTimer(timeInterval: self.step.expectedTravelTime, target: self, selector: #selector(sendMail.sendAttentionMail(_:)), userInfo: nil, repeats: false)
        }
        
        self.currentCoordinate.latitude = location.coordinate.latitude
        self.currentCoordinate.longitude = location.coordinate.longitude
//        print("緯度：\(self.currentCoordinate.longitude)")
//        print("経度：\(self.currentCoordinate.latitude)")
        
        if prevCoordinateInfo == nil {
            prevCoordinateInfo = locations.last
            print("位置情報\(String(describing: prevCoordinateInfo))")
            return
        }
        
        if self.step == nil {
            return
        }
    
        // 位置座標が変更していないとき
        if prevCoordinateInfo?.coordinate.latitude == currentCoordinate.latitude && prevCoordinateInfo?.coordinate.longitude == currentCoordinate.longitude {
            print("位置座標が変わってません")
            return
        }
    
        // 到着時のアナウンス
        print("到着：count: \(self.step.steps.count)")
        if self.step.steps.count == self.stepCount {
            self.stepCount = 0
            let message = "到着しました。お疲れさまでした。"
            let speechUtterance = AVSpeechUtterance(string: message)
            self.speech.speak(speechUtterance)
            // 現在刺されているピンの削除
            mapView.removeAnnotations(searchAnnotationArray)
            // 現在表示されているルートを削除
            self.mapView.removeOverlays(self.mapView.overlays)
            sendMail.sendArrivedMail(text: self.voiceStr)
            self.step = nil
            return
        }
        
        let nextLocation = self.step.steps[self.stepCount]
        // 目標角度
        let targetRadian = directionJudge.angle(coordinate: prevCoordinateInfo!.coordinate, coordinate2: nextLocation.polyline.coordinate)
        let targetRadian2 = directionJudge.angle(coordinate: nextLocation.polyline.coordinate, coordinate2: prevCoordinateInfo!.coordinate)
        // 実際に移動した角度
        let userRadian = directionJudge.angle(coordinate: prevCoordinateInfo!.coordinate, coordinate2: locations.last!.coordinate )
        let userRadian2 = directionJudge.angle(coordinate: locations.last!.coordinate, coordinate2: prevCoordinateInfo!.coordinate)
        
        print("前回の位置座標\(prevCoordinateInfo!.coordinate)")
        print("現在の位置座標\(locations.last!.coordinate)")
        print("目標地点の座標\(self.step.steps[self.stepCount].polyline.coordinate)")
        print("ユーザの角度: \(userRadian)  目標角度: \(targetRadian)")
        print("ユーザの角度: \(userRadian2)  目標角度: \(targetRadian2)")
        
        if userRadian == targetRadian {
            print("位置が動いてません")
            return
        }
        
        // 角度の評価を行う
        if targetRadian - directionJudge.setAngle < 0 || targetRadian + directionJudge.setAngle > 360 {
            
           Flag = Flag || directionJudge.compareAngle(targetRadian: targetRadian, userRadian: userRadian)
           Flag = Flag || directionJudge.compareAngle(targetRadian: userRadian, userRadian: targetRadian)
        } else {
            
           Flag = Flag || directionJudge.compareAngle2(targetRadian: targetRadian, userRadian: userRadian)
           Flag = Flag || directionJudge.compareAngle(targetRadian: userRadian, userRadian: targetRadian)
        }
        
        if targetRadian2 - directionJudge.setAngle < 0 || targetRadian2 + directionJudge.setAngle > 360 {
            
           Flag = Flag || directionJudge.compareAngle(targetRadian: targetRadian2, userRadian: userRadian2)
            Flag = Flag || directionJudge.compareAngle(targetRadian: userRadian2, userRadian: targetRadian2)
        } else {
            
           Flag = Flag || directionJudge.compareAngle2(targetRadian: targetRadian2, userRadian: userRadian2)
           Flag = Flag || directionJudge.compareAngle2(targetRadian: userRadian2, userRadian: targetRadian2)
        }
        
        // 距離の評価を行う
        let currentDistance = self.distance(current: ( currentCoordinate.latitude, currentCoordinate.longitude), target: (nextLocation.polyline.coordinate.latitude, nextLocation.polyline.coordinate.longitude))
        var targetDistance = nextLocation.distance
        
        if currentDistance > targetDistance + 5.0 {
            Flag = false
            targetDistance = currentDistance
        }
        
        print("現在地から次地点までの距離\(currentDistance)")
        print("予測距離\(targetDistance)")
        
        // 判定を行う
        if Flag {
            print("正しい")
        } else {
            let message = "方向が違います。確認してください。"
            print("違う")
            let speechUtterance = AVSpeechUtterance(string: message)
            self.speech.speak(speechUtterance)
            AudioServicesPlaySystemSound(UInt32(kSystemSoundID_Vibrate))
            AudioServicesPlaySystemSound(UInt32(kSystemSoundID_Vibrate))
        }
        
    }
    
    // 磁気センサからユーザーの角度を取得
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // ユーザの向いている方向
        _ = directionJudge.degToRad(degrees: (self.mapView.camera.heading))
        print("カメラ角度")
        print(mapView.camera.heading)
        
        // 加速度の判定を行う
        fallFlag = self.impactDetection.fallDetectionAccel()
        
        print("accel: \(fallFlag)")
        
        if fallFlag == false {
            fallLabel.text = "accel: 異常なし"
            return
        }
        
        // ジャイロセンサの判定を行う
        fallFlag = self.impactDetection.fallDetectionGyro()
        
        if fallFlag {
            print("Gyro: \(fallFlag)")
        } else {
            
            print("Gyro: \(fallFlag)")
            fallLabel.text = "Gyro: 異常なし"
            return
        }
        
        // 気圧の判定を行う
        fallFlag = self.impactDetection.fallDetectionPressure()
        
        if fallFlag {
            let date = Date()
            
            if (Int(date.timeIntervalSince1970) - impactTime) < 60 {
                return
            }
            
            // フラグの判定を元にメールを送るか否か判定する関数
            print("pressure: \(fallFlag)")
            fallFlag = false
            print("--------\(fallFlag)--------")
            sendMail.sendFallMail(coordinate: self.currentCoordinate)
            impactTime = Int(date.timeIntervalSince1970)
            fallLabel.text = "！！異常検知！！"
            
            return
        } else {
            print("pressure: \(fallFlag)")
            fallLabel.text = "pressure: 異常なし"
            return
        }
        
    }
    
    // 座標から距離を求める関数（三角球面法）
    func distance(current: (la: Double, lo: Double), target: (la: Double, lo: Double)) -> Double {
        
        // 緯度経度をラジアンに変換
        let currentLa   = current.la * Double.pi / 180
        let currentLo   = current.lo * Double.pi / 180
        let targetLa    = target.la * Double.pi / 180
        let targetLo    = target.lo * Double.pi / 180

        // 赤道半径
        let equatorRadius = 6378137.0
        
        // 算出
        let averageLat = (currentLa - targetLa) / 2
        let averageLon = (currentLo - targetLo) / 2
        let distance = equatorRadius * 2 * asin(sqrt(pow(sin(averageLat), 2) + cos(currentLa) * cos(targetLa) * pow(sin(averageLon), 2)))
        return distance
    }
    
    // 角度に関する関数
    func rotateManager(heading: CLLocationDirection) {
        self.mapView.camera.heading = heading
//        print("角度：\(self.mapView.camera.heading)")
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
        
        print("Enter （領域内）\(self.stepCount)")
    
//
        if self.stepCount < self.step.steps.count {
            let currentStep = self.step.steps[stepCount]
            let message = "まもなく \(currentStep.instructions)　です。"
            print("領域内に侵入：\(message)")
            print(self.stepCount)
            let speechUtterance = AVSpeechUtterance(string: message)
            self.speech.speak(speechUtterance)
            self.stepCount += 1
        } else {
            let message = "到着しました。お疲れ様でした。"
            let speechUtterance = AVSpeechUtterance(string: message)
            print("領域内に侵入：\(message)")
            self.speech.speak(speechUtterance)
            stepCount = 0
            // 現在刺されているピンの削除
            mapView.removeAnnotations(searchAnnotationArray)
            // 現在表示されているルートを削除
            self.mapView.removeOverlays(self.mapView.overlays)
            
            locationManager.monitoredRegions.forEach( { self.locationManager.stopMonitoring(for: $0)})
        }
    }
    
    // 領域外に外れた時
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if self.step == nil {
            return
        }
        print("Enter （領域外）\(self.stepCount)")
        
        if self.stepCount == 1 {
            return
        }
        
        if self.stepCount < self.step.steps.count { 
            let currentStep = self.step.steps[stepCount]
            let prevStep = self.step.steps[stepCount - 1]
            let message = "\(prevStep.instructions)です。その先、\(round(currentStep.distance)) メートル先, \(currentStep.instructions)　です。"
            let speechUtterance = AVSpeechUtterance(string: message)
            self.speech.speak(speechUtterance)
            print("領域外：\(message)")
        } else {
            locationManager.monitoredRegions.forEach ({ self.locationManager.stopMonitoring(for: $0)})
        }
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
    
    // MARK: SFSpeechRecognizerDelegate
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
