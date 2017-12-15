//
//  ViewController.swift
//  VoiceAssistant-iOS
//
//  Created by Robert Horrion on 11/13/17.
//  Copyright © 2017 Robert Horrion. All rights reserved.
//

import UIKit
import AVFoundation
import Alamofire

class ViewController: UIViewController {

    //Create AVFoundation instance variables
    var recorder:AVAudioRecorder!
    var player: AVAudioPlayer!
    var finalURL: URL!
    
    var isRecording:Bool!
    
    @IBOutlet var requestTextView: UITextView!
    @IBOutlet var responseTextView: UITextView!
    
    @IBOutlet var startStopButtonOutlet: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.title = "Hal1000"
        
        isRecording = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func startStopButton(_ sender: UIButton) {
        if isRecording {
            //Stop the recording
            stopRecording()
        } else {
            //Start the recording
            captureWAVAudio()
        }
    }
    
    func updateStartStopButtonTextLabel() {
        if isRecording {
            //Set the Button's TextLabel to "Stop" if audio is being recorded
            startStopButtonOutlet.titleLabel?.text = "Stop"
        } else {
            //Set the Button's TextLabel to "Start" if no audio is being recorded
            startStopButtonOutlet.titleLabel?.text = "Start"
        }
    }
    
    func captureWAVAudio() {
        
        switch AVAudioSession.sharedInstance().recordPermission() {
        
        case AVAudioSessionRecordPermission.granted:
            //Permission was granted, record audio
            
            try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryRecord)
            try! AVAudioSession.sharedInstance().setActive(true)
            
            //Set recorder settings to record PCM audio. Bing text-to-speech only supports PCM monochannel 16khz 16bit audio
            let formatSettings: [String : Any] = [AVFormatIDKey: kAudioFormatLinearPCM,
                                                  AVSampleRateKey: 16000.0,
                                                  AVNumberOfChannelsKey: 1,
                                                  AVEncoderBitRateKey: 25600,
                                                  AVLinearPCMBitDepthKey: 16,
                                                  AVEncoderAudioQualityKey: AVAudioQuality.max.rawValue
            ]
            
            let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.finalURL = directory.appendingPathComponent("halFile.wav")
            
            try! self.recorder = AVAudioRecorder(url: self.finalURL, settings: formatSettings)
            self.recorder.record()
            isRecording = true
            print("recording permission == true")
            
            updateStartStopButtonTextLabel()
            
        break
        case AVAudioSessionRecordPermission.denied:
            //Permission was denied
            self.showError(title: "Warning!", description: "Hal won't work without your permission to use the microphone", buttonTitle: "OK")
        
        break
        case AVAudioSessionRecordPermission.undetermined:
            //Permission state couldn't be determined, ask for permission again
            
            AVAudioSession.sharedInstance().requestRecordPermission() { [unowned self] allowed in
            DispatchQueue.main.async {
                if allowed {
                    self.captureWAVAudio()
                    print("recording started")
                } else {
                    self.showError(title: "Warning!", description: "Hal won't work without your permission to use the microphone", buttonTitle: "OK")
                }
                }
            }
        }
    }
    
    //Stop the audio recording
    func stopRecording() {
        recorder.stop()
        isRecording = false
        recorder = nil
        print("recording ended")
        updateStartStopButtonTextLabel()
        
        //playAudioFile(FileURL: finalURL)
        uploadFileToCognitiveServices(FileURL: finalURL)
    }
    
    //Check if audio file exists, if it does play audio
    func playAudioFile(FileURL: URL) {
        
        if FileManager.default.fileExists(atPath: FileURL.path) {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                try AVAudioSession.sharedInstance().setActive(true)
                
                player = try AVAudioPlayer(contentsOf: FileURL, fileTypeHint: AVFileType.wav.rawValue)
                
                player.play()
                
                print(FileURL)
                print("started playing")
                
            }
            catch let error {
                print(error.localizedDescription)
            }
        }
        else {
            showError(title: "Warning!", description: "No audio response found", buttonTitle: "OK")
        }
    }
    
    //MARK: Cognitive Services uploader using Alamofire
    func uploadFileToCognitiveServices(FileURL: URL) {
        
        var displayText: Any!
        var jsonString: String!
        
        
        let bingSpeechToTextURL = "https://speech.platform.bing.com/speech/recognition/interactive/cognitiveservices/v1?language=de-DE&format=simple"
        
        //Configure the header, documentation can be found here: https://docs.microsoft.com/en-us/azure/cognitive-services/speech/getstarted/getstartedrest?tabs=Powershell
        let headers: HTTPHeaders = [
            "Accept": "application/json;text/xml",
            "Content-Type": "audio/wav; codec=audio/pcm; samplerate=16000",
            "Ocp-Apim-Subscription-Key": "956cba529ba740d3a42e2924262c4454",
            "Host": "speech.platform.bing.com",
            "Transfer-Encoding": "chunked",
            "Expect": "100-continue"
            ]
        
        Alamofire.upload(FileURL, to: bingSpeechToTextURL, method: HTTPMethod.post, headers: headers).responseJSON { response in switch response.result {
            
        case .success(let JSON):
                print("Success with JSON: \(JSON)")
                
                
                let response = JSON as! NSDictionary
                
                //single out the actual speech to text conversion
                displayText =  response.object(forKey: "DisplayText")
                self.requestTextView.text = displayText as! String
            
            case .failure(let error):
                self.showError(title: "HTTP Error", description: "Request failed with error: \(error)", buttonTitle: "OK")
            }
        }
        

        
        
        
        
    }
    
    //Error UI display helper function
    func showError(title: String, description: String, buttonTitle: String) {
        let alertController = UIAlertController(title: title, message: description, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
}
