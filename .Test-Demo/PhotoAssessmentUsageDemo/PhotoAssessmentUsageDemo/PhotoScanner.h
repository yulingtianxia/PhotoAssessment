//
//  PhotoScanner.h
//  PhotoAssessmentUsageDemo
//
//  Created by 杨萧玉 on 2018/11/20.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

#import <Foundation/Foundation.h>
@class PHAsset;

NS_ASSUME_NONNULL_BEGIN

@interface PhotoScanner : NSObject

/**
 扫描系统相册照片
 
 @param fetchLimit 扫描数量上限。如果为0，则会扫描所有照片。
 @return 照片数组
 */
+ (NSArray<PHAsset *> *)scanPhotosWithLimit:(NSUInteger)fetchLimit;
/**
 扫描系统相册照片
 
 @param fetchLimit 扫描数量上限。如果为0，则会扫描所有照片。
 @param startDate 扫描起始时间。
 @param latest 是否取最近时间的照片
 @return 照片数组
 */
+ (NSArray<PHAsset *> *)scanPhotosWithLimit:(NSUInteger)fetchLimit afterDate:(nullable NSDate *)startDate latest:(BOOL)latest;

@end

NS_ASSUME_NONNULL_END
