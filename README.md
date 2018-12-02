[![CI Status](http://img.shields.io/travis/yulingtianxia/PhotoAssessment.svg?style=flat)](https://travis-ci.org/yulingtianxia/PhotoAssessment)
[![Version](https://img.shields.io/cocoapods/v/PhotoAssessment.svg?style=flat)](http://cocoapods.org/pods/PhotoAssessment)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/PhotoAssessment.svg?style=flat)](http://cocoapods.org/pods/PhotoAssessment)
[![Platform](https://img.shields.io/cocoapods/p/PhotoAssessment.svg?style=flat)](http://cocoapods.org/pods/PhotoAssessment)
[![CocoaPods](https://img.shields.io/cocoapods/dt/PhotoAssessment.svg)](http://cocoapods.org/pods/PhotoAssessment)
[![CocoaPods](https://img.shields.io/cocoapods/at/PhotoAssessment.svg)](http://cocoapods.org/pods/PhotoAssessment)
[![Twitter Follow](https://img.shields.io/twitter/follow/yulingtianxia.svg?style=social&label=Follow)](https://twitter.com/yulingtianxia)

# PhotoAssessment

Photo Assessment using Core ML and Metal.

## 📚 Article

- [使用 Metal 和 Core ML 评价照片质量](http://yulingtianxia.com/blog/2018/11/30/Photo-Assessment/)

## 🔮 Example

To run the example project, clone the repo and run PhotoAssessment target.

![](https://github.com/yulingtianxia/Blog-Hexo-Source/blob/master/source/resources/PhotoAssessment/AssessmentResult1.png?raw=true)![](https://github.com/yulingtianxia/Blog-Hexo-Source/blob/master/source/resources/PhotoAssessment/AssessmentResult2.png?raw=true)

## 🐒 How to use

`PhotoAssessmentHelper` generates assessment result quicker and easier, using far less code.

```
self.helper.requestMLAssessmentScore(for: downsampleImage, completionHandler: { (score) in
    DispatchQueue.main.async {
        self.assessmentLabel.text = String(format: "Assessment Score:%0.5f", score)
    }
})
self.helper.requestMPSAssessmentScore(for: downsampleImage, completionHandler: { (result) in
    DispatchQueue.main.async {
        self.detailLabel.text = result.description
    }
})
```

### PhotoAssessmentKit

Support iOS、tvOS.

### PhotoAssessmentMacKit

Support macOS.

### ConvertMLModel

Convert NIMA model to Core ML format.

## 📲 Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate PhotoAssessment into your Xcode project using CocoaPods, specify it in your `Podfile`:


```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'
use_frameworks!
target 'MyApp' do
	pod 'PhotoAssessment'
end
```

You need replace "MyApp" with your project's name.

Then, run the following command:

```bash
$ pod install
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate PhotoAssessment into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "yulingtianxia/PhotoAssessment"
```

Run `carthage update` to build the framework and drag the built `PhotoAssessmentKit.framework` into your Xcode project.

### Manual

Just drag the "Sources" document folder into your project.

## ❤️ Contributed

- If you **need help** or you'd like to **ask a general question**, open an issue.
- If you **found a bug**, open an issue.
- If you **have a feature request**, open an issue.
- If you **want to contribute**, submit a pull request.

## 👨🏻‍💻 Author

yulingtianxia, yulingtianxia@gmail.com

## 👮🏻 License

PhotoAssessment is available under the MIT license. See the LICENSE file for more info.