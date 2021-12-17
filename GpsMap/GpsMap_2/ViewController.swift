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
    let setAngle: Float = 15.0
    // 現在地ボタン
    var button2 = UIButton()
    let image = UIImage(named: "arrow")
    // 音声テキストボタン
    var micButton = UIButton()
    let image2 = UIImage(named: "mic")
    var voiceStr = ""

    // マイクの変数
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    //加速度センサーの変数
    var coreManager = CMMotionManager()
    var xAxis = 0.0
    var yAxis = 0.0
    var zAxis = 0.0
    
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
        self.button2 = UIButton(type: .custom)
        self.button2.setImage(self.image, for: .normal)
        self.view.addSubview(button2)
        self.button2.frame = CGRect(x: 290, y: 500, width: 60, height: 60)
        button2.addTarget(self, action: #selector(self.tapButton(_ :)), for: .touchUpInside)
        
        // 現在地ボタンのアクセシビリティ
        self.button2.isAccessibilityElement = true
        self.button2.accessibilityLabel = "現在地を示す"
        self.button2.accessibilityHint = "ボタンを押すと音声で現在地を示します。"
//
        // 音声テキストボタンを作成
        self.micButton = UIButton(type: .custom)
        self.micButton.setImage(self.image2, for: .normal)
        self.view.addSubview(micButton)
        self.micButton.frame = CGRect(x: 290, y: 430, width: 60, height: 60)
        micButton.addTarget(self, action: #selector(self.recordButtonTapped(sender:)), for: .touchUpInside)
        micButton.setTitle("Start Recording", for: [])
        micButton.isEnabled = false
        
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
        
        if coreManager.isAccelerometerAvailable {
            // 加速度センサーの値取得間隔
            coreManager.accelerometerUpdateInterval = 0.1
            
            // motionの取得を開始
            coreManager.startAccelerometerUpdates(to: OperationQueue.current!, withHandler: { (data, error) in
                // 取得した値をコンソールに表示
                self.xAxis = (data?.acceleration.x)!
                self.yAxis = (data?.acceleration.y)!
                self.zAxis = (data?.acceleration.z)!
//                print("x: \(data?.acceleration.x) y: \(data?.acceleration.y) z: \(data?.acceleration.z)")
                print("X: \(self.xAxis),Y: \(self.yAxis),Z: \(self.zAxis)")
            })
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

    // メールを自動で送信する関数(到着時間を過ぎた時用)
    @objc func sendAttentionMail(_ sender: UIButton){
        print("メールの送信を行います")
        let smtp = SMTP(
            hostname: "smtp.gmail.com",     // SMTP server address
            email: "hiroto.0927.123@gmail.com",        // メールアドレスを入力
            password: ""            // password to login
        )
        
        let drLight = Mail.User(name: "Dr. Light", email: "hiroto.0927.123@gmail.com")
        let megaman = Mail.User(name: "Megaman", email: "hiroto_0927_123@yahoo.co.jp")

        let mail = Mail(
            from: drLight,
            to: [megaman],
            subject: "Humans and robots living together in harmony and equality.",
            text: "到着予定時間を超えています。安否確認を行ってください。位置座標：(緯度,経度)=( \(self.currentCoordinate.latitude), \(self.currentCoordinate.longitude))"
        )

        smtp.send(mail){ (error) in
            if let error = error {
                print("エラーがおきました\(error)")
            }
        }
    }
    
    // メールを自動で送信する関数 https://github.com/Kitura/Swift-SMTP
    func sendArrivedMail() {
        print("メールの送信を行います")
        let smtp = SMTP(
            hostname: "smtp.gmail.com",     // SMTP server address
            email: "hiroto.0927.123@gmail.com",        // メールアドレスを入力
            password: ""            // password to login
        )
        var text = ""
        let drLight = Mail.User(name: "テストユーザー１", email: "hiroto.0927.123@gmail.com")
        let megaman = Mail.User(name: "テストユーザー２", email: "hiroto_0927_123@yahoo.co.jp")

        let location = CLLocation(latitude: self.currentCoordinate.latitude, longitude: self.currentCoordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else { return }
            text = placemark.name!
            print("地名：\(text)")
        }
        // 0.5秒止める
        Thread.sleep(forTimeInterval: 1.5)
        
        let mail = Mail(
            from: drLight,
            to: [megaman],
            subject: "Humans and robots living together in harmony and equality.",
            text: "目的地:\(text)へ到着しました。位置座標：(緯度,経度)=( \(self.currentCoordinate.latitude), \(self.currentCoordinate.longitude))"
        )

        smtp.send(mail){ (error) in
            if let error = error {
                print("エラーがおきました\(error)")
            }
        }

    }

    
    // アプリへの場所関連イベントの配信を開始および停止するために使用する
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        var Flag: Bool = false
        guard let location = locations.first else { return }
        
        // 到着予定時間を過ぎたら一度だけ実行される関数
        if self.step != nil {
            Timer.scheduledTimer(timeInterval: self.step.expectedTravelTime, target: self, selector: #selector(self.sendAttentionMail(_:)), userInfo: nil, repeats: false)
        }

        
        self.currentCoordinate.latitude = location.coordinate.latitude
        self.currentCoordinate.longitude = location.coordinate.longitude
        print("緯度：\(self.currentCoordinate.longitude)")
        print("経度：\(self.currentCoordinate.latitude)")
        
        //
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
            self.sendArrivedMail()
            self.step = nil
            return
        }
        
        let nextLocation = self.step.steps[self.stepCount]
        // 目標角度
        let targetRadian = self.angle(coordinate: prevCoordinateInfo!.coordinate, coordinate2: nextLocation.polyline.coordinate)
        let targetRadian2 = self.angle(coordinate: nextLocation.polyline.coordinate, coordinate2: prevCoordinateInfo!.coordinate)
        // 実際に移動した角度
        let userRadian = self.angle(coordinate: prevCoordinateInfo!.coordinate, coordinate2: locations.last!.coordinate )
        let userRadian2 = self.angle(coordinate: locations.last!.coordinate, coordinate2: prevCoordinateInfo!.coordinate)
        
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
        if targetRadian - setAngle < 0 || targetRadian + setAngle > 360 {
            
           Flag = Flag || self.compareAngle(targetRadian: targetRadian, userRadian: userRadian)
           Flag = Flag || self.compareAngle(targetRadian: userRadian, userRadian: targetRadian)
        } else {
            
           Flag = Flag || self.compareAngle2(targetRadian: targetRadian, userRadian: userRadian)
           Flag = Flag || self.compareAngle(targetRadian: userRadian, userRadian: targetRadian)
        }
        
        if targetRadian2 - setAngle < 0 || targetRadian2 + setAngle > 360 {
            
           Flag = Flag || self.compareAngle(targetRadian: targetRadian2, userRadian: userRadian2)
            Flag = Flag || self.compareAngle(targetRadian: userRadian2, userRadian: targetRadian2)
        } else {
            
           Flag = Flag || self.compareAngle2(targetRadian: targetRadian2, userRadian: userRadian2)
           Flag = Flag || self.compareAngle2(targetRadian: userRadian2, userRadian: targetRadian2)
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
        _ = self.degToRad(degrees: (self.mapView.camera.heading))
//        print("カメラ角度")
//        print(mapView.camera.heading)
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
    
    // 角度を比較し、アナウンスするか否かの処理(０と３６０の間をまたぐとき）
    func compareAngle(targetRadian: Float, userRadian: Float) -> Bool {
        // １つ目の計算用変数の角度調整
        var calculationRadian = targetRadian + setAngle
        
        if calculationRadian > 360 {
            calculationRadian -= 360
        }
        // ２つ目の計算用変数の角度調整
        var calculationRadian2 = targetRadian - setAngle
        
        if calculationRadian2 < 0 {
            calculationRadian2 += 360
        }
            
        if userRadian < calculationRadian || userRadian > calculationRadian2 {
            let a = true
            return a
        } else {
            let a = false
            return a
        }
    }
    
    // 角度を比較し、アナウンスするか否かの処理(０と３６０の間をまたがいないとき)
    func compareAngle2(targetRadian: Float, userRadian: Float) -> Bool {
     
        // １つ目の計算用変数の角度調整
        var calculationRadian = targetRadian + setAngle
        
        if calculationRadian > 360 {
            
            calculationRadian -= 360
            
        }
        // ２つ目の計算用変数の角度調整
        var calculationRadian2 = targetRadian - setAngle
        
        if calculationRadian2 < 0 {
            
            calculationRadian2 += 360
            
        }
            
        if userRadian < calculationRadian && userRadian > calculationRadian2 {
            
            let a = true
            return a
            
        } else {
            
            let a = false
            return a
            
        }
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
                
                let searchRequest = MKLocalSearch.Request()
                searchRequest.naturalLanguageQuery = self.voiceStr
                
                // 検索範囲はマップビューと同じにする。
                searchRequest.region = mapView.region
                // ローカル検索を実行する。
                let localSerch: MKLocalSearch = MKLocalSearch(request: searchRequest)
                localSerch.start(completionHandler: localSearchCompHandler(response:error:))
                
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
