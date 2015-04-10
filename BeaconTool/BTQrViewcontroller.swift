//
//  BTQrViewcontroller.swift
//  BeaconTool
//
//  Created by YunTop on 15/1/4.
//  Copyright (c) 2015年 YunTop. All rights reserved.
//

import UIKit

class BTQrViewcontroller: UIViewController,ZXCaptureDelegate {
    private let capture = ZXCapture();
    
    override func viewDidLoad() {
        self.capture.camera = self.capture.back();
        self.capture.focusMode = AVCaptureFocusMode.ContinuousAutoFocus;
        self.capture.rotation = 90.0;
        self.capture.layer.frame = self.view.bounds;
        self.capture.delegate = self;
        self.view.layer.addSublayer(self.capture.layer);
        
    }
    
    override func didReceiveMemoryWarning() {
        
    }
    func captureResult(capture: ZXCapture!, result: ZXResult!) {
        print(result);
    }
}
