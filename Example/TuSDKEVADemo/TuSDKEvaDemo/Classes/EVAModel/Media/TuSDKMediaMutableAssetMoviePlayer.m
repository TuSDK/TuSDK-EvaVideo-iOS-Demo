//
//  TuSDKMediaCompositionMoviePlayer.m
//  TuSDKVideo
//
//  Created by sprint on 11/09/2018.
//  Copyright © 2018 TuSDK. All rights reserved.
//

#import "TuSDKMediaMutableAssetMoviePlayer.h"
#import "TuSDKMediaTimelineAssetMoviePlayer.h"
#import "TuSDKMediaAssetComposition.h"
#import "TuSDKMediaFormatAssistant.h"

#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wprotocol"
@interface TuSDKMediaMutableAssetMoviePlayer()
{
    //
    AVMutableComposition *_composition;
    AVMutableCompositionTrack *_compositionVideoTrack;
    AVMutableCompositionTrack *_compositionAudioTrack;
    
    NSMutableArray<TuSDKMediaAsset *> *_inputMediaAssets;

}
@end

@implementation TuSDKMediaMutableAssetMoviePlayer

/**
 构建一个视频播放器
 
 @param preview 预览视图
 @return TuSDKMediaMutableAssetMoviePlayer
 @since      v3.0.1
 */
- (instancetype _Nullable)initWithPreview:(UIView *_Nonnull)preview;
{
    if (self = [self initWithMediaAssets:@[] preview:preview]) {
        
    }
    return self;
}

/**
 构建一个视频播放器
 
 @param asset 资产信息
 @param preview 预览视图
 @return TuSDKMediaAssetMoviePlayer
 @since      v3.0
 */
- (instancetype)initWithAsset:(AVAsset *)asset preview:(UIView *)preview;
{
    NSParameterAssert(asset);

    if (self = [self initWithMediaAssets:@[[[TuSDKMediaAsset alloc] initWithAsset:asset timeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)]] preview:preview]) {
        
    }
    return self;
}

/**
 构建一个视频播放器
 
 @param inputMediaAssets 输入的资产列表
 @param preview 预览视图
 @return TuSDKMediaAssetMoviePlayer
 @since      v3.0.1
 */
- (instancetype _Nullable)initWithMediaAssets:(NSArray<TuSDKMediaAsset *> *_Nonnull)inputMediaAssets preview:(UIView *_Nonnull)preview;
{
    if (self = [super initWithAsset:[self asset] preview:preview]) {
        _inputMediaAssets = [NSMutableArray array];
        
        if (inputMediaAssets.count > 0)
            [self addInputMediaAssets:inputMediaAssets];
        
    }
    return self;
}

/**
 获取支持的最大数量
 
 @return NSUInteger
 @since  v3.0.1
 */
- (NSUInteger)maxInputSize;
{
    return 9;
}

@end


#pragma mark - 资产文件管理

/**
 动态设置 AVAsset
 
 @since v3.0.1
 */
@implementation TuSDKMediaMutableAssetMoviePlayer (MutableAsset)

/**
 将 inputAssets 组装好的的 AVMutableComposition
 
 @return AVMutableComposition
 @since      v3.0.1
 */
- (AVMutableComposition *)composition;
{
    if (_composition) return _composition;
    _composition = [AVMutableComposition composition];
    return _composition;
}

/**
 输入播放的Asset
 
 @return AVAsset
 */
- (AVAsset *)asset;
{
    return [self composition];
}

/**
 添加 TuSDKMediaAsset
 
 @param mediaAssets NSArray<TuSDKMediaAsset *> *
 @return 是否添加成功
 @since v3.0.1
 */
- (BOOL)addInputMediaAssets:(NSArray<TuSDKMediaAsset *> *_Nonnull)mediaAssets;
{

    if (self.status == TuSDKMediaPlayerStatusPlaying || !mediaAssets.count) return NO;
    
    NSMutableArray<TuSDKMediaAsset *> *filterMediaAssets = [NSMutableArray arrayWithCapacity:mediaAssets.count];
    [mediaAssets enumerateObjectsUsingBlock:^(TuSDKMediaAsset * _Nonnull inputMediaAsset, NSUInteger idx, BOOL * _Nonnull stop) {
        if (inputMediaAsset.inputAsset) {
            [filterMediaAssets addObject:inputMediaAsset];
        }
    }];
    
    if (filterMediaAssets.count == 0) {
        lsqLError(@"Please add a valid asset file");
        return NO;
    }
    
    NSUInteger remainingCount = self.maxInputSize - filterMediaAssets.count;

    if (remainingCount < 0) {
        lsqLError(@"The minimum number of video supported is 1.");
        return NO;
    }
    
    if (mediaAssets.count > self.maxInputSize) {
        lsqLError(@"The maximum number of video supported is %d subRange:(0,%d)",self.maxInputSize,MIN(remainingCount, mediaAssets.count));
    }
    
    if (remainingCount >= 0)
        [_inputMediaAssets addObjectsFromArray:filterMediaAssets];
    else
        [_inputMediaAssets addObjectsFromArray:[filterMediaAssets subarrayWithRange:NSMakeRange(0, self.maxInputSize - 1)]];
    
    [self buildComposition];
    
    return YES;
}

/**
 移除 TuSDKMediaAsset
 
 @param mediaAssets NSArray<TuSDKMediaAsset *> *
 @return 是否添加成功
 @since v3.0.1
 */
- (BOOL)removeInputMediaAssets:(NSArray<TuSDKMediaAsset *> *_Nonnull)mediaAssets;
{
   if (self.status == TuSDKMediaPlayerStatusPlaying) return NO;

    [_inputMediaAssets removeObjectsInArray:mediaAssets];
    
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self buildComposition];
    });
   
    return YES;
}

/**
 移除所有输入的资产文件
 
 @return 是否移除成功
 @since v3.0.1
 */
- (BOOL)removeAllInputMediaAssets;
{
    [self stop];
    
    if (_inputMediaAssets.count == 0) return NO;
    
    [_inputMediaAssets removeAllObjects];
    
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self buildComposition];
    });
    
    return YES;
}

/**
 首选输出尺寸
 
 @since v3.0.1
 */
- (CGSize)preferredOutputSize;
{
    if (_inputMediaAssets.count == 0) return CGSizeZero;
    
    // 获取最大视频分辨率
    __block CGSize outputSize = CGSizeZero;
    __block CGFloat scale = 0;
    [_inputMediaAssets enumerateObjectsUsingBlock:^(TuSDKMediaAsset * _Nonnull inputMediaAsset, NSUInteger idx, BOOL * _Nonnull stop) {

        if (inputMediaAsset.inputAssetInfo.videoInfo.videoTrackInfoArray.count == 0) return;

        CGSize presentSize = inputMediaAsset.inputAssetInfo.videoInfo.videoTrackInfoArray.firstObject.presentSize;

        CGFloat maxSide = MAX(presentSize.width,presentSize.height);
        if (maxSide > MAX(outputSize.width , outputSize.height))
            outputSize = presentSize;
        
        CGFloat maxScale = presentSize.height/presentSize.width;
        if (scale < maxScale) {
            scale = maxScale;
        }
    }];
    
    // 再将最大的分辨率适应最大比例
    if (outputSize.height/outputSize.width < scale) { // 过滤掉自己的比例，
        outputSize = CGSizeMake(outputSize.width, outputSize.width*scale);
    }
//    if (outputSize.width > outputSize.height) {
//        outputSize = CGSizeMake(outputSize.width, outputSize.width * scale);
//    } else {
//        outputSize = CGSizeMake(outputSize.height * scale, outputSize.height * scale);
//    }
//    outputSize = ((TuSDKMediaAsset *)_inputMediaAssets.firstObject).inputAssetInfo.videoInfo.videoTrackInfoArray.firstObject.presentSize;
//    return [TuSDKMediaFormatAssistant preferredVideoSize:outputSize];
    // 直接先输出原始最大尺寸
    return outputSize;
}


/**
 原视频尺寸对其最大视频尺寸

 @param originSize 原视频尺寸
 @return 对其后的视频尺寸
 @since v3.4.2
 */
- (CGSize)safeSize:(CGSize)originSize {
    
    // 最大视频尺寸
    CGSize outputSize = [self preferredOutputSize];
    // 宽对其，高自适应
    return CGSizeMake(outputSize.width, outputSize.width/originSize.width*originSize.height);
    
}

/**
 用于对原视频进行裁剪，可选择裁剪区域（居中，左上角...）
 
 @return CGAffineTransform
 @since v3.4.2
 */
- (CGAffineTransform)outputCropTransform:(CGSize)outputSize pageSize:(CGSize)pageSize;
{
    
    CGFloat sx = (pageSize.width - outputSize.width) * 0.5f;
    CGFloat sy = (pageSize.height - outputSize.height) * 0.5f;
    
    return CGAffineTransformMakeTranslation(sx,sy);
}




/**
 构建 AVMutableComposition
 
 @since v3.0.1
 */
- (void)buildComposition;
{
    if (_inputMediaAssets.count == 0) {
        lsqLError(@"Please input a valid asset file.");
        return;
    }
    
    [_composition removeTrack:_compositionVideoTrack];
    [_composition removeTrack:_compositionAudioTrack];
    
    _compositionVideoTrack = [_composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    _compositionAudioTrack = [_composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    
    __block CMTime outputTime = kCMTimeZero;
    __block CMTime outputAudioTime = kCMTimeZero;
    [_inputMediaAssets enumerateObjectsUsingBlock:^(TuSDKMediaAsset * _Nonnull inputMediaAsset, NSUInteger idx, BOOL * _Nonnull stop) {

        TuSDKMediaAssetComposition *assetComposition = [[TuSDKMediaAssetComposition alloc] initWithMediaAsset:inputMediaAsset];
        assetComposition.outputSize = [self safeSize:inputMediaAsset.inputAssetInfo.videoInfo.videoTrackInfoArray.firstObject.presentSize];
        
        AVAsset *outputAsset = assetComposition.outputAsset;
        
        AVAssetTrack *videoTrack = [outputAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        
        // 视频轨道
        [_compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoTrack.timeRange.duration) ofTrack:videoTrack atTime:outputTime error:NULL];
        outputTime = CMTimeAdd(outputTime, videoTrack.timeRange.duration);
        
        // 音频轨道
        /** 音频轨道务必使用 videoTrack 时间，防止某个视频是静音数据，导致音视频无法同步，使用 videoTrack.timeRange 可以生成静音数据。  **/
        AVAssetTrack *audioTrack = [outputAsset tracksWithMediaType:AVMediaTypeAudio].firstObject;
        [_compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoTrack.timeRange.duration) ofTrack:audioTrack atTime:outputAudioTime error:NULL];
        outputAudioTime = CMTimeAdd(outputAudioTime, videoTrack.timeRange.duration);
    
    }];
    
    self.videoComposition = [self buildVideoComposition];
}

/**
 构建 AVMutableVideoComposition 用以纠正视频方向及分辨率

 @return AVMutableVideoComposition
 @since v3.0.1
 */
- (AVMutableVideoComposition *)buildVideoComposition;
{
    if (self.inputMediaAssets.count == 0) return nil;
    
   
    // 用以视频 旋转,裁剪
    NSMutableArray<AVMutableVideoCompositionInstruction *> *instructions = [NSMutableArray array];
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = [self preferredOutputSize];

   __block TuSDKMediaTimeSliceEntity *sliceEntity = [self findSliceEntityWithSlice:self.orginSlices.firstObject];

    
    if (!sliceEntity)
        sliceEntity = [[TuSDKMediaTimeSliceEntity alloc] initWithSlice:[[TuSDKMediaTimelineSlice alloc] initWithStart:kCMTimeZero end:[self timelineOutputDuraiton]]];


    __block CMTime inputTime = kCMTimeZero;
    __block CMTime outputTime = kCMTimeZero;
    __block CMTime frameDuration = CMTimeMake(1, 60);
    
    
    [_inputMediaAssets enumerateObjectsUsingBlock:^(TuSDKMediaAsset * _Nonnull inputMediaAsset, NSUInteger idx, BOOL * _Nonnull stop) {
        
        TuSDKMediaAssetComposition *assetComposition = [[TuSDKMediaAssetComposition alloc] initWithMediaAsset:inputMediaAsset];
        
        CGSize outputSize = [self safeSize:inputMediaAsset.inputAssetInfo.videoInfo.videoTrackInfoArray.firstObject.presentSize];
        assetComposition.outputSize = outputSize;
        
        AVAsset *outputAsset = assetComposition.outputAsset;
        
        AVAssetTrack *videoTrack = [outputAsset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        
        if (CMTIME_COMPARE_INLINE(videoTrack.minFrameDuration, <, frameDuration) && CMTIME_COMPARE_INLINE(videoTrack.minFrameDuration, >, kCMTimeZero))
            frameDuration = videoTrack.minFrameDuration;
        
        CMTime defaultKeepEndTime = CMTimeAdd(inputTime,videoTrack.timeRange.duration);
        if (CMTIME_COMPARE_INLINE(CMTimeAdd(sliceEntity.timeRange.start , frameDuration), >=, defaultKeepEndTime)) {
            inputTime = CMTimeAdd(inputTime, videoTrack.timeRange.duration);
            return;
        }
        
        // 轨道保留的持续时
        CMTime trackDurationTime =  kCMTimeZero;
        
        if (idx == 0)
           trackDurationTime = CMTimeSubtract(videoTrack.timeRange.duration, sliceEntity.timeRange.start);
        else if(CMTIME_COMPARE_INLINE(kCMTimeZero, ==, outputTime))
            trackDurationTime = CMTimeSubtract(defaultKeepEndTime, sliceEntity.timeRange.start);
        else
           trackDurationTime =  CMTimeSubtract(defaultKeepEndTime, inputTime);
        
        /** 最终轨道保留的时间区间 */
        CMTimeRange inputTimeRange = CMTimeRangeMake(inputTime,trackDurationTime);
        /** 最终轨道应用变速后，输出的时间区间 */
        CMTimeRange outputTimeRange = CMTimeRangeMake(outputTime,CMTimeMultiplyByFloat64(trackDurationTime, 1 /sliceEntity.speedRate));

        /** 裁剪区域是否到达末尾 */
        if (CMTIME_COMPARE_INLINE(sliceEntity.timeRange.end , < ,CMTimeRangeGetEnd(inputTimeRange))) {
//            outputTimeRange = CMTimeRangeMake(outputTime,CMTimeMultiplyByFloat64(CMTimeSubtract(sliceEntity.timeRange.end, inputTimeRange.start), 1 /sliceEntity.speedRate));
            outputTimeRange = CMTimeRangeMake(outputTime, kCMTimeIndefinite);
            *stop = YES;

        }

        AVMutableVideoCompositionLayerInstruction * layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        // 让小视频居中在画布上
        CGAffineTransform outputTransform = CGAffineTransformConcat(assetComposition.outputTransform, [self outputCropTransform:outputSize pageSize:[self preferredOutputSize]]);
//        NSLog(@"outputTransform: %@", NSStringFromCGAffineTransform(assetComposition.outputTransform));
        [layerInstruction setTransform:outputTransform atTime:outputTime];

        
        // 创建最终输出使用的 VideoComposition
        AVMutableVideoCompositionInstruction *videoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        videoCompositionInstruction.timeRange = outputTimeRange;
        videoCompositionInstruction.layerInstructions = [NSArray arrayWithObject:layerInstruction];
        
        [instructions addObject:videoCompositionInstruction];
        
        inputTime =  CMTimeAdd(videoTrack.timeRange.duration, inputTime);
        outputTime = CMTimeAdd(outputTime, outputTimeRange.duration);
        
    }];
    
    // 设置颜色空间 解决了单色变浅的问题，但是多次会有环境色差
    AVAssetTrack *videoTrack = [[_inputMediaAssets.firstObject.inputAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    if (videoTrack) {
        CMFormatDescriptionRef description = (__bridge CMFormatDescriptionRef)([videoTrack formatDescriptions].firstObject);
        if (description) {
//            lsqLInfo(@"%@", description);
            if (@available(iOS 10.0, *)) {
                CFTypeRef colorAttachments = CMFormatDescriptionGetExtension(description, kCVImageBufferYCbCrMatrixKey);
                if (colorAttachments != NULL) {
                    if(CFStringCompare(colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_601_4, 0) == kCFCompareEqualTo) {
                        videoComposition.colorPrimaries = (__bridge NSString * _Nullable)(kCVImageBufferColorPrimaries_ITU_R_709_2);
                        videoComposition.colorYCbCrMatrix = (__bridge NSString * _Nullable)(kCVImageBufferYCbCrMatrix_ITU_R_601_4);
                        videoComposition.colorTransferFunction = (__bridge NSString * _Nullable)(kCVImageBufferTransferFunction_ITU_R_709_2);
                    } else if (CFStringCompare(colorAttachments, kCVImageBufferYCbCrMatrix_ITU_R_709_2, 0) == kCFCompareEqualTo) {
                        videoComposition.colorPrimaries = (__bridge NSString * _Nullable)(kCVImageBufferColorPrimaries_ITU_R_709_2);
                        videoComposition.colorYCbCrMatrix = (__bridge NSString * _Nullable)(kCVImageBufferYCbCrMatrix_ITU_R_709_2);
                        videoComposition.colorTransferFunction = (__bridge NSString * _Nullable)(kCVImageBufferTransferFunction_ITU_R_709_2);
                    }
                }
            }
        }
    }

    videoComposition.frameDuration = frameDuration;
    videoComposition.instructions = instructions;

    
    return videoComposition;
}

@end




#pragma mark - 时间切片

/**
 动态设置 AVAsset
 
 @since v3.0.1
 */
@implementation TuSDKMediaMutableAssetMoviePlayer (TimelineSlice)

/**
 在原有特效后追加新的特效. 
 
 @param timelineSlice 特效片段
 @since      v3.0.1
 */
- (BOOL)appendMediaTimeSlice:(TuSDKMediaTimelineSlice *)timelineSlice;
{
    if (self.orginSlices.count > 0) {
        lsqLError(@"Sorry, multi-file player only supports setting up one slice at most.");
        return NO;
    }
    
    BOOL result = [super appendMediaTimeSlice:timelineSlice];
    self.videoComposition = [self buildVideoComposition];
    return result;
}

/**
 移除特效片段
 
 @param timelineSlice TuSDKMediaTimelineSlice
 @since      v3.0
 */
- (BOOL)removeMediaTimeSlice:(TuSDKMediaTimelineSlice *)timelineSlice;
{
    BOOL result = [super removeMediaTimeSlice:timelineSlice];
    
    self.videoComposition = [self buildVideoComposition];
    
    return result;
}

/**
 移除所有特效片段
 
 @since v3.0.1
 */
- (void)removeAllMediaTimeSlices;
{
    [super removeAllMediaTimeSlices];
    self.videoComposition = [self buildVideoComposition];
}


@end

