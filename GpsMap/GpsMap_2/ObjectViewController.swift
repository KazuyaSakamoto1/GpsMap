//
//  ObjectViewController.swift
//  LEAD WAY
//
//  Created by 坂本和哉 on 2022/06/25.
//

import UIKit
import AVFoundation
import Vision

struct Detection{
    var wall: Date
    var white: Date
    var cone: Date
    var person: Date
    var block: Date
    /*
    init(wall: Date, white: Date, cone: Date, person: Date, block: Date){
        self.wall = Date()
        self.white = Date()
        self.cone = Date()
        self.person = Date()
        self.block = Date()
        return
    }
     */
}

class Detectionclass{
    var wall: Date = Date()
    var white: Date = Date()
    var cone: Date = Date()
    var person: Date = Date()
    var block: Date = Date()
    var flag: Int = 0
}

class ObjectViewController: UIViewController {
    @IBOutlet weak var cameraView: UIView!
    
    var videoCapture: VideoCapture!
    var objectDetection: ObjectDetection!
    
    var detection = Detection(wall: Date(), white: Date(), cone: Date(), person: Date(), block: Date())
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        // Do any additional setup after loading the view.
        
        // Order below is important (in this order are layers being added)
        self.videoCapture = VideoCapture(self.cameraView.layer)
        self.objectDetection = ObjectDetection(self.cameraView.layer, videoFrameSize: self.videoCapture.getCaptureFrameSize())
        
        // When all components are setup, we can start capturing video
        let visionRequest = self.objectDetection.createObjectDetectionVisionRequest()
        self.videoCapture.startCapture(visionRequest)
            
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
