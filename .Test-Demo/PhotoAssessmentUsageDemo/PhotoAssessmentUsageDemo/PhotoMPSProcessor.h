//
//  PhotoMPSProcessor.h
//  PhotoAssessmentUsageDemo
//
//  Created by 杨萧玉 on 2018/11/30.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

API_AVAILABLE(ios(11.0))
@interface PhotoMPSProcessor : NSObject

- (void)downsampleWithImagePixels:(int32_t *)imagePixels width:(NSInteger)width height:(NSInteger)height scaleDimension:(NSInteger)scaleDimension completionHandler:(void (^)(NSArray<NSNumber *> * _Nullable))block;
- (void)edgeDetectWithImagePixels:(int32_t *)imagePixels width:(NSInteger)width height:(NSInteger)height completionHandler:(void (^)(int8_t, int8_t))block;

@end

NS_ASSUME_NONNULL_END
