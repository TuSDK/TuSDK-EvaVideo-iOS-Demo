//
//  TTDirectorMediator.m
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2022/6/16.
//  Copyright © 2022 TuSdk. All rights reserved.
//

#import "TTDirectorMediator.h"


#import <TuSDKPulseEva/TUPEvaModel.h>
#import <TuSDKPulseEva/TUPEvaDirector.h>
#import <TuSDKPulseCore/TuSDKPulseCore.h>

static TTDirectorMediator *_directorMediator;

@interface TTDirectorMediator()<TUPPlayerDelegate, TUPProducerDelegate>
/// eva 模型
@property (nonatomic, strong) TUPEvaModel *model;
/// eva文件路径
@property (nonatomic, strong) NSString *evaPath;
/// eva模型管理器
@property (nonatomic, strong) TUPEvaDirector *evaDirector;
/// eva 播放器
@property (nonatomic, strong) TUPEvaDirectorPlayer *evaPlayer;
/// eva渲染视图
@property (nonatomic, strong) TUPDisplayView *displayView;
/// eva导出器
@property (nonatomic, strong) TUPEvaDirectorProducer *producer;

@end

@implementation TTDirectorMediator
///**
// *  eva播放导出器
// *  @return TTDirectorMediator
// */
//+ (TTDirectorMediator *)shareMediator;
//{
//    static dispatch_once_t once = 0;
//    dispatch_once(&once, ^{
//        _directorMediator = [[self alloc] init];
//    });
//    return _directorMediator;
//}

- (instancetype)init
{
    if (self = [super init]) {
        
    }
    return self;
}

/**
 * 第一步 : eva 模型创建
 * @param evaPath 文件路径
 * @return 创建成功
 */
- (BOOL)setup:(NSString *)evaPath;
{
    self.evaPath = evaPath;
    //如果eva文件不存在
    if (!evaPath) {
        return NO;
    }
    self.model = [[TUPEvaModel alloc] init:evaPath];
    //self.model 创建失败
    if (!self.model) {
        return NO;
    }
    
    return YES;
}

- (void)setupEvaDirector
{
    self.evaDirector = [[TUPEvaDirector alloc] init];
    [self.evaDirector openModel:self.model];
    // 创建eva播放器
    self.evaPlayer = (TUPEvaDirectorPlayer *)[self.evaDirector newPlayer];
    [self.evaPlayer open];
    self.evaPlayer.delegate = self;
}

/**
 * 第二步 : 加载eva播放器
 * @param rootView 播放器承载背景视图
 * @param rect frame
 * @return 是否加载成功
 */
- (BOOL)setupView:(UIView *)rootView rect:(CGRect)rect;
{
    if (!rootView) {
        NSLog(@"TUEVA:视图加载失败");
        return NO;
    }
    [self setupEvaDirector];
    self.displayView = [[TUPDisplayView alloc] init];
    [rootView addSubview:self.displayView];
    [self.displayView setup:nil];
    
    self.displayView.frame = rect;
    
    BOOL success = [self.displayView attachPlayer:self.evaPlayer];
    if (!success) {
        NSLog(@"TUEVA:eva播放器加载失败");
        return success;
    }
    return success;
}
/**
 * 替换图片/视频坑位
 * @param videoItem 视频组件
 * @return 替换成功
 */
- (BOOL)updateVideoOrImage:(TAEModelVideoItem *)videoItem;
{
    if (!videoItem) return NO;
    TUPEvaReplaceConfig_ImageOrVideo *imageConfig = [[TUPEvaReplaceConfig_ImageOrVideo alloc] init];
    imageConfig.start = videoItem.start;
    imageConfig.duration = videoItem.duration;
    imageConfig.audioMixWeight = videoItem.audioMixWeight;
    if (videoItem.isEdit) {
        imageConfig.crop = videoItem.crop;
    } else {
        //未编辑的资源默认居中裁剪处理
        imageConfig.crop = CGRectMake(0, 0, 0, 0);
    }
    imageConfig.maxSide = videoItem.maxSide;
    
    NSString *filePath = videoItem.replaceResPath;
    if ([filePath hasPrefix:@"file://"]) {
        filePath = [filePath componentsSeparatedByString:@"file://"].lastObject;
    }
    NSLog(@"TUEVA:资源路径==%@", filePath);
    if (videoItem.isVideo) {
        return [self.evaDirector updateVideo:videoItem.Id withPath:filePath andConfig:imageConfig];
    } else {
        return [self.evaDirector updateImage:videoItem.Id withPath:filePath andConfig:imageConfig];
    }
    
}
/**
 * 替换文字坑位
 * @param textItem 文字组件
 * @return 替换成功
 */
- (BOOL)updateText:(TAEModelTextItem *)textItem;
{
    if (!textItem) return NO;
    return [self.evaDirector updateText:textItem.Id withText:textItem.text];
}

/**
 * 替换背景音乐坑位
 * @param audioItem 音乐组件
 * @return 替换成功
 */
- (BOOL)updateAudio:(TAEModelAudioItem *)audioItem;
{
    if (!audioItem) return NO;
    TUPEvaReplaceConfig_Audio *audioConfig = [[TUPEvaReplaceConfig_Audio alloc] init];
    audioConfig.start = 0;
    audioConfig.duration = [self getDuration];
    audioConfig.audioMixWeight = audioItem.audioMixWeight;
    
    return [self.evaDirector updateAudio:audioItem.Id withPath:audioItem.resPath andConfig:audioConfig];
}

#pragma mark - player
/**
 * 定位到指定时间
 * @param time 时间
 * @return 跳转成功
 */
- (BOOL)seekTo:(NSInteger)time;
{
    return [self.evaPlayer seekTo:time];
}

/**
 * 画面定位到指定时间
 * @param time 时间
 * @return 跳转成功
 */
- (BOOL)previewFrame:(NSInteger)time;
{
    return [self.evaPlayer previewFrame:time];
}

/// 播放
- (BOOL)play;
{
    return [self.evaPlayer play];
}

/// 暂停
- (BOOL)pause;
{
    return [self.evaPlayer pause];
}

#pragma mark - destory

/// 重置
- (void)reset;
{
    [self.evaPlayer close];
    [self.displayView teardown];
    [self.evaDirector close];
}

/// 销毁
- (void)destory;
{
    if (_evaDirector) {
        [_evaPlayer close];
        [_displayView teardown];
        [_evaDirector close];
    }
}

#pragma mark - Producer
/// 开始导出
- (void)startProducer
{
    // 必须暂停eva播放器
    [self pause];
    /**
     导出配置，默认全部导出
     如果导出部分视频则需要配置 rangeStart 和 rangeDuration
     rangeStart ：导出起始时间
     rangeDuration ：导出视频长度
     */
    
    // 6S以下540P, 7P及以下的机型保持最高分辨率是中等，即720p，其它的保证原分辨率
    CGFloat scale = [UIDevice lsqDevicePlatform] <= TuDevicePlatform_iPhone7p ? ([UIDevice lsqDevicePlatform] < TuDevicePlatform_iPhone6s ? 0.5 : 0.67) : 1;
    
    NSString *savePath = [self generateTempFile];
    NSLog(@"TUEVA:本地存储地址 == %@", savePath);
    TUPProducer_OutputConfig *config = [[TUPProducer_OutputConfig alloc] init];
    config.rangeStart = 0;
    config.rangeDuration = [self getDuration];
    config.watermark = [UIImage imageNamed:@"sample_watermark"];
    config.watermarkPosition = -1;
    config.scale = scale;
    
    self.producer = (TUPEvaDirectorProducer *)[self.evaDirector newProducer];
    self.producer.delegate = self;
    self.producer.savePath = [@"file://" stringByAppendingString:savePath];
    
    [self.producer setOutputConfig:config];
    [self.producer open];
    [self.producer start];
}

/// 取消导出器
- (void)cancelProducer;
{
    [self.producer cancel];
}

/// 关闭导出器
- (void)closeProducer;
{
    [self.producer close];
}
/// 重置导出器
- (void)resetProducer;
{
    [self.evaDirector resetProducer];
}


/**
 * 生成临时文件路径
 * @return 文件路径
 */
- (NSString *)generateTempFile;
{
    NSString *path = [TuTSFileManager createDir:[TuTSFileManager pathInCacheWithDirPath:NSTemporaryDirectory() filePath:@""]];
    path = [NSString stringWithFormat:@"%@%f.mp4", path, [[NSDate date]timeIntervalSince1970]];
    
    unlink([path UTF8String]);
    
    return path;
}

#pragma mark - setter getter

- (NSString *)producerPath;
{
    return self.producer.savePath;
}
/**
 * 获取模型尺寸
 * @return 视频模型尺寸
 */
- (CGSize)modelSize;
{
    return [self.model getSize];
}

/**
 * 获取视频总时长
 * @return 视频总时长
 */
- (NSInteger)getDuration;
{
    return [self.evaPlayer getDuration];
}


#pragma mark - TUPPlayerDelegate
/**
 * eva播放器回调
 * @param state 播放器状态
 * @param ts 时间
 */
- (void)onPlayerEvent:(TUPPlayerState)state withTimestamp:(NSInteger)ts
{
    if ([self.delegate respondsToSelector:@selector(directorMediatorPlayerEvent:withTimestamp:)]) {
        [self.delegate directorMediatorPlayerEvent:state withTimestamp:ts];
    }
}
#pragma mark - TUPProducerDelegate
/**
 * eva导出器回调
 * @param state 播放器状态
 * @param ts 时间
 */
- (void)onProducerEvent:(TUPProducerState)state withTimestamp:(NSInteger)ts
{
    if ([self.delegate respondsToSelector:@selector(directorMediatorProducerEvent:withTimestamp:)]) {
        [self.delegate directorMediatorProducerEvent:state withTimestamp:ts];
    }
}

@end
