//
//  PhotoMLProcessor.m
//  PhotoAssessmentUsageDemo
//
//  Created by 杨萧玉 on 2018/12/4.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

#import "PhotoMLProcessor.h"
#import <CoreML/CoreML.h>
#import <Vision/Vision.h>
#import "MobileNet.h"

@interface PhotoMLProcessor ()

@property (nonatomic, strong) MobileNet *nima;
@property (nonatomic, strong) VNCoreMLModel *model;
@property (nonatomic, assign) double score;
@property (nonatomic, strong) dispatch_queue_t processQueue;
@property (nonatomic, strong) VNCoreMLRequest *assessmentRequest;
@property (nonatomic, strong) NSURL *url;

@end

@implementation PhotoMLProcessor

- (instancetype)init
{
    self = [super init];
    if (self) {
        _processQueue = dispatch_queue_create("com.photoassessment.mlprocessor", DISPATCH_QUEUE_SERIAL);
        _score = 0;
    }
    return self;
}

- (MobileNet *)nima
{
    if (!_nima) {
        _nima = [MobileNet new];
    }
    return _nima;
}

- (VNCoreMLModel *)model
{
    if (!_model) {
        NSError *error = nil;
//        if (!self.url) {
//            return nil;
//        }
//        NSURL *compiledUrl = [MLModel compileModelAtURL:self.url error:&error];
//        if (error) {
//            NSLog(@"Failed to load Vision ML model NIMANasnet:%@", error.localizedDescription);
//            return nil;
//        }
//        MLModel *mlModel = [MLModel modelWithContentsOfURL:compiledUrl error:&error];
//        if (error) {
//            NSLog(@"Failed to load Vision ML model NIMANasnet:%@", error.localizedDescription);
//            return nil;
//        }
        _model = [VNCoreMLModel modelForMLModel:self.nima.model error:&error];
        if (error) {
            NSLog(@"Failed to load Vision ML model NIMANasnet:%@", error.localizedDescription);
            return nil;
        }
    }
    return _model;
}

- (VNCoreMLRequest *)assessmentRequest
{
    if (!_assessmentRequest) {
        if (!self.model) {
            return nil;
        }
        _assessmentRequest = [[VNCoreMLRequest alloc] initWithModel:self.model];
        _assessmentRequest.imageCropAndScaleOption = VNImageCropAndScaleOptionScaleFill;
    }
    return _assessmentRequest;
}

- (double)processNIMAForRequest:(VNRequest *)request
{
    double result = 0;
    if ([request.results.firstObject isKindOfClass:VNCoreMLFeatureValueObservation.class]) {
        MLMultiArray *scores = ((VNCoreMLFeatureValueObservation *)request.results.firstObject).featureValue.multiArrayValue;
        for (int i = 0; i < scores.count; i ++) {
            result += scores[i].doubleValue * (i + 1);
        }
        return result;
    }
    else {
        return 0;
    }
}

- (void)processImage:(CGImageRef)image completionHandler:(void(^)(double))completionHandler
{
    if (!completionHandler) {
        return;
    }
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCGImage:image options:@{}];
    dispatch_async(self.processQueue, ^{
//        if (!self.url) {
//            NSURLSessionDownloadTask *task = [[NSURLSession sharedSession] downloadTaskWithURL:[NSURL URLWithString:@"https://raw.githubusercontent.com/yulingtianxia/PhotoAssessment/master/PhotoAssessment-Sample/Sources/MobileNet.mlmodel"] completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//                if (error) {
//                    return;
//                }
//                NSFileManager *fileManager = [NSFileManager defaultManager];
//                NSURL *fileURL = [[fileManager URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:location create:YES error:&error] URLByAppendingPathComponent:[[response URL] lastPathComponent]];
//                if (error) {
//                    return;
//                }
//                if ([fileManager fileExistsAtPath:[fileURL path] isDirectory:NULL]) {
//                    [fileManager removeItemAtURL:fileURL error:NULL];
//                }
//                [fileManager moveItemAtURL:location toURL:fileURL error:NULL];
//                self.url = fileURL;
//                if (self.assessmentRequest) {
//                    [handler performRequests:@[self.assessmentRequest] error:&error];
//                    if (error) {
//                        NSLog(@"Failed to perform Assessment. %@", error.localizedDescription);
//                    }
//                    double score = 0;
//                    score = [self processNIMAForRequest:self.assessmentRequest];
//                    completionHandler(score);
//                }
//                else {
//                    completionHandler(0);
//                }
//            }];
//            [task resume];
//        }
//        else {
            NSError *error = nil;
            if (self.assessmentRequest) {
                [handler performRequests:@[self.assessmentRequest] error:&error];
                if (error) {
                    NSLog(@"Failed to perform Assessment. %@", error.localizedDescription);
                }
                double score = 0;
                score = [self processNIMAForRequest:self.assessmentRequest];
                completionHandler(score);
            }
            else {
                completionHandler(0);
            }
//        }
        
    });
}

@end
