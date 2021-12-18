//
//  DirectionJudge.swift
//  ブラインドマップ
//
//  Created by 樋口裕翔 on 2021/12/18.
//

import Foundation
import CoreLocation
import UIKit

class DirectionJudge {
    
    let setAngle: Float = 15.0
    
    // 角度をラジアンに変換する
    func degToRad(degrees: CGFloat) -> CGFloat {
        return degrees * CGFloat.pi / 180
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
    
    // 各位を計算
    func angle(coordinate: CLLocationCoordinate2D, coordinate2: CLLocationCoordinate2D) -> Float {
        let currentLatitude     = self.degToRad(degrees: coordinate.latitude)
        let currentLongitude    = self.degToRad(degrees: coordinate.longitude)
        let targetLatitude      = self.degToRad(degrees: coordinate2.latitude)
        let targetLongitude     = self.degToRad(degrees: coordinate2.longitude)
        
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
    func compareAngle(targetRadian: Float, userRadian: Float) -> Bool{
        // １つ目の計算用変数の角度調整
        var calculationRadian = targetRadian + setAngle
        
        if calculationRadian > 360  {
            
            calculationRadian -= 360
            
        }
        
        // ２つ目の計算用変数の角度調整
        var calculationRadian2 = targetRadian - setAngle
        
        if calculationRadian2 < 0 {
            
            calculationRadian2 += 360
            
        }
            
        if userRadian < calculationRadian || userRadian > calculationRadian2 {
            
            let a  = true
            return a
            
        } else {
            let a  = false
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
    
}
