//
//  ViewController.swift
//  OpenSphericalCameraSample
//
//  Created by Tatsuhiko Arai on 6/3/16.
//  Copyright © 2016 Tatsuhiko Arai. All rights reserved.
//

import UIKit
import OpenSphericalCamera

class ViewController: UIViewController {
    var osc: ThetaCamera = ThetaCamera()
    var connected = false

    @IBOutlet weak var liveView: UIImageView!
    @IBOutlet weak var previewView: UIImageView!
    @IBOutlet weak var connectButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func connectPressed(sender: UIButton) {
        if connected {
            connectButton.setTitle("Connect", forState: .Normal)
            connected = false
            return
        }

        // Set OSC API level 2 (for Ricoh THETA S)
        self.osc.startSession { (data, response, error) in
            if let data = data where error == nil {
                if let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary, results = jsonDic["results"] as? NSDictionary, sessionId = results["sessionId"] as? String {
                    self.osc.setOptions(sessionId: sessionId, options: ["clientVersion": 2]) { (data, response, error) in
                        self.osc.closeSession(sessionId: sessionId) { (data, response, error) in
                            self.startLivePreview()
                        }
                    }
                } else {
                    // Assume clientVersion is equal or later than 2
                    self.startLivePreview()
                }
            } else {
                // Assume clientVersion is equal or later than 2
                self.startLivePreview()
            }
        }

        sender.setTitle("Disconnect", forState: .Normal)
        connected = true
    }

    @IBAction func shutterPressed(sender: UIButton) {
        sender.enabled = false

        self.osc.takePicture { (data, response, error) in
            if let data = data where error == nil {
                let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                if let jsonDic = jsonDic, rawState = jsonDic["state"] as? String, state = OSCCommandState(rawValue: rawState) {
                    switch state {
                    case .InProgress:
                        assertionFailure()
                    case .Done:
                        if let results = jsonDic["results"] as? NSDictionary, fileUrl = results["fileUrl"] as? String {
                            self.osc.get(fileUrl) { (data, response, error) in
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.previewView.image = UIImage(data: data!)
                                }
                                self.startLivePreview()
                            }
                        }
                    case .Error:
                        break // TODO
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue()) {
                sender.enabled = true
            }
        }
    }

    func startLivePreview() {
        // Live Preview
        self.osc.getLivePreview { (data, response, error) in
            if let data = data where error == nil {
                dispatch_async(dispatch_get_main_queue()) {
                    self.liveView.image = UIImage(data: data)
                }
            }
        }
    }
}

