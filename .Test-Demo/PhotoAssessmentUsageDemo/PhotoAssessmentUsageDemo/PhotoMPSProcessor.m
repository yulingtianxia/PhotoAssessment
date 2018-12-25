//
//  PhotoMPSProcessor.m
//  PhotoAssessmentUsageDemo
//
//  Created by 杨萧玉 on 2018/11/30.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

#import "PhotoMPSProcessor.h"
#import <UIKit/UIKit.h>
#import <MetalPerformanceShaders/MetalPerformanceShaders.h>

@interface PhotoMPSProcessor ()

@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;

@end

@implementation PhotoMPSProcessor

- (instancetype)init
{
    self = [super init];
    if (self) {
        _device = MTLCreateSystemDefaultDevice();
        _commandQueue = [self.device newCommandQueue];
    }
    return self;
}

- (void)downsampleWithImagePixels:(int32_t *)imagePixels width:(NSInteger)width height:(NSInteger)height scaleDimension:(NSInteger)scaleDimension completionHandler:(void (^)(NSArray<NSNumber *> * _Nullable))block
{
    if (!block) {
        return;
    }
    // Make sure the current device supports MetalPerformanceShaders.
    if (!MPSSupportsMTLDevice(self.device)) {
        block(nil);
        return;
    }
    // TextureDescriptors
    MTLTextureDescriptor *scaleSrcTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Snorm width:width height:height mipmapped:NO];
    scaleSrcTextureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
    
    MTLTextureDescriptor *scalaDesTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Snorm width:scaleDimension height:scaleDimension mipmapped:NO];
    scalaDesTextureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
    // Textures
    id<MTLTexture> scaleSrcTexture = [self.device newTextureWithDescriptor:scaleSrcTextureDescriptor];
    id<MTLTexture> scaleDesTexture = [self.device newTextureWithDescriptor:scalaDesTextureDescriptor];
    if (scaleSrcTexture == nil || scaleDesTexture == nil) {
        block(nil);
        return;
    }
    // Fill sobelSrcTexture with pixels
    MTLRegion scaleRegion = MTLRegionMake2D(0, 0, width, height);
    [scaleSrcTexture replaceRegion:scaleRegion mipmapLevel:0 withBytes:imagePixels bytesPerRow:4 * width];
    // Run Image Filters
    id<MTLCommandBuffer> commandBuffer = self.commandQueue.commandBuffer;
    if (commandBuffer == nil) {
        block(nil);
        return;
    }
    MPSImageBilinearScale *scale = [[MPSImageBilinearScale alloc] initWithDevice:self.device];
    [scale encodeToCommandBuffer:commandBuffer sourceTexture:scaleSrcTexture destinationTexture:scaleDesTexture];
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull buffer) {
        int32_t *result = (int32_t *)calloc(scaleDimension * scaleDimension, sizeof(int32_t));
        MTLRegion region = MTLRegionMake2D(0, 0, scaleDimension, scaleDimension);
        [scaleDesTexture getBytes:result bytesPerRow:4 * scaleDimension fromRegion:region mipmapLevel:0];
        NSMutableArray<NSNumber *> *resultArr = [NSMutableArray arrayWithCapacity:scaleDimension * scaleDimension];
        int32_t *currentPixel = result;
        for (int i = 0; i < scaleDimension * scaleDimension; i ++) {
            [resultArr addObject:@(*currentPixel)];
            currentPixel ++;
        }
        free(result);
        block([resultArr copy]);
    }];
    [commandBuffer commit];
}

- (void)edgeDetectWithImagePixels:(int32_t *)imagePixels width:(NSInteger)width height:(NSInteger)height completionHandler:(void (^)(int8_t, int8_t))block
{
    if (!block) {
        return;
    }
    // Make sure the current device supports MetalPerformanceShaders.
    if (!MPSSupportsMTLDevice(self.device)) {
        block(0, 0);
        return;
    }
    // TextureDescriptors
    MTLTextureDescriptor *sobelSrcTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Snorm width:width height:height mipmapped:NO];
    sobelSrcTextureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
    
    MTLTextureDescriptor *sobelDesTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Snorm width:width height:height mipmapped:NO];
    sobelDesTextureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
    
    MTLTextureDescriptor *varianceTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR8Snorm width:2 height:1 mipmapped:NO];
    varianceTextureDescriptor.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
    // Textures
    id<MTLTexture> sobelSrcTexture = [self.device newTextureWithDescriptor:sobelSrcTextureDescriptor];
    id<MTLTexture> sobelDesTexture = [self.device newTextureWithDescriptor:sobelDesTextureDescriptor];
    id<MTLTexture> varianceTexture = [self.device newTextureWithDescriptor:varianceTextureDescriptor];
    if (sobelSrcTexture == nil || sobelDesTexture == nil || varianceTexture == nil) {
        block(0, 0);
        return;
    }
    // Fill sobelSrcTexture with pixels
    MTLRegion sobelRegion = MTLRegionMake2D(0, 0, width, height);
    [sobelSrcTexture replaceRegion:sobelRegion mipmapLevel:0 withBytes:imagePixels bytesPerRow:4 * width];
    // Run Image Filters
    id<MTLCommandBuffer> commandBuffer = self.commandQueue.commandBuffer;
    if (commandBuffer == nil) {
        block(0, 0);
        return;
    }
    MPSImageSobel *sobel = [[MPSImageSobel alloc] initWithDevice:self.device];
    MPSImageStatisticsMeanAndVariance *meanAndVariance = [[MPSImageStatisticsMeanAndVariance alloc] initWithDevice:self.device];
    [sobel encodeToCommandBuffer:commandBuffer sourceTexture:sobelSrcTexture destinationTexture:sobelDesTexture];
    [meanAndVariance encodeToCommandBuffer:commandBuffer sourceTexture:sobelDesTexture destinationTexture:varianceTexture];
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull buffer) {
        int8_t *result = (int8_t *)calloc(2 * 1, sizeof(int8_t));
        MTLRegion region = MTLRegionMake2D(0, 0, 2, 1);
        [varianceTexture getBytes:result bytesPerRow:1 * 2 fromRegion:region mipmapLevel:0];
        int8_t *currentPixel = result;
        int8_t mean = *currentPixel;
        currentPixel ++;
        int8_t variance = *currentPixel;
        block(mean, variance);
        free(result);
    }];
    [commandBuffer commit];
}

@end
