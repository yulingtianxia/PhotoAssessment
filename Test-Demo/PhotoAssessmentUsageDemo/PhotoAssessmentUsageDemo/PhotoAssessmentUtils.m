//
//  PhotoAssessmentUtils.m
//  PhotoAssessmentUsageDemo
//
//  Created by 杨萧玉 on 2018/11/30.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

#import "PhotoAssessmentUtils.h"

#define Mask8(x) ( (x) & 0xFF )
#define A(x) ( Mask8(x) )
#define B(x) ( Mask8(x >> 8 ) )
#define G(x) ( Mask8(x >> 16) )
#define R(x) ( Mask8(x >> 24) )
#define RGBAMake(r, g, b, a) ( Mask8(a) | Mask8(b) << 8 | Mask8(g) << 16 | Mask8(r) << 24 )

@implementation PhotoAssessmentUtils

+ (NSDictionary<NSNumber *, NSNumber *> *)fingerprintForImagePixels:(NSArray<NSNumber *> *)imagePixels width:(NSInteger)width height:(NSInteger)height
{
    NSMutableDictionary<NSNumber *, NSNumber *> *bucket = [NSMutableDictionary dictionary];
    for (int j = 0; j < height; j ++) {
        for (int i = 0; i < width; i ++) {
            NSUInteger color = [imagePixels[width * j + i] unsignedIntegerValue];
            NSUInteger fingerprint = RGBAMake([self downsampleComponent:R(color)],
                     [self downsampleComponent:G(color)],
                     [self downsampleComponent:B(color)],
                     [self downsampleX:i y:j w:width h:height]);
            bucket[@(fingerprint)] = @(bucket[@(fingerprint)].unsignedIntegerValue + 1);
        }
    }
    [bucket enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        bucket[key] = @(obj.doubleValue / imagePixels.count);
    }];
    return bucket;
}

+ (UInt32)downsampleComponent:(UInt8)component
{
    return (UInt32)component / 16;
}

+ (UInt32)downsampleX:(NSInteger)x y:(NSInteger)y w:(NSInteger)width h:(NSInteger)height
{
    NSInteger rowCount = MIN(4, height);
    NSInteger countPerRow = MIN(4, width);
    NSInteger hStep = width / countPerRow;
    NSInteger vStep = height / rowCount;
    NSInteger row = y / vStep;
    NSInteger col = x / hStep;
    return (UInt32)(row * countPerRow + col);
}

+ (HSBColor *)meanHSBForImagePixels:(NSArray<NSNumber *> *)imagePixels width:(NSInteger)width height:(NSInteger)height
{
    CGFloat meanHue = 0, meanSaturation = 0, meanBrightness = 0;
    for (NSNumber *pixel in imagePixels) {
        NSUInteger colorHex = [pixel unsignedIntegerValue];
        UIColor *color = [UIColor colorWithRed:R(colorHex) green:G(colorHex) blue:B(colorHex) alpha:A(colorHex)];
        CGFloat hue, saturation, brightness;
        [color getHue:&hue saturation:&saturation brightness:&brightness alpha:nil];
        meanHue += hue;
        meanSaturation += saturation;
        meanBrightness += brightness;
    }
    HSBColor *hsb = [HSBColor new];
    hsb.hue = meanHue / imagePixels.count;
    hsb.saturation = meanSaturation / imagePixels.count;
    hsb.brightness = meanBrightness / imagePixels.count;
    return hsb;
}

@end

@implementation HSBColor

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeDouble:self.hue forKey:@"hue"];
    [aCoder encodeDouble:self.saturation forKey:@"saturation"];
    [aCoder encodeDouble:self.brightness forKey:@"brightness"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    if (self = [self init]) {
        self.hue = [aDecoder decodeDoubleForKey:@"hue"];
        self.saturation = [aDecoder decodeDoubleForKey:@"saturation"];
        self.brightness = [aDecoder decodeDoubleForKey:@"brightness"];
    }
    return self;
}

@end
