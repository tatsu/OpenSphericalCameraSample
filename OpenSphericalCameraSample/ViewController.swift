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
    var sessionId: String?

    @IBOutlet weak var liveView: UIImageView!
    @IBOutlet weak var previewView: UIImageView!
    @IBOutlet weak var connectButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        connectButton.setTitle("Connect", forState: .Normal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func connectPressed(sender: UIButton) {
        sender.enabled = false

        if let sessionId = self.sessionId {
            self.osc.closeSession(sessionId: sessionId) { (data, response, error) in
                defer {
                    sender.enabled = true
                }
                self.sessionId = nil
                dispatch_async(dispatch_get_main_queue()) {
                    sender.setTitle("Connect", forState: .Normal)
                }
            }
        } else {
            self.osc.startSession { (data, response, error) in
                defer {
                    sender.enabled = true
                }
                if let data = data where error == nil {
                    let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                    if let jsonDic = jsonDic, results = jsonDic["results"] as? NSDictionary {
                        self.sessionId = results["sessionId"] as? String
                        self.startLivePreview()
                    }
                }
                if self.sessionId != nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        sender.setTitle("Disconnect", forState: .Normal)
                    }
                }
            }
        }

    }

    @IBAction func shutterPressed(sender: UIButton) {
        guard let sessionId = self.sessionId else {
            return
        }

        sender.enabled = false

        self.osc.takePicture(sessionId: sessionId) { (data, response, error) in
            defer {
                sender.enabled = true
            }

            if let data = data where error == nil {
                let jsonDic = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                if let jsonDic = jsonDic, rawState = jsonDic["state"] as? String, state = OSCCommandState(rawValue: rawState) {
                    switch state {
                    case .InProgress:
                        assertionFailure()
                    case .Done:
                        if let results = jsonDic["results"] as? NSDictionary, fileUri = results["fileUri"] as? String {
                            self.osc.getImage(fileUri: fileUri, _type: .Thumb) { (data, response, error) in
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
        }
    }

    func startLivePreview() {
        if let sessionId = self.sessionId {
            // Live Preview
            self.osc._getLivePreview(sessionId: sessionId) { (data, response, error) in
                if let data = data where error == nil {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.liveView.image = UIImage(data: data)
                    }
                }
            }
        }
    }
}

