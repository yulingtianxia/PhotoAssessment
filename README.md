# PhotoAssessment

Photo Assessment using Core ML and Metal.

![](https://github.com/yulingtianxia/Blog-Hexo-Source/blob/master/source/resources/PhotoAssessment/AssessmentResult1.png?raw=true)![](https://github.com/yulingtianxia/Blog-Hexo-Source/blob/master/source/resources/PhotoAssessment/AssessmentResult2.png?raw=true)

## Article

- [使用 Metal 和 Core ML 评价照片质量](http://yulingtianxia.com/blog/2018/11/30/Photo-Assessment/)

## ConvertMLModel

Convert NIMA model to Core ML format.

## PhotoAssessmentKit

Support iOS、tvOS.
Demo: PhotoAssessment-iOSSample

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

## PhotoAssessmentMacKit

Support macOS.
