//
//  TuSDKAudioInfo.m
//  TuSDKVideo
//
//  Created by sprint on 02/07/2018.
//  Copyright © 2018 TuSDK. All rights reserved.
//

#import "TuSDKAudioInfo.h"


@implementation TuSDKAudioInfo

/**
 同步加载音频信息
 
 @param asset AVAsset
 @since 3.0
 */
-(void)loadSynchronouslyForAssetInfo:(AVAsset *)asset
{    
    __block BOOL isLoad = NO;
    [self loadAsynchronouslyForAssetInfo:asset completionHandler:^{
        isLoad = YES;
    }];
    // 等待加载完成再出去
    while (!isLoad) {
        [NSThread sleepForTimeInterval:0.005];
    }
}

/**
 异步加载音频信息
 
 @param asset AVAsset
 @param handler 完成后回调
 @since 3.0
 */
- (void)loadAsynchronouslyForAssetInfo:(AVAsset *)asset completionHandler:(void (^)(void))handler;
{
    if (asset == nil) return;
    
   NSMutableArray<TuSDKAudioTrackInfo *> *audioTrackInfoArray = [NSMutableArray arrayWithCapacity:1];
    _audioTrackInfoArray = audioTrackInfoArray;
    
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
            
            NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
            [audioTracks enumerateObjectsUsingBlock:^(AVAssetTrack *audioTrack, NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSArray *audioFormatInfo = audioTrack.formatDescriptions;
                if ([audioFormatInfo count] > 0)
                {
                    CMAudioFormatDescriptionRef audioFormatDescriptionRef = (CMAudioFormatDescriptionRef)CFBridgingRetain([audioFormatInfo objectAtIndex:0]);
                    TuSDKAudioTrackInfo *audioTrackInfo = [[TuSDKAudioTrackInfo alloc] initWithCMAudioFormatDescriptionRef:audioFormatDescriptionRef];
                    CFRelease(audioFormatDescriptionRef);
                    [audioTrackInfoArray addObject:audioTrackInfo];
                }
                
                
            }];
            
            
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
    [_audioTrackInfoArray enumerateObjectsUsingBlock:^(TuSDKAudioTrackInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [description appendFormat:@"\n [ \n trackIndex : %ld \n %@ \n ]\n",idx,obj];
    }];
    
    return description;
}

@end

#pragma mark - TuSDKAudioTrackInfo

@implementation TuSDKAudioTrackInfo

/**
 根据 CMAudioFormatDescriptionRef 初始化 TuSDKAudioTrackInfo
 
 @param audioFormatDescriptionRef CMAudioFormatDescriptionRef
 @return TuSDKAudioTrackInfo
 */
- (instancetype)initWithCMAudioFormatDescriptionRef:(CMAudioFormatDescriptionRef)audioFormatDescriptionRef
{
     if (!audioFormatDescriptionRef) return nil;
    
    if (self = [self initWithAudioStreamBasicDescription: CMAudioFormatDescriptionGetStreamBasicDescription (audioFormatDescriptionRef)])
    {
        _audioFormatDescriptionRef =  CFRetain(audioFormatDescriptionRef);
    }
    
    return self;
}

- (instancetype)initWithAudioStreamBasicDescription:(AudioStreamBasicDescription *)audioStreamBasicDescription;
{
    if (self = [super init])
    {
        _sampleRate = audioStreamBasicDescription -> mSampleRate;
        _channelsPerFrame = audioStreamBasicDescription -> mChannelsPerFrame;
        _bytesPerPacket = audioStreamBasicDescription -> mBytesPerPacket;
        _bitsPerChannel = audioStreamBasicDescription -> mBitsPerChannel;
        _framesPerPacket = audioStreamBasicDescription -> mFramesPerPacket;
    }
    
    return self;
}

/**
 TuSDKAudioTrackInfo
 
 @param audioTrack (AVAssetTrack *)
 @return TuSDKAudioTrackInfo
 */
+ (instancetype)trackInfoWithAudioAssetTrack:(AVAssetTrack *)audioTrack
{
    NSArray *audioFormatInfos = audioTrack.formatDescriptions;
    if ([audioFormatInfos count] > 0)
    {
        CMAudioFormatDescriptionRef audioFormatDescriptionRef = (CMAudioFormatDescriptionRef)CFBridgingRetain([audioFormatInfos objectAtIndex:0]);
        TuSDKAudioTrackInfo *audioTrackInfo = [[TuSDKAudioTrackInfo alloc] initWithCMAudioFormatDescriptionRef:audioFormatDescriptionRef];
        CFRelease(audioFormatDescriptionRef);
        return audioTrackInfo;
    }
    
    return nil;
}

- (instancetype)init{
    if (self = [super init])
    {
        _sampleRate = 44100;
        _channelsPerFrame = 2;
        _bitsPerChannel = 16;
    }
    
    return self;
}

/**
 描述信息
 
 @return NSString
 @since v3.0
 */
- (NSString *)description;
{
    NSMutableString *description = [NSMutableString new];
    [description appendFormat:@"  sampleRate : %f \n ",_sampleRate];
    [description appendFormat:@"  channelsPerFrame : %d \n ",_channelsPerFrame];
    [description appendFormat:@"  bytesPerPacket : %d \n ",_bytesPerPacket];
    [description appendFormat:@"  bitsPerChannel : %d \n ",_bitsPerChannel];
    [description appendFormat:@"  framesPerPacket : %d \n ",_framesPerPacket];
    return description;
}


- (void)dealloc
{
    if (_audioFormatDescriptionRef) {
        CFRelease(_audioFormatDescriptionRef);
        _audioFormatDescriptionRef = nil;
    }
}

@end
