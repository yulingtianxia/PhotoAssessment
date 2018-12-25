//
//  PhotoMLProcessor.h
//  PhotoAssessmentUsageDemo
//
//  Created by 杨萧玉 on 2018/12/4.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PhotoMLProcessor : NSObject

- (void)processImage:(CGImageRef)image completionHandler:(void(^)(double))completionHandler;

@end

NS_ASSUME_NONNULL_END
