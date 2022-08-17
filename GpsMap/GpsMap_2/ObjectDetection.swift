//
//  ObjectDetection.swift
//  LEAD WAY
//
//  Created by 坂本和哉 on 2022/06/25.
//

import UIKit
import Vision

class ObjectDetection {
    private var objectDetectionLayer: CALayer!
    
    
    
    
    var detection = Detection(wall: Date(), cross: Date(), cone: Date(), person: Date(), block: Date(), blue: Date(), red: Date(), car: Date())
    let detectionclass = Detectionclass()

    init(_ viewLayer: CALayer, videoFrameSize: CGSize) {
        self.setupObjectDetectionLayer(viewLayer, videoFrameSize)
    }
    
    public func createObjectDetectionVisionRequest() -> VNRequest? {
        // Setup Vision parts
        do {
            let model = vidvip_20210521().model
            let visionModel = try VNCoreMLModel(for: model)
            let objectRecognition = VNCoreMLRequest(model: visionModel, completionHandler: { (request, error) in
                DispatchQueue.main.async(execute: {
                    // perform all the UI updates on the main queue
                    if let results = request.results {
                        self.processVisionRequestResults(results)
                    }
                })
            })
            
            // To make things simpler we use .scaleFill below (what will introduce some geomerty distortion to the image, but will ensure
            // that the whole visilble image is processed by the ML model.
            // If we would like to be 100% sure that no distortion is introduced, we would need to use .scaleFit and update
            // setupObjectDetectionLayer below to ensure proper scaling of returned results.
            objectRecognition.imageCropAndScaleOption = .scaleFill
            return objectRecognition
        } catch let error as NSError {
            print("モデルの読み込みに失敗しました: \(error)")
            return nil
        }
    }
    
    //レイヤーの構築
    private func setupObjectDetectionLayer(_ viewLayer: CALayer, _ videoFrameSize: CGSize) {
        self.objectDetectionLayer = CALayer() // container layer that has all the renderings of the observations
        self.objectDetectionLayer.name = "ObjectDetectionLayer"
        self.objectDetectionLayer.bounds = CGRect(x: 0.0,
                                         y: 0.0,
                                         width: videoFrameSize.width,
                                         height: videoFrameSize.height)
        self.objectDetectionLayer.position = CGPoint(x: viewLayer.bounds.midX, y: viewLayer.bounds.midY)
        
        viewLayer.addSublayer(self.objectDetectionLayer)

        // Scaling layer from video frame size to the actual size
        let bounds = viewLayer.bounds
        
        // NOTE: We need to use fmin() here, if we use videoPreviewLayer.videoGravity = .resizeAspect in the VideoCapture.
        //       We need to use fmax() here, if we use videoPreviewLayer.videoGravity = .resizeAspectFill in the VideoCapture.
        let scale = fmax(bounds.size.width  / videoFrameSize.width, bounds.size.height / videoFrameSize.height)
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        // We need to invert the y coordinates returned from the model to match screen coordinates
        self.objectDetectionLayer.setAffineTransform(CGAffineTransform(scaleX: scale, y: -scale))
        
        // center the layer
        self.objectDetectionLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        
        CATransaction.commit()
    }
    
    //バウンディングボックスの作成
    //音声案内
    private func createBoundingBoxLayer(_ bounds: CGRect, identifier: String, confidence: VNConfidence) -> CALayer {
        let path = UIBezierPath(rect: bounds)
        
        let boxLayer = CAShapeLayer()
        boxLayer.path = path.cgPath
        boxLayer.strokeColor = UIColor.red.cgColor
        boxLayer.lineWidth = 2
        boxLayer.fillColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 0.0])
        
        boxLayer.bounds = bounds
        boxLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        boxLayer.name = "Detected Object Box"
        boxLayer.backgroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.5, 0.5, 0.2, 0.3])
        boxLayer.cornerRadius = 6

        let textLayer = CATextLayer()
        textLayer.name = "Detected Object Label"
        
        // confidence=適合率 0.80など
        // identifier=識別子　信号機など
        textLayer.string = String(format: "\(identifier)\n(%.2f)", confidence)
        textLayer.fontSize = CGFloat(16.0)
        
        textLayer.bounds = CGRect(x: 0, y: 0, width: bounds.size.width - 10, height: bounds.size.height - 10)
        textLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        textLayer.alignmentMode = .center
        textLayer.foregroundColor =  UIColor.red.cgColor
        textLayer.contentsScale = 2.0 // retina rendering
        
        // We have inverted y axis to handle results returned from the model.
        // To avoid text labels being printed upside down, we need to invert y axis for text once again.
        textLayer.setAffineTransform(CGAffineTransform(scaleX: 1.0, y: -1.0))
        
        boxLayer.addSublayer(textLayer)
        
        return boxLayer
    }

    private func processVisionRequestResults(_ results: [Any]) {
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        
        let speechService = SpeechService()
        
        //let detectionstruct = ObjectViewController()
        
        self.objectDetectionLayer.sublayers = nil // remove all previously detected objects
        for observation in results where observation is VNRecognizedObjectObservation {
            guard let objectObservation = observation as? VNRecognizedObjectObservation else {
                continue
            }
            // Select only the label with the highest confidence.
            let topLabelObservation = objectObservation.labels[0]
            let objectBounds = VNImageRectForNormalizedRect(
                objectObservation.boundingBox,
                Int(self.objectDetectionLayer.bounds.width), Int(self.objectDetectionLayer.bounds.height))
            //実装したいもの
            //白線　信号機　人　壁　点字ブロック　カラーコーン
            if topLabelObservation.confidence >= 0.90 {
                let date = Date()
                let dspan = detectionclass.dspan.timeIntervalSince(date)
                let signalspan = detectionclass.signalspan.timeIntervalSince(date)
                
                if(signalspan < -3){
                    if(topLabelObservation.identifier == "signal_blue"){
                        //１回目
                        if(detectionclass.blueflag == 0){
                            //let span = detectionstruct.detection.block.timeIntervalSince(date)
                            speechService.say("歩行者信号が青です")
                            detectionclass.blueflag = 1
                            detection.blue = Date()
                            detectionclass.signalspan = Date()
                        }else{//１回目以降
                            let span = detection.blue.timeIntervalSince(date)
                            print(span)
                            if span < -3{
                                speechService.say("歩行者信号が青です")
                                detection.blue = Date()
                                detectionclass.signalspan = Date()
                            }//５秒以上経過せず
                        }//1回目以降
                        
                    }else if(topLabelObservation.identifier == "signal_red"){
                        if(detectionclass.redflag == 0){
                            //let span = detectionstruct.detection.block.timeIntervalSince(date)
                            speechService.say("歩行者信号が赤です")
                            detectionclass.redflag = 1
                            detection.red = Date()
                            detectionclass.signalspan = Date()
                        }else{//１回目以降
                            let span = detection.red.timeIntervalSince(date)
                            print(span)
                            if span < -3{
                                speechService.say("歩行者信号が赤です")
                                detection.red = Date()
                                detectionclass.signalspan = Date()
                            }//５秒以上経過せず
                        }//1回目以降
                    }
                }
                
                
                
                if(dspan < -2){
                    //？秒に一回壁を音声案内できる機能（何度も音声案内するとうるさいから）
                    if(topLabelObservation.identifier == "wall" && UserDefaults.standard.bool(forKey: "wall") == true){
                        //１回目
                        if(detectionclass.wallflag == 0){
                            //let span = detectionstruct.detection.wall.timeIntervalSince(date)
                            if(objectBounds.midX < 180){
                                speechService.say("左側に壁があります")
                            }else if(objectBounds.midX >= 180 && objectBounds.midX < 260){
                                speechService.say("前方に壁があります")
                            }else{
                                speechService.say("右側に壁があります")
                            }
                            detectionclass.wallflag = 1
                            detection.wall = Date()
                            detectionclass.dspan = Date()
                        }else{//１回目以降
                            let span = detection.wall.timeIntervalSince(date)
                            print(span)
                            if span < -4{
                                if(objectBounds.midX < 180){
                                    speechService.say("左側に壁があります")
                                }else if(objectBounds.midX >= 180 && objectBounds.midX < 260){
                                    speechService.say("前方に壁があります")
                                }else{
                                    speechService.say("右側に壁があります")
                                }
                                detection.wall = Date()
                                detectionclass.dspan = Date()
                            }
                        }
                    }else if(topLabelObservation.identifier == "crosswalk" && UserDefaults.standard.bool(forKey: "cross") == true){//横断歩道
                        //１回目
                        if(detectionclass.crossflag == 0){
                            //let span = detectionstruct.detection.white.timeIntervalSince(date)
                            if(objectBounds.midX < 180){
                                speechService.say("左前方に横断歩道があります")
                            }else if(objectBounds.midX >= 180 && objectBounds.midX < 260){
                                speechService.say("前方に横断歩道があります")
                            }else{
                                speechService.say("右前方に横断歩道があります")
                            }
                            detectionclass.crossflag = 1
                            detection.cross = Date()
                            detectionclass.dspan = Date()
                        }else{//１回目以降
                            let span = detection.cross.timeIntervalSince(date)
                            print(span)
                            if span < -4{
                                if(objectBounds.midX < 180){
                                    speechService.say("左前方に横断歩道があります")
                                }else if(objectBounds.midX >= 180 && objectBounds.midX < 260){
                                    speechService.say("前方に横断歩道があります")
                                }else{
                                    speechService.say("右前方に横断歩道があります")
                                }
                                detection.cross = Date()
                                detectionclass.dspan = Date()
                            }
                        }
                    }else if(topLabelObservation.identifier == "safety-cone" && UserDefaults.standard.bool(forKey: "cone") == true){//コーン
                        //１回目
                        if(detectionclass.coneflag == 0){
                            //let span = detectionstruct.detection.cone.timeIntervalSince(date)
                            speechService.say("コーンがあります")
                            detectionclass.coneflag = 1
                            detection.cone = Date()
                            detectionclass.dspan = Date()
                        }else{//１回目以降
                            let span = detection.cone.timeIntervalSince(date)
                            print(span)
                            if span < -5{
                                speechService.say("コーンがあります")
                                detection.cone = Date()
                                detectionclass.dspan = Date()
                            }
                        }
                    }else if(topLabelObservation.identifier == "person" && UserDefaults.standard.bool(forKey: "person") == true){//人
                        //１回目
                        if(detectionclass.personflag == 0){
                            //let span = detectionstruct.detection.person.timeIntervalSince(date)
                            speechService.say("前方に人がいます")
                            detectionclass.personflag = 1
                            detection.person = Date()
                            detectionclass.dspan = Date()
                        }else{//１回目以降
                            let span = detection.person.timeIntervalSince(date)
                            print(span)
                            if span < -4{
                                speechService.say("前方に人がいます")
                                detection.person = Date()
                                detectionclass.dspan = Date()
                            }
                        }
                    }else if(topLabelObservation.identifier == "braille_block" && UserDefaults.standard.bool(forKey: "block") == true){//点字ブロックif(topLabelObservation.identifier == "braille_block")
                        //１回目
                        if(detectionclass.blockflag == 0){
                            //let span = detectionstruct.detection.block.timeIntervalSince(date)
                            if(objectBounds.midX < 180){
                                speechService.say("左前方に点字ブロックがあります")
                            }else if(objectBounds.midX >= 180 && objectBounds.midX < 260){
                                speechService.say("前方に点字ブロックがあります")
                            }else{
                                speechService.say("右前方に点字ブロックがあります")
                            }
                            detectionclass.blockflag = 1
                            detection.block = Date()
                            detectionclass.dspan = Date()
                        }else{//１回目以降
                            let span = detection.block.timeIntervalSince(date)
                            print(span)
                            if span < -8{
                                if(objectBounds.midX < 180){
                                    speechService.say("左前方に点字ブロックがあります")
                                }else if(objectBounds.midX >= 180 && objectBounds.midX < 260){
                                    speechService.say("前方に点字ブロックがあります")
                                }else{
                                    speechService.say("右前方に点字ブロックがあります")
                                }
                                detection.block = Date()
                                detectionclass.dspan = Date()
                            }//５秒以上経過せず
                        }//1回目以降
                     }else if(topLabelObservation.identifier == "car" && UserDefaults.standard.bool(forKey: "car") == true){
                         //１回目
                         if(objectBounds.midX >= 180 && objectBounds.midX < 260){
                             if(detectionclass.carflag == 0){
                                 //let span = detectionstruct.detection.wall.timeIntervalSince(date)
                                 speechService.say("前方に壁があります")
                                 detectionclass.wallflag = 1
                                 detection.wall = Date()
                                 detectionclass.dspan = Date()
                             }else{//１回目以降
                                 let span = detection.wall.timeIntervalSince(date)
                                 print(span)
                                 if span < -4{
                                     speechService.say("前方に壁があります")
                                     detection.wall = Date()
                                     detectionclass.dspan = Date()
                                 }
                             }
                         }
                         
                     }//物体ごと
                }//２秒間隔で音声案内
            }//0.85適合率以上の検知
            
            let bbLayer = self.createBoundingBoxLayer(objectBounds, identifier: topLabelObservation.identifier, confidence: topLabelObservation.confidence)
            self.objectDetectionLayer.addSublayer(bbLayer)
        }
    
        CATransaction.commit()
    }
}

