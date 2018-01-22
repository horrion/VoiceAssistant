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
import QuartzCore

class ViewController: UIViewController, AVAudioPlayerDelegate  {

    //Create AVFoundation instance variables
    var recorder:AVAudioRecorder!
    var player: AVAudioPlayer!
    var finalURL: URL!
    
    var isRecording:Bool!
    
    //Create Bing Speech API instance variables
    
    //Create SubscriptionKey instance variables
    let bingSpeechSubscriptionKey = ""
    let luisSubscriptionKey = ""
    
    //LUIS Intent
    var luisIntent: String!
    
    //REST API URLs
    let requestTokenURL = "https://api.cognitive.microsoft.com/sts/v1.0/issueToken"
    let bingSpeechToTextURL = NSLocalizedString("bingSpeechRecognitionURL", comment: "")
    let bingTextToSpeechURL = "https://speech.platform.bing.com/synthesize"
    let luisURL = ""
    
    
    
    @IBOutlet var requestTextView: UITextView!
    @IBOutlet var responseTextView: UITextView!
    
    @IBOutlet var startStopButtonOutlet: UIButton!
    
    //MARK: iOS functions
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.title = "Anna"
        
        isRecording = false
        
        //GUI setup
        requestTextView.layer.cornerRadius = 10
        responseTextView.layer.cornerRadius = 10
        startStopButtonOutlet.layer.cornerRadius = 10
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func startStopButton(_ sender: UIButton) {
        if isRecording {
            //Stop the recording
            stopRecording()
            
            //Set the Button's TextLabel to "Start" if no audio is being recorded
            startStopButtonOutlet.titleLabel?.text = "Start"
        } else {
            //Start the recording
            captureWAVAudio()
            
            //Set the Button's TextLabel to "Stop" if audio is being recorded
            startStopButtonOutlet.titleLabel?.text = "Stop"
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
            
        break
        case AVAudioSessionRecordPermission.denied:
            //Permission was denied
            self.showError(title: NSLocalizedString("warning", comment: ""), description: NSLocalizedString("microphoneWarning", comment: ""), buttonTitle: NSLocalizedString("ok", comment: ""))
        
        break
        case AVAudioSessionRecordPermission.undetermined:
            //Permission state couldn't be determined, ask for permission again
            
            AVAudioSession.sharedInstance().requestRecordPermission() { [unowned self] allowed in
            DispatchQueue.main.async {
                if allowed {
                    self.captureWAVAudio()
                    print("recording started")
                } else {
                    self.showError(title: NSLocalizedString("warning", comment: ""), description: NSLocalizedString("microphoneWarning", comment: ""), buttonTitle: NSLocalizedString("ok", comment: ""))
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
        
        //Convert the recorded soundfile to text using Microsoft's Speech to Text API
        bingSpeechToText(FileURL: finalURL)
    }
    
    func playAudioFile(FileData: Data) {
        
        //Play the audio file if its contents aren't empty
        if FileData.description != "" {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                try AVAudioSession.sharedInstance().setActive(true)
                
                //Bing Text to Speech was set to provide .mp3 files. Bing's .wav files can't be played by AVAudioPlayer as of 12/2017
                player = try AVAudioPlayer(data: FileData, fileTypeHint: AVFileType.mp3.rawValue)
                player.delegate = self
                
                player.play()
                
                print("started playing")
            }
            catch let error {
                //AVAudioPlayer Error occured, handle it!
                showError(title: NSLocalizedString("avaudioplayerError", comment: ""), description: error.localizedDescription, buttonTitle: NSLocalizedString("ok", comment: ""))
            }
        }
        else {
            //AVAudioPlayer Error occured, handle it!
            showError(title: NSLocalizedString("warning", comment: ""), description: NSLocalizedString("noAudioResponseFound", comment: ""), buttonTitle: NSLocalizedString("ok", comment: ""))
        }
    }
    
    //MARK: Cognitive Services uploader using Alamofire
    func bingSpeechToText(FileURL: URL) {
        
        var displayText: Any!
        
        //Configure the header, documentation can be found here: https://docs.microsoft.com/en-us/azure/cognitive-services/speech/getstarted/getstartedrest?tabs=Powershell
        let header: HTTPHeaders = [
            "Accept": "application/json;text/xml",
            "Content-Type": "audio/wav; codec=audio/pcm; samplerate=16000",
            "Ocp-Apim-Subscription-Key": bingSpeechSubscriptionKey,
            "Host": "speech.platform.bing.com",
            "Transfer-Encoding": "chunked",
            "Expect": "100-continue"
            ]
        
        //REST API request and response handling
        Alamofire.upload(FileURL, to: bingSpeechToTextURL, method: .post, headers: header).responseJSON { response in switch response.result {
            
        case .success(let JSON):
                print("Success with JSON: \(JSON)")
                
                let response = JSON as! NSDictionary
                
                //single out the actual speech to text conversion
                displayText =  response.object(forKey: "DisplayText")
                
                //Set the TextView text property to use the converted Speech to Text string
                self.requestTextView.text = displayText as! String
                
                //Now process the converted text string in LUIS to add a smart element to your app
                //For more information visit http://LUIS.ai
                self.processLUIS(stringToProcess: displayText as! String)
            
            case .failure(let error):
                //HTTP Error occured, handle it!
                self.showError(title: "HTTP Error", description: "Request failed with error: \(error)", buttonTitle: "OK")
            }
        }
    }
    
    func processLUIS(stringToProcess: String) {
        
        let parameters: Parameters = [
            "q": stringToProcess
        ]
        
        //REST API request and response handling
        Alamofire.request(luisURL, method: .get, parameters: parameters).responseJSON { response in
            switch response.result {
                
            case .success(let JSON):
                print("Success with JSON: \(JSON)")
                
                let response = JSON as! NSDictionary
                
                //single out the actual intent through nested keypaths
                let intent = response.value(forKeyPath: "topScoringIntent.intent")
                
                let intentString = intent as! String
                print(intentString)
                
                self.localIntentProcessor(intent: intentString)
                
                
            case .failure(let error):
                //HTTP Error occured, handle it!
                //self.showError(title: "HTTP Error", description: "Request failed with error: \(error)", buttonTitle: "OK")
                print(error)
            }
        }
    }
    
    func bingAccessTokenRequest(stringToSend: String) {
        
        //Get an access token. You need to do this to authorize your Bing Text to Speech request
        
        //REST API Header setup
        let tokenHeader: HTTPHeaders = [
            "Content-type": "application/x-www-form-urlencoded",
            "Content-Length": "0",
            "Ocp-Apim-Subscription-Key": bingSpeechSubscriptionKey,
        ]
        
        //REST API request and response handling
        Alamofire.request(requestTokenURL, method: .post, headers: tokenHeader).responseString { response in switch response.result {
            
            case .success(let rString) :
                //Token request was successful
                print("Token request was successful")
                self.bingTextToSpeech(stringToConvert: stringToSend, accessToken: rString)
            
            case .failure(let error):
                //HTTP Error occured, handle it!
                self.showError(title: "HTTP Error", description: "Request failed with error: \(error)", buttonTitle: "OK")
            }
        }
    }
    
    func bingTextToSpeech(stringToConvert: String, accessToken: String) {
        //Documentation can be found here: https://docs.microsoft.com/en-us/azure/cognitive-services/speech/api-reference-rest/bingvoiceoutput
        
        //REST API Header setup
        let textToSpeechHeader: HTTPHeaders = [
            "X-Microsoft-OutputFormat": "audio-16khz-128kbitrate-mono-mp3",
            "Content-Type": "text/plain",
            "Host": "speech.platform.bing.com",
            "Authorization": "Bearer " + accessToken,
            ]
        
        var request = URLRequest(url: URL(string: bingTextToSpeechURL)!)
        request.httpMethod = HTTPMethod.post.rawValue
        request.allHTTPHeaderFields = textToSpeechHeader
        
        //REST API custom body setup
        let body: String = NSLocalizedString("audioVoice", comment: "") + stringToConvert + "</voice></speak>"
        
        let data = (body.data(using: .utf8))! as Data
        
        request.httpBody = data
        
        //REST API request and response handling
        Alamofire.request(request).responseData { response in switch response.result {

            case .success(let audioData) :
                //Text to Speech conversion was successful, play file
                self.playAudioFile(FileData: audioData)
                
            case .failure(let error):
                //HTTP Error occured, handle it!
                print(error)
                self.showError(title: "HTTP Error", description: "Request failed with error: \(error)", buttonTitle: "OK")
            }
    }
}
    
    //MARK: Swift helper
    
    //Error UI display helper function using a UIAlertController
    func showError(title: String, description: String, buttonTitle: String) {
        let alertController = UIAlertController(title: title, message: description, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func weekdayHelper(Weekday: Int) -> String {
        switch Weekday {
        case 1:
            return NSLocalizedString("sunday", comment: "")
        case 2:
            return NSLocalizedString("monday", comment: "")
        case 3:
            return NSLocalizedString("tuesday", comment: "")
        case 4:
            return NSLocalizedString("wednesday", comment: "")
        case 5:
            return NSLocalizedString("thursday", comment: "")
        case 6:
            return NSLocalizedString("friday", comment: "")
        case 7:
            return NSLocalizedString("saturday", comment: "")
        default:
            return NSLocalizedString("monday", comment: "")
        }
    }
    
    func localIntentProcessor(intent: String) {
        
        var ttsResponse: String
        
        switch intent {
        case "None":
            ttsResponse = NSLocalizedString("didn't_Understand", comment: "")
            bingAccessTokenRequest(stringToSend: ttsResponse)
            
        case "favoriteMusic":
            ttsResponse = NSLocalizedString("favoriteSong", comment: "")
            bingAccessTokenRequest(stringToSend: ttsResponse)
            
        case "Weather":
            ttsResponse = NSLocalizedString("weather", comment: "")
            bingAccessTokenRequest(stringToSend: ttsResponse)
            
        case "Hello":
            ttsResponse = NSLocalizedString("hello", comment: "")
            bingAccessTokenRequest(stringToSend: ttsResponse)
            
        case "ShowTime":
            let date = Date()
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            let minutes = calendar.component(.minute, from: date)
            
            ttsResponse = NSLocalizedString("it_Is", comment: "") + String(hour) + NSLocalizedString("O_Clock", comment: "") + String(minutes)
            bingAccessTokenRequest(stringToSend: ttsResponse)
            
        case "ShowDate":
            let date = Date()
            let calendar = Calendar.current
            let day = calendar.component(.day, from: date)
            let month = calendar.component(.month, from: date)
            let year = calendar.component(.year, from: date)
            
            let weekday = calendar.component(.weekday, from: date)
            
            let weekdayString = weekdayHelper(Weekday: weekday)
            
            let preferredLanguage = Locale.preferredLanguages[0]
            let separatedComponents = prefferedLanguage.components(separatedBy: "-")
            let appLanguage = separatedComponents.first
            
            if appLanguage == "de" {
                //Preferred language is German
                ttsResponse = NSLocalizedString("today_Is", comment: "") + weekdayString + NSLocalizedString("bridging_The", comment: "") + String(day) + "." + String(month) + "." + String(year)
            } else {
            //App defaults to English if the preferred language isn't German
            ttsResponse = NSLocalizedString("today_Is", comment: "") + weekdayString + NSLocalizedString("bridging_The", comment: "") + String(month)  + "/" + String(day) + "/" + String(year)
            }
            
            
            bingAccessTokenRequest(stringToSend: ttsResponse)
            
        case "Facebook":
            ttsResponse = NSLocalizedString("facebook", comment: "")
            bingAccessTokenRequest(stringToSend: ttsResponse)
            
        case "twitter":
            ttsResponse = NSLocalizedString("twitter", comment: "")
            bingAccessTokenRequest(stringToSend: ttsResponse)
            
        case "GoogleMaps":
            ttsResponse = NSLocalizedString("hangOn", comment: "")
            bingAccessTokenRequest(stringToSend: ttsResponse)
        case "SnowHeight":
            ttsResponse = NSLocalizedString("snowConditions", comment: "")
            bingAccessTokenRequest(stringToSend: ttsResponse)
            
        default:
            ttsResponse = NSLocalizedString("didn't_Understand", comment: "")
            bingAccessTokenRequest(stringToSend: ttsResponse)
        }
        luisIntent = intent
        //Set the TextView text property to use the converted Speech to Text string
        self.responseTextView.text = ttsResponse
    }
    
    //MARK: Delegates
    
    //Use audioPlayerDidFinishPlaying to carry out actions after the audio file has been played
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            let luisLocal = luisIntent
            
            switch luisLocal {
                
                case "favoriteMusic"?:
                    if let url = URL(string: "https://www.youtube.com/watch?v=VLFx30Ijiq0") {
                        UIApplication.shared.open(url, options: [:])
                }
                
                case "Weather"?:
                    if let url = URL(string: "https://weather.com") {
                        UIApplication.shared.open(url, options: [:])
                }
                
                case "Facebook"?:
                    let facebookUrl = URL(string: "fb://feed")
                    if UIApplication.shared.canOpenURL(facebookUrl!) {
                        UIApplication.shared.open(facebookUrl!)
                    } else {
                        //Redirect to Safari if native app isn't installed
                        UIApplication.shared.open(URL(string: "http://facebook.com/")!)
                }
                
                case "twitter"?:
                    let twitterUrl = URL(string: "twitter://")
                    if UIApplication.shared.canOpenURL(twitterUrl!) {
                        UIApplication.shared.open(twitterUrl!)
                    } else {
                        //Redirect to Safari if native app isn't installed
                        UIApplication.shared.open(URL(string: "http://twitter.com/")!)
                }
                
                case "GoogleMaps"?:
                        let gMapsUrl = URL(string: "comgooglemaps://?q=")
                        if UIApplication.shared.canOpenURL(gMapsUrl!) {
                            UIApplication.shared.open(gMapsUrl!)
                        } else {
                            //Redirect to Safari if native app isn't installed
                            UIApplication.shared.open(URL(string: "http://maps.google.com/")!)
                        }
                case "SnowHeight"?:
                if let url = URL(string: "http://www.snow-forecast.com") {
                    UIApplication.shared.open(url, options: [:])
                }
                
            default: print("String luisIntent == nil")
            }
        }
    }
}
