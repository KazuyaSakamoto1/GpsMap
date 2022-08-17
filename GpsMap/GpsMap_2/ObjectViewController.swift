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
    var cross: Date
    var cone: Date
    var person: Date
    var block: Date
    var blue: Date
    var red: Date
    var car: Date
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
    var cross: Date = Date()
    var cone: Date = Date()
    var person: Date = Date()
    var block: Date = Date()
    var blue: Date = Date()
    var red:Date = Date()
    var car:Date = Date()
    var wallflag: Int = 0
    var crossflag: Int = 0
    var coneflag: Int = 0
    var personflag: Int = 0
    var blockflag: Int = 0
    var blueflag: Int = 0
    var redflag: Int = 0
    var carflag: Int = 0
    var dspan:Date = Date()
    var signalspan:Date = Date()
}

class ObjectViewController: UIViewController {
    @IBOutlet weak var cameraView: UIView!
    
    var videoCapture: VideoCapture!
    var objectDetection: ObjectDetection!
    
    var detection = Detection(wall: Date(), cross: Date(), cone: Date(), person: Date(), block: Date(),blue: Date(),red: Date(),car: Date())
    
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
