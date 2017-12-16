# HAL1000
Meet Hal, my custom Voice Assistant. 

## Library & API Usage
Alamofire was used to make REST API calls easier and avoid boilerplate code

## Compiling the App
If you're using this app within 2 days of attending one of my talks the provided Azure subscription keys will work. 
Otherwise you'll have to use your own subscription keys. Subscription keys can be generated on https://portal.azure.com

The subscription key constants can be found in the top section of ViewController.swift. 

Before you can compile the app, you'll need to install Alamofire. Using CocoaPods is highly recommended. 

Use terminal to execute the following commands: 
if Cocoapods isn't installed or you're not sure, execute
`sudo gem install cocoapods`

Once CocoaPods is installed, execute
`cd ~/Path/To/Folder/Containing/VoiceAssistant-iOS`

`pod install`

Open VoiceAssistant-iOS.xcworkspace

Set the MainInterface under Target Deployment info to "iPhone" or "iPad". 
Provide a Team under Target Signing

The app should now compile. 

Note: Please use VoiceAssistant-iOS.xcworkspace only. 
VoiceAssistant-iOS.xcodeproj doesn't include CocoaPods and will therefore not work. 

