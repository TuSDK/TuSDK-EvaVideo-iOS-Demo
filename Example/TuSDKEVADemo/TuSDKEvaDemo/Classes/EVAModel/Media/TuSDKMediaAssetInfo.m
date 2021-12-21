//
//  TuSDKMediaAssetInfo.h
//  TuSDKVideo
//
//  Created by sprint on 04/05/2018.
//  Copyright © 2018 TuSDK. All rights reserved.
//

#import "TuSDKMediaAssetInfo.h"

/**
 * TuSDKMovieInfo
 */
@implementation TuSDKMediaAssetInfo

/**
 根据 AVAsset 初始化 TuSDKMediaAssetInfo
 
 @param asset 资产信息
 @return TuSDKMediaAssetInfo
 @since v3.0
 */
- (instancetype)initWithAsset:(AVAsset *)asset;
{
    if (self = [self init]) {
        [self loadSynchronouslyForAssetInfo:asset];
    }
    return self;
}

/**
 异步加载视频信息
 
 @param asset AVAsset
 @param handler 完成后回调
 @since v2.2.0
 */
-(void)loadSynchronouslyForAssetInfo:(AVAsset *)asset
{
    if (!asset) {
        NSLog(@"Please input a valid asset file");
        return;
    }
    
    _asset = asset;
    
    _videoInfo = [[TuSDKVideoInfo alloc] init];
    [self.videoInfo loadSynchronouslyForAssetInfo:asset];
    
    _audioInfo = [[TuSDKAudioInfo alloc] init];
    [self.audioInfo loadSynchronouslyForAssetInfo:asset];

}

/**
 描述信息

 @return NSString
 @since v3.0
 */
- (NSString *)description;
{
    NSMutableString *description = [NSMutableString new];
    [description appendFormat:@" asset : %@ \n ",_asset];
    [description appendFormat:@" videoInfo : %@ \n ",_videoInfo];
    [description appendFormat:@" audioInfo : %@ \n",_audioInfo];
    
    return description;
}

@end

