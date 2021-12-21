//
//  TuSDKVideoInfo.m
//  TuSDKVideo
//
//  Created by sprint on 02/07/2018.
//  Copyright © 2018 TuSDK. All rights reserved.
//

#import "TuSDKVideoInfo.h"

@implementation TuSDKVideoInfo

/**
 是否为4k视频
 
 @since v3.0
 */
- (BOOL)is4K;
{
    CGSize naturalSize = self.videoTrackInfoArray.firstObject.naturalSize;
    CGFloat maxSide = MAX(naturalSize.width, naturalSize.height);
    return maxSide >= 3840;
}

- (void)loadSynchronouslyForAssetInfo:(AVAsset *)asset
{
    __block BOOL isLoad = NO;
    [self loadAsynchronouslyForAssetInfo:asset completionHandler:^{
        isLoad = YES;
    }];
    
    // 等待加载完成再出去
    while (!isLoad) {
        [NSThread sleepForTimeInterval:0.01];
    }
}

/**
 *  从NSURL加载AVURLAsset
 *
 *  @param URL     URL
 *  @param handler 加载完成后处理回调
 */
- (void)loadAsynchronouslyForAssetInfo:(AVAsset *)asset completionHandler:(void (^)(void))handler;
{
    if (asset == nil) return;
    
    _videoTrackInfoArray = [NSMutableArray arrayWithCapacity:1];
    
    _duration = asset.duration;
    
    [asset loadValuesAsynchronouslyForKeys:@[@"tracks",@"duration"] completionHandler: ^{
        
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSError *error;
            AVKeyValueStatus tracksStatus = [asset statusOfValueForKey:@"tracks" error:&error];
            if ((tracksStatus != AVKeyValueStatusLoaded || error))
            {
                if(handler) handler();
                
                return;
            }
            
            _duration = asset.duration;
            
            // 获取所有视频轨道信息
            NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
            NSMutableArray<TuSDKVideoTrackInfo *> *videoTrackInfoArray = [NSMutableArray arrayWithCapacity:1];
            
            [videoTracks enumerateObjectsUsingBlock:^(AVAssetTrack *videoTrack, NSUInteger idx, BOOL * _Nonnull stop) {
                
                TuSDKVideoTrackInfo *videoTrackInfo = [[TuSDKVideoTrackInfo alloc] initWithVideoAssetTrack:videoTrack];
                [videoTrackInfoArray addObject:videoTrackInfo];
                
            }];
            
            _videoTrackInfoArray = videoTrackInfoArray;
          
            
            if(handler)
                handler();
            
        });
    }];
    
}

/**
 描述信息
 
 @return NSString
 @since v3.0
 */
- (NSString *)description;
{
     NSMutableString *description = [NSMutableString new];
    [_videoTrackInfoArray enumerateObjectsUsingBlock:^(TuSDKVideoTrackInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [description appendFormat:@"\n [ \n trackIndex : %ld \n  %@ \n ]\n",idx,obj];
    }];

    return description;
}

@end


#pragma mark - TuSDKVideTrackInfo

@implementation TuSDKVideoTrackInfo

/**
 trackInfoWithVideoAssetTrack
 
 @param videoTrack AVAssetTrack
 @return TuSDKVideoTrackInfo
 */
+ (instancetype)trackInfoWithVideoAssetTrack:(AVAssetTrack *)videoTrack
{
    TuSDKVideoTrackInfo *trackInfo = [[TuSDKVideoTrackInfo alloc] initWithVideoAssetTrack:videoTrack];
    return trackInfo;
}

- (instancetype)initWithVideoAssetTrack:(AVAssetTrack *)videoTrack
{
    if (self = [super init])
    {
        
        _naturalSize = videoTrack.naturalSize;
        _presentSize = CGSizeMake(_naturalSize.width, _naturalSize.height);
        _preferredTransform = videoTrack.preferredTransform;
        _orientation = [self preferredTransformToRotation:_preferredTransform];
        _estimatedDataRate = videoTrack.estimatedDataRate;
        _nominalFrameRate = videoTrack.nominalFrameRate;
        _minFrameDuration = videoTrack.minFrameDuration;
        
        _isTransposedSize = (_orientation == LSQKGPUImageRotateRight || _orientation == LSQKGPUImageRotateLeft);
        
        if (_isTransposedSize)
            _presentSize = CGSizeMake(_naturalSize.height, _naturalSize.width);
        
    }
    
    return self;
}

- (LSQGPUImageRotationMode)preferredTransformToRotation:(CGAffineTransform)transform
{
    if (transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0)
        return LSQKGPUImageRotateRight;
    else if (transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0)
        return LSQKGPUImageRotateLeft;
    else if (transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0)
        return LSQKGPUImageNoRotation;
    else if (transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0)
        return LSQKGPUImageRotate180;
    else
        return LSQKGPUImageNoRotation;
}

/**
 描述信息
 
 @return NSString
 @since v3.0
 */
- (NSString *)description;
{
    NSMutableString *description = [NSMutableString new];
    [description appendFormat:@"  naturalSize : %@ \n ",NSStringFromCGSize(_naturalSize)];
    [description appendFormat:@"  presentSize : %@ \n ",NSStringFromCGSize(_presentSize)];
    [description appendFormat:@"  estimatedDataRate : %f \n ",_estimatedDataRate];
    [description appendFormat:@"  nominalFrameRate : %f \n ",_nominalFrameRate];
    [description appendFormat:@"  orientation : %ld \n ",_orientation];
    
    return description;
}

@end
