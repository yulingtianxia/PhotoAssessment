//
//  PickMeViewController.m
//  PhotoAssessmentUsageDemo
//
//  Created by 杨萧玉 on 2018/12/18.
//  Copyright © 2018 杨萧玉. All rights reserved.
//

#import "PickMeViewController.h"
#import "PhotoAssessmentHelper.h"
#import <Photos/Photos.h>
#import "PhotoScanner.h"
#import "PhotoAssessmentUtils.h"
#import "TZPhotoPreviewCell.h"

@interface PickPhotoResult : NSObject <NSSecureCoding>

@property (nonatomic, strong) PhotoAssessmentResult *resultA;
@property (nonatomic, strong) PhotoAssessmentResult *resultB;
@property (nonatomic, assign, getter=isPickA) BOOL pickA;

- (BOOL)pickRight;

@end

@implementation PickPhotoResult

- (BOOL)pickRight
{
    return [self.resultA betterThan:self.resultB] == self.isPickA;
}

#pragma mark - NSSecureCoding

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeObject:self.resultA forKey:@"resultA"];
    [aCoder encodeObject:self.resultB forKey:@"resultB"];
    [aCoder encodeBool:self.pickA forKey:@"pickA"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    if (self = [self init]) {
        self.resultA = [aDecoder decodeObjectForKey:@"resultA"];
        self.resultB = [aDecoder decodeObjectForKey:@"resultB"];
        self.pickA = [aDecoder decodeBoolForKey:@"pickA"];
    }
    return self;
}

@end

@interface PickMeViewController ()

@property (nonatomic, strong) PhotoAssessmentHelper *helper;
@property (nonatomic, strong) NSArray<PHAsset *> *assets;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewA;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewB;
@property (nonatomic, strong) PickPhotoResult *pickResult;
@property (nonatomic, assign) BOOL rightAnswer;
@property (nonatomic, strong) NSMutableArray<PickPhotoResult *> *allPickResults;
@property (nonatomic, strong) dispatch_queue_t queue;
@property (nonatomic, assign) NSUInteger rightCount;
@property (weak, nonatomic) IBOutlet UILabel *statisticsLabel;
@property (weak, nonatomic) IBOutlet UILabel *scoreLabel;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapGestureA;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapGestureB;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *doubleTapGestureA;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *doubleTapGestureB;
@property (strong, nonatomic) TZPhotoPreviewView *photoPreviewView;
@property (nonatomic, assign) NSUInteger assetIndexA;
@property (nonatomic, assign) NSUInteger assetIndexB;

@end

@implementation PickMeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.helper = [PhotoAssessmentHelper new];
    self.queue = dispatch_queue_create("com.photoassessment.demo", NULL);
    [self loadAllPickResults];
    NSUInteger rightCount = 0;
    for (PickPhotoResult *pickResult in self.allPickResults) {
        if ([pickResult pickRight]) {
            rightCount ++;
        }
    }
    self.rightCount = rightCount;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        self.assets = [PhotoScanner scanPhotosWithLimit:2000];
        if (self.assets.count >= 2) {
            [self pickTwoPhotos];
        }
        else {
            self.resultLabel.text = @"刚才无照片权限，重新进入页面试试";
        }
    });
    [self.tapGestureA requireGestureRecognizerToFail:self.doubleTapGestureA];
    [self.tapGestureB requireGestureRecognizerToFail:self.doubleTapGestureB];
    self.photoPreviewView = [[TZPhotoPreviewView alloc] initWithFrame:self.view.bounds];
    self.photoPreviewView.backgroundColor = [UIColor blackColor];
    __weak typeof(self) weakSelf = self;
    [self.photoPreviewView setSingleTapGestureBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.photoPreviewView removeFromSuperview];
    }];
}

- (void)pickTwoPhotos
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.resultLabel.text = @"结果";
        self.resultLabel.textColor = [UIColor blackColor];
        self.tapGestureA.enabled = YES;
        self.tapGestureB.enabled = YES;
        self.scoreLabel.text = @"Score";
        self.photoPreviewView.showScore = NO;
    });
    dispatch_async(self.queue, ^{
        NSDate *start = [NSDate date];
        dispatch_group_t group = dispatch_group_create();
        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.resizeMode  = PHImageRequestOptionsResizeModeFast;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.networkAccessAllowed = NO;
        self.assetIndexA = arc4random_uniform((uint32_t)self.assets.count);
        self.assetIndexB = arc4random_uniform((uint32_t)self.assets.count);
        self.pickResult = [PickPhotoResult new];
        
        dispatch_group_enter(group);
        // targetSize 的调整会影响计算总耗时，但并不是 targetSize 越小耗时越小，好神奇。大概试了下，500最合适
        [[PHImageManager defaultManager] requestImageForAsset:self.assets[self.assetIndexA]
                                                   targetSize:CGSizeMake(224, 224)
                                                  contentMode:PHImageContentModeAspectFit
                                                      options:options
                                                resultHandler:^(UIImage *image, NSDictionary *info) {
                                                    if (image.CGImage) {
                                                        self.imageViewA.image = image;
                                                        [self.helper requestMPSAssessmentScoreFor:image.CGImage completionHandler:^(PhotoAssessmentResult * _Nonnull result) {
                                                            dispatch_async(self.queue, ^{
                                                                self.pickResult.resultA = result;
                                                                dispatch_group_leave(group);
                                                                NSLog(@"%@", result);
                                                            });
                                                        }];
                                                    }
                                                    else {
                                                        dispatch_group_leave(group);
                                                    }
                                                }];
        dispatch_group_enter(group);
        [[PHImageManager defaultManager] requestImageForAsset:self.assets[self.assetIndexB]
                                                   targetSize:CGSizeMake(224, 224)
                                                  contentMode:PHImageContentModeAspectFit
                                                      options:options
                                                resultHandler:^(UIImage *image, NSDictionary *info) {
                                                    if (image.CGImage) {
                                                        self.imageViewB.image = image;
                                                        [self.helper requestMPSAssessmentScoreFor:image.CGImage completionHandler:^(PhotoAssessmentResult * _Nonnull result) {
                                                            dispatch_async(self.queue, ^{
                                                                self.pickResult.resultB = result;
                                                                dispatch_group_leave(group);
                                                                NSLog(@"%@", result);
                                                            });
                                                        }];
                                                    }
                                                    else {
                                                        dispatch_group_leave(group);
                                                    }
                                                }];
        dispatch_group_notify(group, self.queue, ^{
            NSTimeInterval duration = -[start timeIntervalSinceNow];
            NSLog(@"total complete %f", duration);
        });
    });
}

- (IBAction)changePhotos:(UIButton *)sender {
    if (self.assets.count >= 2) {
        [self pickTwoPhotos];
    }
}

- (IBAction)handleTapImageViewA:(UITapGestureRecognizer *)sender {
    self.pickResult.pickA = YES;
    self.rightAnswer = [self.pickResult.resultA betterThan:self.pickResult.resultB];
}

- (IBAction)handleTapImageViewB:(UITapGestureRecognizer *)sender {
    self.pickResult.pickA = NO;
    self.rightAnswer = [self.pickResult.resultB betterThan:self.pickResult.resultA];
}

- (IBAction)handleDoubleTapImageViewA:(UITapGestureRecognizer *)sender {
    [self.photoPreviewView setAsset:self.assets[self.assetIndexA]];
    [self.view addSubview:self.photoPreviewView];
}

- (IBAction)handleDoubleTapImageViewB:(UITapGestureRecognizer *)sender {
    [self.photoPreviewView setAsset:self.assets[self.assetIndexB]];
    [self.view addSubview:self.photoPreviewView];
}

- (void)setRightAnswer:(BOOL)rightAnswer
{
    _rightAnswer = rightAnswer;
    [self.allPickResults addObject:self.pickResult];
    if (rightAnswer) {
        self.resultLabel.text = @"正确";
        self.resultLabel.textColor = [UIColor greenColor];
        self.rightCount ++;
    }
    else {
        self.resultLabel.text = @"错误";
        self.resultLabel.textColor = [UIColor redColor];
        self.rightCount = self.rightCount;
    }
    [self saveAllPickResults];
    self.tapGestureA.enabled = NO;
    self.tapGestureB.enabled = NO;
    self.photoPreviewView.showScore = YES;
    self.scoreLabel.text = [NSString stringWithFormat:@"ImageA:%f\nImageB:%f", self.pickResult.resultA.totalScore, self.pickResult.resultB.totalScore];
}

- (void)setRightCount:(NSUInteger)rightCount
{
    _rightCount = rightCount;
    self.statisticsLabel.text = [NSString stringWithFormat:@"%lu/%lu", (unsigned long)self.rightCount, (unsigned long)self.allPickResults.count];
}

- (void)loadAllPickResults
{
    NSData *archivedData = [NSUserDefaults.standardUserDefaults dataForKey:@"allPickResults"];
    if (!archivedData) {
        self.allPickResults = [NSMutableArray array];
        return;
    }
    NSError *error;
    self.allPickResults = [NSKeyedUnarchiver unarchivedObjectOfClasses:[NSSet setWithArray:@[PickPhotoResult.class, PhotoAssessmentResult.class, HSBColor.class, NSMutableDictionary.class, NSMutableArray.class]] fromData:archivedData error:&error];
    if (error) {
        NSLog(@"%@", error.localizedDescription);
    }
}

- (void)saveAllPickResults
{
    NSError *error;
    NSData *archivedData = [NSKeyedArchiver archivedDataWithRootObject:self.allPickResults requiringSecureCoding:NO error:&error];
    [NSUserDefaults.standardUserDefaults setObject:archivedData forKey:@"allPickResults"];
    if (error) {
        NSLog(@"%@", error.localizedDescription);
    }
}

@end
