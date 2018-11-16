//
//  FingerPrint.h
//  PhotoFingerPrint
//
//  Created by 杨萧玉 on 2018/11/16.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FingerPrint : NSObject

+ (NSDictionary *)fingerPrintForURL:(NSURL *)url maxSize:(CGFloat)size;

@end

NS_ASSUME_NONNULL_END
