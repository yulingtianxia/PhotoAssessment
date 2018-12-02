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

![](https://github.com/yulingtianxia/Blog-Hexo-Source/blob/master/source/resources/PhotoAssessment/AssessmentResult1.png?raw=true)![](https://github.com/yulingtianxia/Blog-Hexo-Source/blob/master/source/resources/PhotoAssessment/AssessmentResult2.png?raw=true)

## Article

- [使用 Metal 和 Core ML 评价照片质量](http://yulingtianxia.com/blog/2018/11/30/Photo-Assessment/)

## ConvertMLModel

Convert NIMA model to Core ML format.

## PhotoAssessment-Sample

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
