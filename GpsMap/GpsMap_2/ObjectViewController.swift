//
//  ObjectViewController.swift
//  LEAD WAY
//
//  Created by 坂本和哉 on 2022/06/25.
//

import UIKit
import AVFoundation
import Vision


class ObjectViewController: UIViewController {
    @IBOutlet weak var cameraView: UIView!
    
    var videoCapture: VideoCapture!
    var objectDetection: ObjectDetection!
    
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
