//
//  PhotoScanner.m
//  PhotoAssessmentUsageDemo
//
//  Created by 杨萧玉 on 2018/11/20.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

#import "PhotoScanner.h"
#import <Photos/Photos.h>

@implementation PhotoScanner

+ (NSArray<PHAsset *> *)scanPhotosWithLimit:(NSUInteger)fetchLimit
{
    return [self scanPhotosWithLimit:fetchLimit afterDate:nil latest:YES];
}

+ (NSArray<PHAsset *> *)scanPhotosWithLimit:(NSUInteger)fetchLimit afterDate:(NSDate *)startDate latest:(BOOL)latest
{
    if (!startDate) {
        startDate = [NSDate dateWithTimeIntervalSince1970:0];
    }
    
    NSMutableArray<PHAsset *> *photos = [NSMutableArray array];
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:!latest]];
    
    // a workaround for Apple's bug!!! https://forums.developer.apple.com/thread/44133
    
    if (@available(iOS 9.0, *)) {
        fetchOptions.fetchLimit = fetchLimit;
        fetchOptions.includeAssetSourceTypes = PHAssetSourceTypeUserLibrary | PHAssetSourceTypeCloudShared | PHAssetSourceTypeiTunesSynced;
        fetchOptions.predicate = [NSPredicate predicateWithFormat:@"(pixelWidth >= 240 && pixelHeight >= 240) && (creationDate > %@) && (mediaType == %ld) && (NOT ((mediaSubtype & %lu) != 0)) && (NOT ((mediaSubtype & %lu) != 0))", startDate, (long)PHAssetMediaTypeImage, (unsigned long)PHAssetMediaSubtypePhotoPanorama, (unsigned long)PHAssetMediaSubtypePhotoScreenshot];
    }
    else {
        fetchOptions.predicate = [NSPredicate predicateWithFormat:@"(pixelWidth >= 240 && pixelHeight >= 240) && (creationDate > %@) && (mediaType == %ld) && (NOT ((mediaSubtype & %lu) != 0))", startDate, (long)PHAssetMediaTypeImage, (unsigned long)PHAssetMediaSubtypePhotoPanorama];
    }
    
    PHFetchResult<PHAsset *> *assetsFetchResult = [PHAsset fetchAssetsWithOptions:fetchOptions];
    NSUInteger maxCount = fetchLimit > 0 ? MIN(fetchLimit, assetsFetchResult.count) : assetsFetchResult.count;
    // 低于 iOS9 的版本还需要手动限制下返回的张数。
    for (int i = 0; i < maxCount; i ++) {
        PHAsset *asset = assetsFetchResult[i];
        [photos addObject:asset];
    }
    [photos sortUsingComparator:^NSComparisonResult(PHAsset * _Nonnull obj1, PHAsset * _Nonnull obj2) {
        return [obj1.creationDate compare:obj2.creationDate];
    }];
    return photos;
}


@end
