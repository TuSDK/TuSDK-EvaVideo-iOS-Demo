//
//  TuSDKVideoImageExtractor.m
//  TuSDKVideo
//
//  Created by gh.li on 17/3/13.
//  Copyright © 2017年 TuSDK. All rights reserved.
//

#import "TuSDKVideoImageExtractor.h"
#import "TuSDKFramework.h"


typedef NS_ENUM(NSInteger, TuSDKVideoComponentType) {
    /**
     * 提取视频缩略图
     */
   tkc_video_api_extractot_video_images = 0x903005,
};

/// 默认最大图像输出尺寸
static const CGSize kDefaultMaxImageOutputSize = {80.0, 80.0};

@interface TuSDKVideoImageExtractor()

/// 所有视频的时长，调用 `-setupFrameCount` 方法时已经赋值
@property (nonatomic, assign) NSTimeInterval allVideosDuration;

@end

@implementation TuSDKVideoImageExtractor

+ (TuSDKVideoImageExtractor *)createExtractor {
    TuSDKVideoImageExtractor * extractor = [[TuSDKVideoImageExtractor alloc] init];
    return extractor;
}

#pragma mark - private

/// 获取所有视频
- (NSArray *)allVideoAssets {
    NSArray *allVideoAssets = nil;
    if (!_videoAssets.count) {
        if (_videoAsset) {
            allVideoAssets = @[_videoAsset];
        } else if (_videoPath) {
            allVideoAssets = @[[AVURLAsset URLAssetWithURL:_videoPath options:nil]];
        }
    } else {
        allVideoAssets = _videoAssets;
    }
    if (!allVideoAssets.count) {
        
        lsqLError(@"Please set videoAsset, videoPath or videoAssets");
    }
    return allVideoAssets;
}

/// 配置提取的帧数量与帧间隔时间
- (BOOL)setupFrameCount {
    // 获取所有视频，若数量为 0，则返回 NO
    NSArray *allVideoAssets = [self allVideoAssets];
    if (!allVideoAssets.count) {
        return NO;
    }
    
    // 获取视频时长
    NSTimeInterval allVideosDuration = .0;
    for (int i = 0; i < allVideoAssets.count; i++) {
        AVAsset *asset = allVideoAssets[i];
        CMTime duration = asset.duration;
        allVideosDuration += CMTimeGetSeconds(duration);
    }
    _allVideosDuration = allVideosDuration;
    
    // 处理帧间隔、帧数量
    if (_extractFrameTimeInterval <= 0 && _extractFrameCount <= 0) {
        lsqLError(@"extractFrameTimeInterval or extractFrameCount is invalid");
    }
    if (_extractFrameCount > 0) {
        _extractFrameTimeInterval = allVideosDuration / _extractFrameCount * 1.0;
    } else {
        _extractFrameCount = allVideosDuration / _extractFrameTimeInterval * 1.0;
    }
    
    return YES;
}

/// 生成 AVAssetImageGenerator 对象
- (AVAssetImageGenerator *)imageGeneratorWithAsset:(AVAsset *)asset {
    // 若给定的 asset 为空则返回 nil
    if (!asset) return nil;
    
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    // 帧率过低，需要精确获取时间
    if (!_isAccurate) {
        AVAssetTrack *asstTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        if (asstTrack.nominalFrameRate < 10) {
            _isAccurate = YES;
        }
    }
    [self setupImageGenerator:imageGenerator];
    return imageGenerator;
}

/// 配置图片提取器
- (void)setupImageGenerator:(AVAssetImageGenerator *)imageGenerator {
    NSArray *allVideoAssets = [self allVideoAssets];
    
    // 仅为单个视频时，配置 videoComposition
    if (allVideoAssets.count == 1) imageGenerator.videoComposition = self.videoComposition;
    
    // 配置轨道画面变换
    imageGenerator.appliesPreferredTrackTransform = YES;
    
    // 配置精确时间获取图片
    imageGenerator.requestedTimeToleranceAfter = imageGenerator.requestedTimeToleranceBefore
    = _isAccurate ? kCMTimeZero : kCMTimePositiveInfinity;
    
    // 配置输出的最大尺寸
    if (CGSizeEqualToSize(_outputMaxImageSize, CGSizeZero)) {
        // 计算视频数组中最小的尺寸
        CGSize minNaturalSize = CGSizeZero;
        CGFloat scale = [UIScreen mainScreen].scale;
        CGSize defaultSize = CGSizeMake(kDefaultMaxImageOutputSize.width * scale, kDefaultMaxImageOutputSize.height * scale);
        for (int i = 0; i < allVideoAssets.count; i++) {
            AVAsset *asset = allVideoAssets[i];
            CGSize naturalSize = [asset tracksWithMediaType:AVMediaTypeVideo].lastObject.naturalSize;
            if (naturalSize.width * naturalSize.height < minNaturalSize.width * minNaturalSize.height) {
                minNaturalSize = naturalSize;
            }
        }
        // 与默认尺寸比较得出适合的尺寸
        if (minNaturalSize.width > defaultSize.width || minNaturalSize.height > defaultSize.height) {
            CGSize matchSize = AVMakeRectWithAspectRatioInsideRect(minNaturalSize, (CGRect){CGPointZero, kDefaultMaxImageOutputSize}).size;
            _outputMaxImageSize = CGSizeMake(matchSize.width * scale, matchSize.height * scale);
        } else {
            _outputMaxImageSize = defaultSize;
        }
    }
    imageGenerator.maximumSize = _outputMaxImageSize;
}

/// 同步截帧
- (UIImage *)frameImageAtTime:(CMTime)time asset:(AVAsset *)asset {
    AVAssetImageGenerator *imageGenerator = [self imageGeneratorWithAsset:asset];
    NSError *error = nil;
    CMTime actualTime = kCMTimeZero;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:&actualTime error:&error];
    if (error || !imageRef) {
        lsqLError(@"image generate error: %@", error);
        return nil;
    }
    UIImage *frameImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    //NSLog(@"frameImage: %@, time: %f", frameImage, CMTimeGetSeconds(actualTime));
    return frameImage;
}

/// 计算要截取的时间
- (NSArray<NSArray<NSValue *> *> *)allCaptureTimesWithAssets:(NSArray<AVAsset *> *)assets {
    // 经过的视频时长，一个视频算完截取时间则增加该视频的时长
    NSTimeInterval passVideoDuration = 0;
    // 累计截取时间
    NSTimeInterval captureTime = 0;
    // 当前计算截取时间的视频索引
    NSUInteger currentVideoIndex = 0;
    // 当前视频截取的时间
    NSMutableArray<NSValue *> *currentVideoCaptureTimes = [NSMutableArray array];
    // 所有视频的截取时间，每个视频对应一个数组
    NSMutableArray<NSArray *> *allCaptureTimes = [NSMutableArray arrayWithObject:currentVideoCaptureTimes];
    // 依次遍历所有视频
    for (int i = 0; i < _extractFrameCount; i++) {
        AVAsset *currentVideo = assets[currentVideoIndex];
        NSTimeInterval previousVideoDuration = CMTimeGetSeconds(currentVideo.duration);
        if (captureTime > passVideoDuration + previousVideoDuration) { // 获取完一个视频的时间
            currentVideoIndex += 1;
            if (currentVideoIndex >= assets.count) break;
            passVideoDuration += previousVideoDuration;
            currentVideoCaptureTimes = [NSMutableArray array];
            [allCaptureTimes addObject:currentVideoCaptureTimes];
        }
        NSTimeInterval currentVideoCaptureTime = captureTime - passVideoDuration;
        [currentVideoCaptureTimes addObject:[NSValue valueWithCMTime:CMTimeMakeWithSeconds(currentVideoCaptureTime, currentVideo.duration.timescale)]];
        
        captureTime += _extractFrameTimeInterval;
    }
    return allCaptureTimes.copy;
}

#pragma mark - public

#pragma mark 同步截帧

- (UIImage *)frameImageAtTime:(CMTime)time {
    // 若帧数量配置失败则返回 nil
    if (![self setupFrameCount]) return nil;
    NSArray *allVideoAssets = [self allVideoAssets];
    
    // 获取需要操作的视频以及对应的截取的时间，若给定时长大于所有视频时长则完成遍历后返回 nil
    NSTimeInterval captureTime = CMTimeGetSeconds(time);
    NSInteger videoIndex = -1;
    for (int i = 0; i < allVideoAssets.count; i++) {
        AVAsset *asset = allVideoAssets[i];
        NSTimeInterval duration = CMTimeGetSeconds(asset.duration);
        if (captureTime > duration) {
            captureTime -= duration;
        } else {
            videoIndex = i;
            break;
        }
    }
    if (videoIndex < 0) return nil;

    // sdk统计信息
    
    [TuStatistics appendWithComponentIdt:tkc_video_api_extractot_video_images];

    // 同步截取对应视频的对应时间的图片
    AVAsset *asset = allVideoAssets[videoIndex];
    time = CMTimeMakeWithSeconds(captureTime, time.timescale);
    return [self frameImageAtTime:time asset:asset];
}

- (NSArray<UIImage *> *)extractImageList {
    // 若帧数量配置失败则返回 nil
    if (![self setupFrameCount]) return nil;
    
    NSArray *allVideoAssets = [self allVideoAssets];
    NSArray *allCaptureTimes = [self allCaptureTimesWithAssets:allVideoAssets];
    NSMutableArray *frameImages = [NSMutableArray array];
    // 依次同步获取每个视频对应截取时间的图片
    for (int i = 0; i < allCaptureTimes.count; i++) {
        NSArray<NSValue *> *times = allCaptureTimes[i];
        //NSLog(@"asset: %@", allVideoAssets[i]);
        for (int j = 0; j < times.count; j++) {
            @autoreleasepool {
                CMTime time = [times[j] CMTimeValue];
                UIImage *frameImage = [self frameImageAtTime:time asset:allVideoAssets[i]];
                if (frameImage) [frameImages addObject:frameImage];
            }
        }
    }

    // sdk统计信息
    [TuStatistics appendWithComponentIdt:tkc_video_api_extractot_video_images];

    return frameImages;
}

#pragma mark 异步截帧

- (void)asyncExtractImageList:(TuSDKVideoImageExtractorBlock)handler {
    // 保存所有截取帧图片的数组，插入足够数量的对象
    __block NSMutableArray *frameImages = [NSMutableArray array];
    for (NSInteger i = 0; i < _extractFrameCount; i++) {
        [frameImages addObject:@(i)];
    }
    
    // 异步截取帧图片，并替换 frameImages 对应索引的对象，直到截取的数量足够
    __block NSInteger imageCount = 0;
    NSInteger extractFrameCount = self.extractFrameCount;
    [self asyncExtractImageWithHandler:^(UIImage *image, NSUInteger index) {
        imageCount += 1;
        [frameImages replaceObjectAtIndex:index withObject:image];
        if (imageCount == extractFrameCount) { // 截取图片足够则回调
            if (handler) handler(frameImages.copy);
        }
    }];
}

- (void)asyncExtractImageWithHandler:(TuSDKVideoImageExtractorStepImageBlock)handler {
    // 若帧数量配置失败则返回
    if (![self setupFrameCount]) return;
    
    NSArray *allVideoAssets = [self allVideoAssets];
    NSArray<NSArray *> *allCaptureTimes = [self allCaptureTimesWithAssets:allVideoAssets];
    
    // 依次截取图片
    for (int i = 0; i < allCaptureTimes.count; i++) {
        NSArray *currentVideoCaptureTimes = allCaptureTimes[i];
        AVAsset *currentVideo = allVideoAssets[i];
        AVAssetImageGenerator *imageGenerator = [self imageGeneratorWithAsset:currentVideo];
        [imageGenerator generateCGImagesAsynchronouslyForTimes:currentVideoCaptureTimes completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
            // 计算图片最终所在的索引
            NSUInteger finalIndex = [currentVideoCaptureTimes indexOfObject:[NSValue valueWithCMTime:requestedTime]];
            if (i > 0) {
                for (int j = 0; j < i; j ++) {
                    finalIndex += allCaptureTimes[j].count;
                }
            }
            
            if (error) { // 遇错则返回
                lsqLError(@"generate image error: %@", error);
                return;
            }
            
            UIImage *frameImage = [UIImage imageWithCGImage:image];
            dispatch_async(dispatch_get_main_queue(), ^{
                //NSLog(@"image-%zd: %@", finalIndex, frameImage);
                if (handler) handler(frameImage, finalIndex);
            });
        }];
    }

    // sdk统计信息
    [TuStatistics appendWithComponentIdt: tkc_video_api_extractot_video_images];
}

@end
