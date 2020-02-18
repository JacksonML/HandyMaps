# HandyMaps
## UGAHacks 5 Project
HandyMaps is a solution for improving the accessibility of Google Maps's walking navigation feature. The goal of this project is to target wheel-chair accessible entrances to buildings. The project is made to be easily expandable to other college campuses or even cities. Multiple layers of info can also be applied, as can be seen with the outdoor trashcan layer.

We encountered a few challenges while making this project, primarily that no one on my team had really worked with Xcode, the iOS SDK, or the Google Maps for iOS SDK. We had to dive in head first into the documentation and figure out what to do. Our whole team is very proud of how much we've learned and accomplished over the past couple of days, making a smooth, interactive app that has the potential to help people.

## Running from source
```
git clone https://github.com/JacksonML/HandyMaps
cd HandyMaps
pod install
```
If the GoogleMaps SDK that is installed is not version `3.7`, run `pod update`

Open `HandyMaps.xcworkspace` with Xcode

You will need to provide your own Google Cloud API Key in `AppDelegate.swift` and `ViewController.swift`
Your API credential will need to have `Directions API` ,`Maps SKD for iOS`, and `Places API` enabled.

Build for your device, then launch it!
