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

    @IBAction func connectPressed(_ sender: UIButton) {
        if connected {
            connectButton.setTitle("Connect", for: UIControlState())
            connected = false
            return
        }

        // Set OSC API level 2 (for Ricoh THETA S)
        self.osc.startSession { (data, response, error) in
            if let data = data , error == nil {
                if let jsonDic = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary, let results = jsonDic["results"] as? NSDictionary, let sessionId = results["sessionId"] as? String {
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

        sender.setTitle("Disconnect", for: UIControlState())
        connected = true
    }

    @IBAction func shutterPressed(_ sender: UIButton) {
        sender.isEnabled = false

        self.osc.takePicture { (data, response, error) in
            if let data = data , error == nil {
                let jsonDic = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as! NSDictionary
                if let jsonDic = jsonDic, let rawState = jsonDic["state"] as? String, let state = OSCCommandState(rawValue: rawState) {
                    switch state {
                    case .InProgress:
                        assertionFailure()
                    case .Done:
                        if let results = jsonDic["results"] as? NSDictionary, let fileUrl = results["fileUrl"] as? String {
                            self.osc.get(fileUrl) { (data, response, error) in
                                DispatchQueue.main.async {
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
            DispatchQueue.main.async {
                sender.isEnabled = true
            }
        }
    }

    func startLivePreview() {
        // Live Preview
        self.osc.getLivePreview { (data, response, error) in
            if let data = data , error == nil {
                DispatchQueue.main.async {
                    self.liveView.image = UIImage(data: data)
                }
            }
        }
    }
}

