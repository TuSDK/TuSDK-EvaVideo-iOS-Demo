//
//  TuSDKMediaAsset.m
//  TuSDKVideo
//
//  Created by sprint on 11/09/2018.
//  Copyright © 2018 TuSDK. All rights reserved.
//

#import "TuSDKMediaAsset.h"

@implementation TuSDKMediaAsset
@synthesize inputAssetInfo = _inputAssetInfo;

/**
 初始化资产切片对象
 
 @param inputAsset 输入的资产信息
 @param timeRange 裁剪区间
 @return TuSDKMediaAssetSlice
 @since v3.0.1
 */
- (instancetype)initWithAsset:(AVAsset *)inputAsset timeRange:(CMTimeRange)timeRange;
{
    if (self = [super init]) {
        _inputAsset = inputAsset;
        _timeRange = timeRange;
    }
    
    return self;
}

/**
 获取视频信息
 
 @return TuSDKMediaAssetInfo
 */
- (TuSDKMediaAssetInfo *)inputAssetInfo
{
    if (_inputAssetInfo != nil) return _inputAssetInfo;
    
    _inputAssetInfo = [[TuSDKMediaAssetInfo alloc] init];
    [_inputAssetInfo loadSynchronouslyForAssetInfo:_inputAsset];
    
    return _inputAssetInfo;
}

/**
 视频裁剪区间
 
 @return CMTimeRange
 */
- (CMTimeRange)timeRange;
{
    if (CMTIMERANGE_IS_VALID(_timeRange)) return _timeRange;
    
    return CMTimeRangeMake(kCMTimeZero, self.inputAsset.duration);
}


@end
