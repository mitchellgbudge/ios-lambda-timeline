//
//  AudioCommentViewController.swift
//  LambdaTimeline
//
//  Created by Spencer Curtis on 10/15/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import UIKit
import AVFoundation

class AudioCommentViewController: UIViewController, AVAudioRecorderDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preferredContentSize = CGSize(width: view.frame.width * 0.9, height: view.frame.height * 0.15)
        recordLabel.text = "Tap the Record button to start your comment"
        
        playRecordingButton.isHidden = true
        
        session = AVAudioSession.sharedInstance()
        
        do {
            
            try session.setCategory(.playAndRecord, mode: .default, options: [])
            try session.setActive(true)
            session.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                    } else {
                        self.presentInformationalAlertController(title: "Unable to record audio", message: "Audio recording permissions not granted")
                    }
                }
            }
        } catch {
            NSLog("Error with audio record permissions: \(error)")
            self.presentInformationalAlertController(title: "Unable to record audio", message: "Audio recording failed. Try again.")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        NotificationCenter.default.post(name: .audioVCPopoverDismissed, object: nil)
    }
    
    @IBAction func record(_ sender: Any) {
        if recorder == nil {
            guard let fileURL = fileURL else { return }
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            do {
                recorder = try AVAudioRecorder(url: fileURL, settings: settings)
                recorder.delegate = self
                recorder.record()
                recordLabel.text = "Recording..."
                recordButton.setTitle("Stop", for: .normal)
            } catch {
                NSLog("Error recording audio comment: \(error)")
            }
        } else {
            
            let time = round(recorder.currentTime * 100) / 100
            
            recordLabel.text = "Recording duration: \(time) seconds"
            recorder.stop()
            recorder = nil
            recordButton.setTitle("Record", for: .normal)
        }
    }
    
    @IBAction func done(_ sender: Any) {
        
        if let fileURL = fileURL,
            let data = try? Data(contentsOf: fileURL),
            let post = post {
            
            let alert = UIAlertController(title: "Do you want to send the comment or cancel it?", message: nil, preferredStyle: .alert)
            
            let sendAction = UIAlertAction(title: "Send", style: .default) { (_) in
                self.postController.addComment(with: data, to: post) {
                    self.dismiss(animated: true, completion: nil)
                }
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) { (_) in
                self.dismiss(animated: true, completion: nil)
            }
            
            alert.addAction(sendAction)
            alert.addAction(cancelAction)
            
            present(alert, animated: true, completion: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    var post: Post!
    var postController: PostController!
    
    var session: AVAudioSession!
    var recorder: AVAudioRecorder!
    
    var fileURL: URL? {
        guard let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        
        return documentDirectory.appendingPathComponent("audioComment.m4a")
    }
    
    
    @IBOutlet weak var recordLabel: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var playRecordingButton: UIButton!
}

