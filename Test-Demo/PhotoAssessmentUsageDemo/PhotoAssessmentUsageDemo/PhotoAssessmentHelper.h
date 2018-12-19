//
//  PhotoAssessmentHelper.h
//  PhotoAssessmentUsageDemo
//
//  Created by 杨萧玉 on 2018/11/30.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HSBColor;
@class PhotoAssessmentResult;

NS_ASSUME_NONNULL_BEGIN
API_AVAILABLE(ios(11.0))
@interface PhotoAssessmentHelper : NSObject

- (void)requestMLAssessmentScoreFor:(CGImageRef)image completionHandler:(void(^)(double))completionHandler;
- (void)requestMPSAssessmentScoreFor:(CGImageRef)image completionHandler:(void (^)(PhotoAssessmentResult *))completionHandler;

@end

@interface PhotoAssessmentResult : NSObject <NSSecureCoding>

@property (nonatomic, assign) int8_t edgeDetectMean;
@property (nonatomic, assign) int8_t edgeDetectVariance;
@property (nonatomic, strong) HSBColor *hsb;
@property (nonatomic, strong) NSDictionary<NSNumber *, NSNumber *> *fingerprint;
@property (nonatomic, assign) double contentScore;

- (BOOL)betterThan:(PhotoAssessmentResult *)anotherResult;
- (double)totalScore;

@end

NS_ASSUME_NONNULL_END
