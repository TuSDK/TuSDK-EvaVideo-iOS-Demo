//
//  EVAPreviewViewController.m
//  TuSDKEvaDemo
//
//  Created by tutu on 2019/6/26.
//  Copyright © 2019 TuSdk. All rights reserved.
//

#import "EVAPreviewViewController.h"
#import "EVAMutiAssetPickerController.h"

#import "TuSDKFramework.h"
#import "EditViewController.h"
#import "EvaProgressSlider.h"
#import "TAEModelMediator.h"

#define videoPathHost @"https://files.tusdk.com/miniprogram/eva/"
#define timeScale 20
#define defaultPlay NO    //默认是否播放

@interface EVAPreviewViewController ()<UIGestureRecognizerDelegate>
{
    BOOL _editStatus;
}
@property (weak, nonatomic) IBOutlet UIView *preview;
@property (weak, nonatomic) IBOutlet UIView *previewSuperView;
@property (weak, nonatomic) IBOutlet EvaProgressSlider *slider;
@property (weak, nonatomic) IBOutlet UIButton *makeBtn;
@property (weak, nonatomic) IBOutlet UILabel *text;
@property (weak, nonatomic) IBOutlet UILabel *media;
@property (weak, nonatomic) IBOutlet UILabel *music;
@property (weak, nonatomic) IBOutlet UILabel *duration;
@property (weak, nonatomic) IBOutlet UILabel *evaTitle;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *makeButtonBottom;
@property (weak, nonatomic) IBOutlet UIStackView *textSuperView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewSuperHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewHeight;
@property (weak, nonatomic) IBOutlet UIView *durationView;

@property (weak, nonatomic) IBOutlet UIButton *playBtn;

/**
 slider Befor
 */
@property (nonatomic, assign) BOOL sliderBefore;
/**
 是否seek
 */
@property (nonatomic, assign) BOOL isSeek;

/** 上次拖拽的进度 */
@property (nonatomic, assign) CGFloat lastProgress;
/**eva总时长*/
@property (nonatomic, assign) NSInteger totalTime;

/**eva模型*/
@property (nonatomic, strong) TAEModelMediator *evaMediator;
/**播放器*/
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;

/**播放时长观察者*/
@property (nonatomic) id timeObserve;
/**是否正在播放*/
@property (nonatomic, assign) BOOL isPlaying;


@end

@implementation EVAPreviewViewController

#pragma mark - Init

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _editStatus = NO;
    
    NSLog(@"TUEVA::预览页进入");
    
    [self commonInit];
    
    [self loadTemplate];
    
    // 添加后台、前台切换的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackFromFront) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterFrontFromBack) name:UIApplicationDidBecomeActiveNotification object:nil];
}


- (void)dealloc {
    NSLog(@"EVAPreviewViewController------dealloc");
    
    if (self.playerLayer) {
        [self.playerLayer removeFromSuperlayer];
        self.playerLayer = nil;
    }
    
    if (self.timeObserve) {
        [self.player pause];
        [self.player removeTimeObserver:self.timeObserve];
        self.timeObserve = nil;
        [self.player.currentItem removeObserver:self forKeyPath:@"status"];
        [self.player.currentItem cancelPendingSeeks];
        [self.player.currentItem.asset cancelLoading];
        self.player = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
}


- (void)commonInit {
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
    self.navigationItem.title = @"模板详情";
    self.evaTitle.text = _modelTitle;
    
    [self.slider setThumbImage:[UIImage imageNamed:@"circle_s_ic"] forState:UIControlStateNormal];
    self.slider.value = 0.0;
    
    self.makeBtn.layer.cornerRadius = 26;
    self.makeBtn.layer.masksToBounds = YES;
    self.makeBtn.backgroundColor = [UIColor colorWithRed:0 green:122.0/255.0 blue:1.0 alpha:1.0];
    
    [self refreshUI];
    self.previewSuperView.hidden = YES;
    self.slider.hidden = YES;
    self.textSuperView.hidden = YES;
    self.evaTitle.hidden = YES;
    self.makeBtn.hidden = YES;
    self.durationView.hidden = YES;
    self.playBtn.hidden = defaultPlay;
    self.isPlaying = defaultPlay;
    
    //创建播放器
    NSString *videoPath = [videoPathHost stringByAppendingString:[NSString stringWithFormat:@"%@.mp4", _ID]];
    NSLog(@"TUEVA::视频路径===%@", videoPath);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:videoPath]];
        self.totalTime = CMTimeGetSeconds(playerItem.asset.duration) * 1000;
        
        self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];

        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
        self.playerLayer.frame = self.preview.bounds;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.preview.layer addSublayer:self.playerLayer];

            // 默认是否播放
            if (defaultPlay) {
                [self.player play];
            }

            __weak typeof(self)weakSelf = self;
            self.timeObserve = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, timeScale) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
                
                if (!weakSelf.isPlaying) return;

                NSInteger currentTime = CMTimeGetSeconds(time) * 1000;
                NSLog(@"TUEVA:播放时长===%ld", (long)currentTime);
                [weakSelf playerProgressChange:currentTime];
                weakSelf.lastProgress = [[NSString stringWithFormat:@"%.5f", currentTime * 1000.f / weakSelf.totalTime / 1000] floatValue];
                NSLog(@"TUEVA:播放进度===%.5f", weakSelf.lastProgress);
                weakSelf.slider.value = weakSelf.lastProgress;
            }];
        });
        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];

        
    });
    
    
    //播放器监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruption:) name:AVAudioSessionInterruptionNotification object:nil];
    
}

/// 播放器时间进度
- (void)playerProgressChange:(NSInteger)currentTime;
{
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowBlurRadius = 5;
    shadow.shadowOffset = CGSizeMake(0, 0);
    shadow.shadowColor = [UIColor blackColor];
    NSString *progressStr = [NSString stringWithFormat:@"%@/%@", [self.evaMediator evaFileTotalTime:currentTime], [self.evaMediator evaFileTotalTime:self.totalTime]];
    
    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:progressStr attributes:@{NSShadowAttributeName:shadow}];
    self.duration.attributedText = attString;
}



- (void)playFinish:(NSNotification *)noti
{
    self.isPlaying = NO;
    self.playBtn.hidden = NO;
    NSLog(@"TUEVA:播放完成");
}

- (void)interruption:(NSNotification *)noti
{
    [self.player pause];
    self.isPlaying = NO;
    self.playBtn.hidden = NO;
    NSLog(@"TUEVA:声音被打断（来电话了）");
}


- (void)refreshUI {
    self.text.text = [NSString stringWithFormat:@"文字 %ld段", [self.evaMediator textCount]];
    self.media.text = [NSString stringWithFormat:@"图片/视频 %ld个", [self.evaMediator imageVideoCount]];
    self.music.text = [NSString stringWithFormat:@"音乐 %ld段", [self.evaMediator audioCount]];
    
    [self.view layoutIfNeeded];


    [UIView animateWithDuration:0.25 animations:^{
       [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.previewSuperView.hidden = NO;
        self.slider.hidden = NO;
        self.textSuperView.hidden = NO;
        self.evaTitle.hidden = NO;
        self.makeBtn.hidden = NO;
        self.durationView.hidden = NO;
    }];
}


// 加载模板
- (void)loadTemplate {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        self.evaMediator = [[TAEModelMediator alloc] initWithEvaPath:self.evaPath];
        BOOL state = [self.evaMediator loadResource];
        if (!state) {
            //[[TuSDK shared].messageHub showError:@"  模板有误   "];
            if (self.loadTempleError) {
                self.loadTempleError();
            }
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self refreshUI];
        });
    });

    
}

#pragma mark - back & front
- (void)enterBackFromFront
{
    if (self.player && self.isPlaying) {
        [self.player pause];
        self.isPlaying = self.playBtn.hidden = NO;
    }
}

- (void)enterFrontFromBack
{
//    NSLog(@"回到前台");
}


#pragma mark - actions
// 去制作
- (IBAction)clickMake:(UIButton *)sender {
    
    EVAMutiAssetPickerController *controller = [[EVAMutiAssetPickerController alloc] init];
    controller.evaMediator = self.evaMediator;
    [self showViewController:controller sender:nil];
}


// 播放进度拖拽
- (IBAction)sliderValueChanged:(UISlider *)sender {
    
    
    if (!self.player) return;
    if (!_isSeek) {
        _isSeek = YES;
        _lastProgress = 0;
    }
    self.isPlaying = self.playBtn.hidden = NO;
    [self.player pause];
    
    NSInteger seekTime = sender.value * self.totalTime / 1000;
    NSLog(@"TUEVA::拖拽时间===%ld", (long)seekTime);
    [self.player seekToTime:CMTimeMakeWithSeconds(seekTime, timeScale)];
    _lastProgress = sender.value;
    NSInteger sliderTime = self.totalTime * _lastProgress;
    [self playerProgressChange:sliderTime];
}

// 进度拖拽完成
- (IBAction)sliderCompleted:(UISlider *)sender {
    
    
    if (!self.player) return;
    if (_sliderBefore) {
        NSInteger seekTime = self.totalTime * _lastProgress / 1000;
        [self.player seekToTime:CMTimeMakeWithSeconds(seekTime, timeScale)];
    }
    _isSeek = NO;
}

- (IBAction)lastFrame:(UIButton *)sender {
    if (!self.player) return;
    [self.player pause];
    self.isPlaying = self.playBtn.hidden = NO;
    NSLog(@"TUEVA::结束时间===%ld", self.totalTime / 1000);
    [self.player seekToTime:CMTimeMakeWithSeconds(self.totalTime / 1000, timeScale)];
    [self playerProgressChange:self.totalTime];
    self.slider.value = 1.0;
}

- (IBAction)firstFrame:(UIButton *)sender {
    if (!self.player) return;
    
    [self.player pause];
    [self.player seekToTime:kCMTimeZero];
    self.isPlaying = self.playBtn.hidden = YES;
    self.slider.value = self.lastProgress = 0.0;
    [self.player play];
}


// 预览播放点击
- (IBAction)tapPreView: (UITapGestureRecognizer *)tap {
    
    if (!self.player) return;
    
    if (self.isPlaying) {
        self.isPlaying = NO;
        [self.player pause];
        NSLog(@"TUEVA::暂停播放");
    } else {
        if (self.slider.value == 1.0) {
//            self.duration.text = [NSString stringWithFormat:@"00:00/%@", [self.evaMediator evaFileTotalTime:self.totalTime]];
            [self playerProgressChange:0];
            [self.player seekToTime:kCMTimeZero];
        }
        self.isPlaying = YES;
        [self.player play];
        NSLog(@"TUEVA::开始播放");
    }
    self.playBtn.hidden = self.isPlaying;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        switch (self.player.status) {
            case AVPlayerStatusUnknown:
                NSLog(@"TUEVA::播放器状态未知");
                break;
            case AVPlayerStatusReadyToPlay:
                NSLog(@"TUEVA::准备完毕，可以播放");
                break;
            case AVPlayerStatusFailed:
                NSLog(@"TUEVA::加载失败，请检查网络");
                break;
            default:
                break;
        }
    }
}

@end
