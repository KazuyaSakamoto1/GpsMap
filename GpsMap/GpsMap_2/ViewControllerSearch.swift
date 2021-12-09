//
//  ViewControllerSearch.swift
//  GpsMap_2
//
//  Created by hiroto on 2021/09/28.
//

import Foundation
import UIKit
import MapKit
import AVFoundation

//　検索に関する処理
extension ViewController: UISearchBarDelegate {
    // 検索ボタンがクリックされた際の処理内容
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // トラッキングモードを無効化
        self.mapView.userTrackingMode = .none
        // 現在表示されているルートを削除
        self.mapView.removeOverlays(self.mapView.overlays)
        // キーボードを閉じる。
        serchBar!.resignFirstResponder()
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
            serchBar!.resignFirstResponder()
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
        let point: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: (maxLat + minLat) / 2, longitude: (maxLong + minLong) / 2)
        let region: MKCoordinateRegion = MKCoordinateRegion(center: point, latitudinalMeters: fabs((maxLat - minLat)), longitudinalMeters: fabs((maxLong - minLong)) * 100000)
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
            self.step = route
            let time = route.expectedTravelTime
            let timeMessage = "到着予定時間は約\(ceil(time/60))分です。"
            let speech = AVSpeechUtterance(string: timeMessage)
            self.speech.speak(speech)
            // 経路を描画
            self.mapView.addOverlay(route.polyline)
            print(route.polyline.coordinate)
            // 現在地と目的地を含む表示範囲を設定する
            self.displaySearch2(goalLatitude: goalCoordinate!.latitude, goalLongitude: goalCoordinate!.longitude, parm: 250000)
            
            for i in 0..<self.step.steps.count {
                let step = route.steps[i]
                print(step.instructions)
                print(step.distance)
                print(step.notice  as Any)
                print(step.polyline.coordinate)
                let region = CLCircularRegion(center: step.polyline.coordinate, radius: 40, identifier: "\(i)")
                self.locationManager.startMonitoring(for: region) // 引数で受け取った範囲を監視する
                let circle = MKCircle(center: region.center, radius: region.radius)
                self.mapView.addOverlay(circle)
            }
//            let initialMessage = "\(round(self.step.steps[1].distance))　メートル先, \(self.step.steps[1].instructions)です。"
//            let speechUtterance = AVSpeechUtterance(string: initialMessage)
//            self.speech.speak(speechUtterance)
            self.stepCount += 1
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
        let point: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: (userLatitude + goalLatitude) / 2, longitude: (userLongitude + goalLongitude) / 2)
        let region: MKCoordinateRegion = MKCoordinateRegion(center: point, latitudinalMeters: fabs((userLatitude - goalLatitude) * parm), longitudinalMeters: fabs((userLongitude-goalLongitude)*parm))
            mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    
    // ピンがタップされた際の処理
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        getRoute(goalCoordinate: view.annotation!.coordinate)
        displaySearch(goalLatitude: view.annotation!.coordinate.latitude, goalLongitude: view.annotation!.coordinate.longitude, parm: 500)
        print("----------------確認")
    }
    
    // 経路を描画するときの色や線の太さを指定
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let polylineRenderer = MKPolylineRenderer(polyline: polyline)
            polylineRenderer.strokeColor = .blue
            polylineRenderer.lineWidth = 4.0
            return polylineRenderer
        }
        
        if let polyline = overlay as? MKCircle {
            let polylineRenderer = MKCircleRenderer(overlay: polyline)
            polylineRenderer.strokeColor = .red
            polylineRenderer.fillColor = .red
            polylineRenderer.alpha = 0.5
            return polylineRenderer
        }
        return MKOverlayRenderer()
    }
}
