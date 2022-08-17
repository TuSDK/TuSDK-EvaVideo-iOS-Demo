//
//  VideoEditViewController.m
//  TuSDKEvaDemo
//
//  Created by tutu on 2019/6/26.
//  Copyright © 2019 TuSdk. All rights reserved.
//

#import "VideoEditViewController.h"
#import "TuSDKFramework.h"
#import "SegmentButton.h"
#import "VideoTrimmerView.h"
#import "TrimmerMaskView.h"
#import "VideoCuteView.h"
#import <AVFoundation/AVFoundation.h>
#import <TuSDKPulse/TUPVideoPlayer.h>
#import <TuSDKPulse/TUPDisplayView.h>
#import <TuSDKPulse/TUPTranscoder.h>
#import "TuSDKVideoImageExtractor.h"
#import "TuPopupProgress.h"
//#import "TuSDKMediaAsset.h"
// 最小剪裁时长
static const NSTimeInterval kMinCutDuration = 1.0;

@interface VideoEditViewController ()<VideoTrimmerViewDelegate, UIGestureRecognizerDelegate, TUPPlayerDelegate, TUPProducerDelegate>
{
    UIButton *_saveBtn;
}
/**
 时间修整视图
 */
@property (weak, nonatomic) IBOutlet VideoTrimmerView *videoTrimmerView;

@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UILabel *timeMark;

/**
 视频预览视图
 */
@property (weak, nonatomic) IBOutlet VideoCuteView *playerView;

/**
 播放按钮
 */
@property (weak, nonatomic) IBOutlet UIButton *playButton;

/**
 标识是否删除生成的临时文件
 */
@property (nonatomic, assign) BOOL removeTempFileFlag;

/**
 播放器
 */
@property (nonatomic, strong) TUPVideoPlayer *videoPlayer;
/**
 资源加载器
 */
@property (nonatomic, strong) TUPDisplayView *displayView;

//播放状态
@property (nonatomic, assign) TUPPlayerState playerState;

/**
 暂停时进度
 */
@property (nonatomic, assign) CGFloat lastProgress;
/**
 截取最大时长
 */
@property (nonatomic, assign) float maxVideoPlayerTime;
/**
 开始时间
 */
@property (nonatomic, assign) NSInteger startVideoTime;
/**
 时间间隔
 */
@property (nonatomic, assign) NSInteger timeDuration;
/**转码器*/
@property (nonatomic, strong) TUPTranscoder *transCoder;

@property (nonatomic, copy) NSString *savePath;



@end


@implementation VideoEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    
    // 添加后台、前台切换的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackFromFront) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterFrontFromBack) name:UIApplicationWillEnterForegroundNotification object:nil];
        
    self.startVideoTime = 0;
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (_videoPlayer)
    {
        [_videoPlayer close];
        [_displayView teardown];
        
    }
     [_transCoder close];

    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    NSLog(@"%@", NSStringFromCGRect(_playerView.displayView.frame));
    self.playerView.regionRatio = _cutSize.width / _cutSize.height;
    self.displayView.frame = _playerView.displayView.frame;
}


- (void)setupUI {
    
    if (_inputAssets.count == 0 && self.filePath) {
        if ([self.filePath hasPrefix:@"file://"]) {
            
            AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL URLWithString:self.filePath]];
            self.inputAssets = @[asset];
        } else {
            
            AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:self.filePath]];
            self.inputAssets = @[asset];
        }
    }
    
    NSArray *tracks = [self.inputAssets.firstObject tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        CGSize size = videoTrack.naturalSize;
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            
            size = CGSizeMake(videoTrack.naturalSize.height, videoTrack.naturalSize.width);

        }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            size = CGSizeMake(videoTrack.naturalSize.height, videoTrack.naturalSize.width);
        }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            size = videoTrack.naturalSize;
            // LandscapeRight
        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            size = videoTrack.naturalSize;
        }
        NSLog(@"TUEVA:video width:%f, video height:%f",size.width,size.height);//宽高
        self.playerView.videoSize = size;
    }
    [self setupPlayer];
    [self setupUIAfterAssetsPrepared];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
    self.navigationItem.title = @"编辑";
    
    _saveBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [_saveBtn setTitle:@"确定" forState:UIControlStateNormal];
    _saveBtn.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    [_saveBtn setTitleColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    [_saveBtn addTarget:self action:@selector(confirm) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_saveBtn];
    
    
}


/**
 创建并配置播放器
 */
- (void)setupPlayer {
    
    self.displayView = [[TUPDisplayView alloc] init];
    [self.playerView.displayView addSubview:self.displayView];
    
    [self.displayView setup:nil];
    
    
    self.videoPlayer = [[TUPVideoPlayer alloc] init];
    self.videoPlayer.delegate = self;
    [self.videoPlayer open:self.filePath];
    
    [self.displayView attachPlayer:self.videoPlayer];
    [self.videoPlayer previewFrame:0];

    _slider.value = 1.0;
    
}

/**
 配置其他 UI
 */
- (void)setupUIAfterAssetsPrepared
{
    NSTimeInterval duration = [self.videoPlayer getDuration];

    // 获取缩略图
    TuSDKVideoImageExtractor *imageExtractor = [TuSDKVideoImageExtractor createExtractor];
    //imageExtractor.isAccurate = YES; // 精确截帧
    imageExtractor.videoAssets = _inputAssets;
    const NSInteger frameCount = 10;
    imageExtractor.extractFrameCount = frameCount;
    _videoTrimmerView.thumbnailsView.thumbnailCount = frameCount;
    // 异步渐进式配置缩略图
    [imageExtractor asyncExtractImageWithHandler:^(UIImage * _Nonnull frameImage, NSUInteger index) {
        [self.videoTrimmerView.thumbnailsView setThumbnail:frameImage atIndex:index];
    }];
    
    // 配置最短截取时长
    _videoTrimmerView.minIntervalProgress = [self currentCutMinDuration] / duration;
    
    // 设置目前的范围
    self.maxVideoPlayerTime = self.durationTime * 1.f / 1000;
    if (self.durationTime > [self.videoPlayer getDuration]) {
        self.durationTime = [self.videoPlayer getDuration];
        self.maxVideoPlayerTime = [self.videoPlayer getDuration] * 1.f / 1000;
    }
    _timeMark.text = [NSString stringWithFormat:@"需截取视频的时长范围为：%0.1f至%0.1f", [self currentCutMinDuration], self.maxVideoPlayerTime];
    self.timeDuration = self.durationTime;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.videoTrimmerView.endProgress = self.maxVideoPlayerTime / (duration * 1.f / 1000) ;
    });
}

- (void)confirm
{
    _saveBtn.userInteractionEnabled = NO;
    if (_videoPlayer) {
        [_videoPlayer pause];
    }
    
    TUPProducer_OutputConfig *config = [[TUPProducer_OutputConfig alloc] init];
    config.rangeStart = 0;
    config.rangeDuration = [self.videoPlayer getDuration];
    config.keyint = 1;
    
    _transCoder = [[TUPTranscoder alloc] init];
    
    [_transCoder setOutputConfig:config];
    
    self.savePath = [@"file://" stringByAppendingString:[self generateTempFile]];
    NSLog(@"本地存储地址 == %@", self.savePath);
    _transCoder.savePath = self.savePath;
    _transCoder.delegate = self;
    
    NSString *videoPath = self.filePath;
    [_transCoder open:videoPath];
    [_transCoder start];

}

#pragma mark - TUPPlayerDelegate
- (void)onPlayerEvent:(TUPPlayerState)state withTimestamp:(NSInteger)ts
{
    self.playerState = state;
    NSLog(@"当前时间 ===%ld", (long)ts);

    dispatch_async(dispatch_get_main_queue(), ^{
        self.playButton.hidden = self.playerState == kPLAYING;
        
        NSInteger totalTime = [self.videoPlayer getDuration];
        
        if (ts != 0) {
            self.lastProgress = [[NSString stringWithFormat:@"%.5f", ts * 1000.f / totalTime / 1000] floatValue];
            self.videoTrimmerView.currentProgress = self.lastProgress;
            NSLog(@"进度条君要挺住 === %.5f", self.lastProgress);
        }
    });
}


#pragma mark - 后台切换操作

/**
 进入后台
 */
- (void)enterBackFromFront {

    if (_videoPlayer) {
        [_videoPlayer pause];
    }
}

/**
 后台到前台
 */
- (void)enterFrontFromBack {
    //[[TuSDK shared].messageHub dismiss];
}

#pragma mark - action
/**
 点击手势事件
 
 @param sender 点击手势
 */
- (IBAction)tapAction:(UITapGestureRecognizer *)sender {
        
    if (self.videoPlayer == nil) return;
    
    if (self.playerState == kPLAYING) {
        [self.videoPlayer pause];

    } else {
        if (self.lastProgress >= 0.99) {
            [self.videoPlayer seekTo:0];
        }
        [self.videoPlayer play];
    }
}

/**
 播放按钮事件
 
 @param sender 点击的按钮
 */
- (IBAction)palyButtonAction:(UIButton *)sender {
        
    if (self.videoPlayer == nil) return;
    
    if (self.playerState == kPLAYING) {
        [self.videoPlayer pause];

    } else {
        if (self.lastProgress >= 0.99) {
            [self.videoPlayer seekTo:0];
        }
        [self.videoPlayer play];
    }
}

- (IBAction)volumChanged:(UISlider *)sender {

}

#pragma mark - VideoTrimmerViewDelegate

/**
 时间轴进度更新回调
 
 @param trimmer 时间轴
 @param progress 播放进度
 @param location 进度位置
 */
- (void)trimmer:(id<VideoTrimmerViewProtocol>)trimmer updateProgress:(double)progress atLocation:(TrimmerTimeLocation)location {
    
    NSInteger targetTime = [self.videoPlayer getDuration] * progress;
    
    [self.videoPlayer seekTo:targetTime];
    
    [self.videoPlayer previewFrame:targetTime];
}

/**
 时间轴开始滑动回调
 
 @param trimmer 时间轴
 @param location 进度位置
 */
- (void)trimmer:(id<VideoTrimmerViewProtocol>)trimmer didStartAtLocation:(TrimmerTimeLocation)location {

    _playButton.hidden = YES;
    
    if (_videoPlayer) {
        [_videoPlayer pause];
    }
}

/**
 时间轴结束滑动回调
 
 @param trimmer 时间轴
 @param location 进度位置
 */
- (void)trimmer:(id<VideoTrimmerViewProtocol>)trimmer didEndAtLocation:(TrimmerTimeLocation)location {
    
    self.playButton.hidden = self.playerState == kPLAYING;

    NSInteger duration = [self.videoPlayer getDuration];
    if (duration <= 1) {
        return;
    }
    //如果选择时长小于传入的时长 或者 是小于视频时长
    if ((trimmer.endProgress - trimmer.startProgress) * duration <= self.durationTime) {
        NSLog(@"------------------- 范围小于要选择的视频长度");
        self.timeDuration = (trimmer.endProgress - trimmer.startProgress) * duration;
        
        if (self.timeDuration <= 1000) {
            if (location == TrimmerTimeLocationLeft) {
                // 修整了左边时间，右边时间自适应
                NSInteger endTime = trimmer.startProgress * [self.videoPlayer getDuration] + 1000;
                trimmer.endProgress = endTime * 1.f / [self.videoPlayer getDuration];
                
                // 修整了右边的时间，左边时间自适应
            } else if (location == TrimmerTimeLocationRight) {
                NSInteger startTime = trimmer.endProgress * [self.videoPlayer getDuration] - 1000;
                trimmer.startProgress = startTime * 1.f / [self.videoPlayer getDuration];
            }
            self.startVideoTime = trimmer.startProgress * duration;
        }
        
        return;
    }

    
    self.timeDuration = self.durationTime;
    
    if (location == TrimmerTimeLocationLeft) {
        // 修整了左边时间，右边时间自适应
        NSInteger endTime = trimmer.startProgress * [self.videoPlayer getDuration] + self.durationTime;
        trimmer.endProgress = endTime * 1.f / [self.videoPlayer getDuration];
        
    } else if (location == TrimmerTimeLocationRight) {
        // 修整了右边的时间，左边时间自适应
        NSInteger startTime = trimmer.endProgress * [self.videoPlayer getDuration] - self.durationTime;
        trimmer.startProgress = startTime * 1.f / [self.videoPlayer getDuration];
    }
    self.startVideoTime = trimmer.startProgress * duration;
    
    [self trimmer:trimmer updateProgress:location == TrimmerTimeLocationLeft ? trimmer.startProgress : trimmer.endProgress atLocation:location];
    NSLog(@"目前截取的视频时长：%f", (trimmer.endProgress - trimmer.startProgress) * duration);
}

/**
 时间轴到达临界值回调
 
 @param trimmer 时间轴
 @param reachMaxIntervalProgress 进度最大值
 @param reachMinIntervalProgress 进度最小值
 */
- (void)trimmer:(id<VideoTrimmerViewProtocol>)trimmer reachMaxIntervalProgress:(BOOL)reachMaxIntervalProgress reachMinIntervalProgress:(BOOL)reachMinIntervalProgress {
    
    if (reachMinIntervalProgress) {
        NSString *message = [NSString stringWithFormat:@"视频时长最少%@秒", @([self currentCutMinDuration])];
        [TuPopupProgress showMainThreadWithMessage:message];
    }
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    BOOL skip = NO;
    skip = [_bottomView.layer containsPoint:[touch locationInView:_bottomView]];
    
    if (skip) return NO;
    return YES;
}


#pragma mark - getter setter
- (CGFloat)currentCutMinDuration {
    if (CMTIME_IS_INVALID(self.duration)) {
        return 1;
    }
    if (kMinCutDuration < CMTimeGetSeconds(self.duration)) {
        return kMinCutDuration;
    } else {
        return MAX(CMTimeGetSeconds(self.duration) * 0.5, 0);
    }
}

#pragma mark - TUPProducerDelegate
- (void) onProducerEvent:(TUPProducerState)state withTimestamp:(NSInteger)ts;
{
    if (state == kDO_CANCEL)
    {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        float percent = ts * 1.f / [self.videoPlayer getDuration];
        [TuPopupProgress showProgress:percent status:@"正在处理视频" maskType:TuSDKProgressHUDMaskTypeBlack];
        //NSLog(@"正在处理视频");
        NSLog(@"导出状态 === %ld", state);
        NSLog(@"导出进度 ==== %.5f", percent);
        
        if (state == kEND)
        {
            [TuPopupProgress showSuccessWithStatus:@"处理完成"];
            self->_saveBtn.userInteractionEnabled = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                TUPEvaReplaceConfig_ImageOrVideo *config = [[TUPEvaReplaceConfig_ImageOrVideo alloc] init];
                config.start = self.startVideoTime;
                config.duration = self.timeDuration;
                //设置导出视频最大尺寸
                config.maxSide = 720;
                //NSLog(@"处理视频完成");
                config.crop = self.playerView.cutFrame;
 
                if (self.editCompleted) {
                    self.editCompleted(config, self.savePath);
                }
            });
        }
    });
}

/**
*  生成临时文件路径
*
*  @return 文件路径
*/
- (NSString *) generateTempFile;
{
    
    NSString *path = [TuTSFileManager createDir:[TuTSFileManager pathInCacheWithDirPath:NSTemporaryDirectory() filePath:@""]];
    path = [NSString stringWithFormat:@"%@%f.MOV", path, [[NSDate date]timeIntervalSince1970]];
    
    unlink([path UTF8String]);
    
    return path;
}

@end
