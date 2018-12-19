//
//  ViewController.m
//  PhotoAssessmentUsageDemo
//
//  Created by 杨萧玉 on 2018/11/20.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

#import "ViewController.h"
#import "PhotoScanner.h"
#import <Photos/Photos.h>
#import "PhotoAssessmentHelper.h"
#import "TZImagePickerController/TZImagePickerController.h"

@interface ViewController ()

@property (nonatomic, strong) PhotoAssessmentHelper *helper;

@property (weak, nonatomic) IBOutlet UIButton *button;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
//    self.helper = [PhotoAssessmentHelper new];
//
//    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
//        NSDate *start = [NSDate date];
//        NSArray<PHAsset *> *assets = [PhotoScanner scanPhotosWithLimit:500];
//        dispatch_group_t group = dispatch_group_create();
//        dispatch_queue_t queue = dispatch_queue_create("com.photoassessment.demo", NULL);
//        NSMutableArray<PhotoAssessmentResult *> *results = [NSMutableArray array];
//        PHImageRequestOptions *options = [PHImageRequestOptions new];
//        options.resizeMode  = PHImageRequestOptionsResizeModeFast;
//        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
//        options.networkAccessAllowed = NO;
//        for (PHAsset *asset in assets) {
//            dispatch_group_enter(group);
//            // targetSize 的调整会影响计算总耗时，但并不是 targetSize 越小耗时越小，好神奇。大概试了下，500最合适
//            [[PHImageManager defaultManager] requestImageForAsset:asset
//                                                       targetSize:CGSizeMake(240, 240)
//                                                      contentMode:PHImageContentModeAspectFit
//                                                          options:options
//                                                    resultHandler:^(UIImage *image, NSDictionary *info) {
//                                                        if (image.CGImage) {
//                                                            [self.helper requestMPSAssessmentScoreFor:image.CGImage completionHandler:^(PhotoAssessmentResult * _Nonnull result) {
//                                                                dispatch_async(queue, ^{
//                                                                    [results addObject:result];
//                                                                    dispatch_group_leave(group);
//                                                                    NSLog(@"%@", result);
//                                                                });
//                                                            }];
//                                                        }
//                                                        else {
//                                                            dispatch_group_leave(group);
//                                                        }
//                                                    }];
//        }
//        dispatch_group_notify(group, queue, ^{
//            NSTimeInterval duration = -[start timeIntervalSinceNow];
//            NSLog(@"total complete %f", duration);
//            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Finished" message:[NSString stringWithFormat:@"Duration:%f", duration] preferredStyle:UIAlertControllerStyleAlert];
//            [self presentViewController:alert animated:YES completion:nil];
//        });
//    });
}

- (IBAction)clickButton:(id)sender {
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] init];
    imagePickerVc.allowPickingVideo = NO;
    imagePickerVc.allowPickingGif = NO;
    [self presentViewController:imagePickerVc animated:YES completion:nil];
}

@end
