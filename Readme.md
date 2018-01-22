# Anna
Meet Anna, my custom Voice Assistant. 

## Currently Supported Languages

Anna currently supports English and German. Feel free to add LUIS models in other languages. Please don't forget to update the code accordingly. 

## Library & API Usage
[Alamofire](https://github.com/Alamofire/Alamofire) was used to make REST API calls easier and avoid boilerplate code

[Bing Speech-to-Text](https://azure.microsoft.com/en-us/services/cognitive-services/speech/), 
[LUIS](https://luis.ai) & 
[Bing Text-to-Speech](https://azure.microsoft.com/en-us/services/cognitive-services/speech/) were used for audio processing

## Compiling the App
If you're using this app within 2 days of attending one of my talks the provided Azure subscription keys and LUIS URL will work. 
Otherwise you'll have to use your own subscription keys and LUIS URL. Subscription keys can be generated here:  [Azure Portal](https://portal.azure.com), a LUIS URL can be generated here: [LUIS](https://luis.ai). 

The subscription key and LUIS URL constants can be found in the top section of ViewController.swift. 

Please remove `&q=` from the very end of the LUIS domain. `&q=` will later be appended by the app.

Before you can compile the app, you'll need to install Alamofire. Using CocoaPods to do so is highly recommended. 

Use terminal to execute the following commands: 
if Cocoapods isn't installed or you're not sure, execute
`sudo gem install cocoapods`

Once CocoaPods is installed, execute
`cd ~/Path/To/Folder/Containing/VoiceAssistant-iOS`

`pod install`

Open `VoiceAssistant-iOS.xcworkspace`

Provide a Team under Target Signing

The app should now compile. 

Note: Please use `VoiceAssistant-iOS.xcworkspace` only. 
`VoiceAssistant-iOS.xcodeproj` doesn't include CocoaPods and will therefore not work. 

## Deploying LUIS.ai model
The model information is located in `VoiceAssistantDemo.json` in each respective language's folder in the folder `LUIS`. 
Visit [LUIS](https://luis.ai) and click "import new app". 

## To-Do's
-Add english language support to iOS App

-Replace LUIS URL with App ID and subscription Key

-Fix Start/Stop button Outlet