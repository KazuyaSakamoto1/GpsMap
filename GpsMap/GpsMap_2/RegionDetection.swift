//
//  RegionDetection.swift
//  ブラインドマップ
//
//  Created by 樋口裕翔 on 2022/01/01.
//

import Foundation
import CoreLocation

class RegionDetection {
    
    var regionFlag = true
    let setDistance = 5.0
    
    // フラグがtrueの時の処理
    func regionTrueJudge(userLocation: CLLocationCoordinate2D, targetLocation: CLLocationCoordinate2D) -> Bool {
        
        
        let judgeDistance = self.distance(current: ( userLocation.latitude, userLocation.longitude), target: ( targetLocation.latitude, targetLocation.longitude))
        
        if judgeDistance <= setDistance + 5.0 {
            return false
        }
        
        return true
    }
    
    // フラグがtrueの時の処理
    func regionFalseJudge(userLocation: CLLocationCoordinate2D, targetLocation: CLLocationCoordinate2D) -> Bool {
        
        let judgeDistance = self.distance(current: ( userLocation.latitude, userLocation.longitude), target: ( targetLocation.latitude, targetLocation.longitude))
        
        if judgeDistance >= setDistance {
            return true
        }
        
        return false
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
    
}
