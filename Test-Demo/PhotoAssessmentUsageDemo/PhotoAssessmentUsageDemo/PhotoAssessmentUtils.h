//
//  PhotoAssessmentUtils.h
//  PhotoAssessmentUsageDemo
//
//  Created by 杨萧玉 on 2018/11/30.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HSBColor;

NS_ASSUME_NONNULL_BEGIN

@interface PhotoAssessmentUtils : NSObject

+ (NSDictionary<NSNumber *, NSNumber *> *)fingerprintForImagePixels:(NSArray<NSNumber *> *)imagePixels width:(NSInteger)width height:(NSInteger)height;
+ (HSBColor *)meanHSBForImagePixels:(NSArray<NSNumber *> *)imagePixels width:(NSInteger)width height:(NSInteger)height;

@end

@interface HSBColor : NSObject <NSSecureCoding>

@property (nonatomic, assign) double hue;
@property (nonatomic, assign) double saturation;
@property (nonatomic, assign) double brightness;

@end

NS_ASSUME_NONNULL_END
