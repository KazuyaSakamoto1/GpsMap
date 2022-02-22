//
//  ImpactDetection.swift
//  ブラインドマップ
//
//  Created by hiroto on 2021/12/20.
//

import Foundation

class ImpactDetection {
    
    // 加速度センサーの変数
    var xAccel = 0.0
    var yAccel = 0.0
    var zAccel = 0.0
    let contorlAccel = 0.98
    var mixAccel = 0.0
    
    // ジャイロセンサーの変数
    var roll = 0.0
    var pitch = 0.0
    var yaw = 0.0
    
    // 気圧センサーの変数
    
    var pressure = 0.0
    var altitude = 0.0
    var prePressure = 0.0
    
    // 転倒時の検出(加速度)
    func fallDetectionAccel() -> Bool {
       
        // 加速度の合成値
        self.mixAccel = sqrt(pow(self.xAccel,2)+pow(self.yAccel,2)+pow(self.zAccel,2))
        
        if self.mixAccel > contorlAccel + 0.05 || self.mixAccel < contorlAccel - 0.05 {
            let flag = false
            return flag
        } else {
            let flag = true
            return flag
        }
    }
    
    // 転倒時の検出(ジャイロセンサ)
    func fallDetectionGyro() -> Bool {
        if self.roll > 60 || self.roll < -70   {
         
            if self.pitch < 30 &&  -30 < self.pitch {
                
                let flag = true
                print("Gyro: \(flag)")
                return flag
                
            } else if self.pitch > 150 {
                
                let flag = true
                print("Gyro: \(flag)")
                return flag
                
            } else if -180 < self.pitch && self.pitch < -150 {
                
                let flag = true
                print("Gyro: \(flag)")
                return flag
                
            } else {
                
                let flag = false
                print("Gyro: \(flag)")
                return flag
                
            }
 
        } else {
            
            let flag = false
            print("Gyro: \(flag)")
            return flag
            
        }
    }
    
    // 転倒時の検出(気圧)
    func fallDetectionPressure()-> Bool {
        
        if self.prePressure == 0 {
            self.prePressure = self.pressure
        }
        
        if fabs(self.pressure - self.prePressure) < 0.001 {
            let flag = false
            return flag
        } else {
            let flag = true
            return flag
        }
    }
    
}
