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
    
    var detection = Detection(wall: Date(), white: Date(), cone: Date(), person: Date(), block: Date())
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
    //音声案内(未実装)
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
        
        let detectionstruct = ObjectViewController()
        
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
            if topLabelObservation.confidence >= 0.80 {
                let date = Date()
                //５秒に一回壁を音声案内できる機能（何度も音声案内するとうるさいから）
                if topLabelObservation.identifier == "wall" {
                    //１回目
                    if(detectionclass.flag == 0){
                        let span = detectionstruct.detection.wall.timeIntervalSince(date)
                        speechService.say("壁があります")
                        detectionclass.flag = 1
                        detection.wall = Date()
                    }else{//１回目以降
                        let span = detection.wall.timeIntervalSince(date)
                        print(span)
                        if span < -5{
                            speechService.say("壁があります")
                            detection.wall = Date()
                        }
                    }
                }else if(topLabelObservation.identifier == "white_line"){
                    speechService.say("横断歩道があります")
                }
            }
            
            let bbLayer = self.createBoundingBoxLayer(objectBounds, identifier: topLabelObservation.identifier, confidence: topLabelObservation.confidence)
            self.objectDetectionLayer.addSublayer(bbLayer)
        }
    
        CATransaction.commit()
    }
}

