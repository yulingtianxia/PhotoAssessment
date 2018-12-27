//
//  PhotoAssessmentHelper.m
//  PhotoAssessmentUsageDemo
//
//  Created by 杨萧玉 on 2018/11/30.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

#import "PhotoAssessmentHelper.h"
#import "PhotoAssessmentUtils.h"
#import "PhotoMPSProcessor.h"
#import "PhotoMLProcessor.h"
#import <Metal/Metal.h>

API_AVAILABLE(ios(11.0))
@interface PhotoAssessmentHelper ()

@property (nonatomic, strong) PhotoMPSProcessor *mpsProcessor;
@property (nonatomic, strong) PhotoMLProcessor *mlProcessor;
@property (nonatomic, strong) dispatch_queue_t processQueue;

@end

@implementation PhotoAssessmentHelper

- (instancetype)init
{
    self = [super init];
    if (self) {
        if (@available(iOS 11.0, *)) {
            _mpsProcessor = [PhotoMPSProcessor new];
            _mlProcessor = [PhotoMLProcessor new];
        } else {
            // Fallback on earlier versions
        }
        _processQueue = dispatch_queue_create("com.photoassessment.helper", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)requestMLAssessmentScoreFor:(CGImageRef)image completionHandler:(void(^)(double))completionHandler
{
    return [self.mlProcessor processImage:image completionHandler:completionHandler];
}

- (void)requestMPSAssessmentScoreFor:(CGImageRef)image completionHandler:(void (^)(PhotoAssessmentResult *))completionHandler
{
    if (!completionHandler) {
        return;
    }
    CGImageRetain(image);
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
        
        NSUInteger width = CGImageGetWidth(image);
        NSUInteger height = CGImageGetHeight(image);
        int32_t *pixels = (int32_t *)calloc(height * width, sizeof(int32_t));
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(pixels, width, height,
                                                     8, 4 * width, colorSpace,
                                                     kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Little);
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
        
        
        PhotoAssessmentResult *totalResult = [PhotoAssessmentResult new];
        dispatch_group_t group = dispatch_group_create();
        CGFloat side = 32;
        dispatch_group_enter(group);
        [self.mlProcessor processImage:image completionHandler:^(double score) {
            totalResult.contentScore = score;
            dispatch_group_leave(group);
        }];
        
        CGImageRelease(image);
        dispatch_group_enter(group);
        [self.mpsProcessor downsampleWithImagePixels:pixels width:width height:height scaleDimension:side completionHandler:^(NSArray<NSNumber *> * _Nullable result) {
            if (result) {
                NSDictionary<NSNumber *, NSNumber *> *fingerprint = [PhotoAssessmentUtils fingerprintForImagePixels:result width:side height:side];
                HSBColor *hsb = [PhotoAssessmentUtils meanHSBForImagePixels:result width:side height:side];
                dispatch_async(self.processQueue, ^{
                    totalResult.fingerprint = fingerprint;
                    totalResult.hsb = hsb;
                    dispatch_group_leave(group);
                });
            }
            else {
                dispatch_group_leave(group);
            }
        }];
        dispatch_group_enter(group);
        [self.mpsProcessor edgeDetectWithImagePixels:pixels width:width height:height completionHandler:^(int8_t mean, int8_t variance) {
            dispatch_async(self.processQueue, ^{
                totalResult.edgeDetectMean = mean;
                totalResult.edgeDetectVariance = variance;
                dispatch_group_leave(group);
            });
        }];
        
        CGColorSpaceRelease(colorSpace);
        CGContextRelease(context);
        free(pixels);
        dispatch_group_notify(group, self.processQueue, ^{
            completionHandler(totalResult);
        });
    });
}

@end

@implementation PhotoAssessmentResult

- (NSString *)description
{
    return [NSString stringWithFormat:@"EdgeDetect mean:%d, variance:%d\nHSB: h(%.3f), s(%.3f), b(%.3f)\nContentScore:%f", self.edgeDetectMean, self.edgeDetectVariance, self.hsb.hue, self.hsb.saturation, self.hsb.brightness, self.contentScore];
}

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeInteger:self.edgeDetectMean forKey:@"edgeDetectMean"];
    [aCoder encodeInteger:self.edgeDetectVariance forKey:@"edgeDetectVariance"];
    [aCoder encodeObject:self.hsb forKey:@"hsb"];
    [aCoder encodeObject:self.fingerprint forKey:@"fingerprint"];
    [aCoder encodeDouble:self.contentScore forKey:@"contentScore"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    if (self = [self init]) {
        self.edgeDetectMean = [aDecoder decodeIntegerForKey:@"edgeDetectMean"];
        self.edgeDetectVariance = [aDecoder decodeIntegerForKey:@"edgeDetectVariance"];
        self.hsb = [aDecoder decodeObjectForKey:@"hsb"];
        self.fingerprint = [aDecoder decodeObjectForKey:@"fingerprint"];
        self.contentScore = [aDecoder decodeDoubleForKey:@"contentScore"];
    }
    return self;
}

- (double)totalScore
{
//    return self.contentScore;
    return self.hsb.saturation * (self.edgeDetectMean + self.edgeDetectVariance);
}

- (BOOL)betterThan:(PhotoAssessmentResult *)anotherResult
{
    double scoreA = [self totalScore];
    double scoreB = [anotherResult totalScore];
    return scoreA > scoreB;
}

@end
