//
//  EVAPreviewViewController.m
//  TuSDKEvaDemo
//
//  Created by tutu on 2019/6/26.
//  Copyright © 2019 TuSdk. All rights reserved.
//

#import "EVAPreviewViewController.h"
#import "TuSDKFramework.h"
#import "EditViewController.h"
#import "EvaProgressSlider.h"

#import <TuSDKPulseEva/TUPEvaPlayer.h>
#import <TuSDKPulse/TUPDisplayView.h>

#import <TuSDKPulseEva/TUPEvaDirector.h>



@interface EVAPreviewViewController ()<UIGestureRecognizerDelegate, TUPPlayerDelegate>
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
//播放状态
@property (nonatomic, assign) TUPPlayerState playerState;

/**
 eva 资源加载器
 */
@property (nonatomic, strong) TUPDisplayView *displayView;

/**
 eva 播放器
 */

@property (nonatomic, strong) TUPEvaDirectorPlayer *evaPlayer;

/**
 eva 播放器
 */
@property (nonatomic, strong) TUPEvaDirector *evaDirector;

/**
 文字资源
 */
@property (nonatomic, strong) NSMutableArray *texts;

/**
 图片资源
 */
@property (nonatomic, strong) NSMutableArray *medias;

/**
 音频
 */
@property (nonatomic, strong) NSMutableArray *audios;

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

/**暂停时间*/
@property (nonatomic, assign) NSInteger pauseTime;

@end

@implementation EVAPreviewViewController

#pragma mark - Init

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _editStatus = NO;
    
    [self commonInit];
    
    [self loadTemplate];
    
    // 添加后台、前台切换的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackFromFront) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterFrontFromBack) name:UIApplicationDidBecomeActiveNotification object:nil];
}


- (void)dealloc {
    NSLog(@"EVAPreviewViewController------dealloc");
    
    if (!_editStatus) {
        if (_evaDirector) {
            [_evaPlayer close];
            [_displayView teardown];
            [_evaDirector close];
        }
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
    
    _texts = [NSMutableArray array];
    _medias = [NSMutableArray array];
    _audios = [NSMutableArray array];
    [self refreshUI];
    self.previewSuperView.hidden = YES;
    self.slider.hidden = YES;
    self.textSuperView.hidden = YES;
    self.evaTitle.hidden = YES;
    self.makeBtn.hidden = YES;
    self.durationView.hidden = YES;
    self.playBtn.hidden = YES;
    
    
    self.displayView = [[TUPDisplayView alloc] init];
    [self.preview addSubview:self.displayView];
    
    [self.displayView setup:nil];
    
    self.displayView.frame = self.preview.bounds;
}


- (void)refreshUI {
    self.text.text = [NSString stringWithFormat:@"文字 %ld段", self.texts.count];
    self.media.text = [NSString stringWithFormat:@"图片/视频 %ld个", self.medias.count];
    self.music.text = [NSString stringWithFormat:@"音乐 %ld段", self.audios.count];
    
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
        self.displayView.hidden = NO;
    }];
}


// 加载模板
- (void)loadTemplate {
    
    TUPEvaModel *model = [[TUPEvaModel alloc] init:_evaPath];
    if (model == nil) {
        //[[TuSDK shared].messageHub showError:@"  模板有误   "];
        if (self.loadTempleError) {
            self.loadTempleError();
        }
        return;
    }
    
    _texts = [NSMutableArray arrayWithArray:[model listReplaceableTextAssets]];
    _medias = [NSMutableArray arrayWithArray:[model listReplaceableVideoAssets]];
    [_medias addObjectsFromArray:[model listReplaceableImageAssets]];
    _audios = [NSMutableArray arrayWithArray:[model listReplaceableAudioAssets]];


    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshUI];
        
        TUPEvaModel *model = [[TUPEvaModel alloc]init:self.evaPath];
        self.evaDirector = [[TUPEvaDirector alloc] init];
        [self.evaDirector openModel:model];
        
        self.evaPlayer = (TUPEvaDirectorPlayer *)[self.evaDirector newPlayer];
        [self.evaPlayer open];
        self.evaPlayer.delegate = self;
        
        self.totalTime = [self.evaPlayer getDuration];

        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_TARGET_QUEUE_DEFAULT, 0), ^{
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.displayView attachPlayer:weakSelf.evaPlayer];
                [weakSelf.evaPlayer play];
            });
        });
    });
}

#pragma mark - back & front
- (void)enterBackFromFront
{
    if (self.evaPlayer && self.playerState == kPLAYING) {
        [self.evaPlayer pause];
    }
}

- (void)enterFrontFromBack
{
    if (self.evaPlayer) {
        [self.evaPlayer play];
    }
}


#pragma mark - actions
// 去制作
- (IBAction)clickMake:(UIButton *)sender {
    if (self.displayView == nil) return;
    [self.evaPlayer pause];
    _editStatus = YES;
    //eva播放器关闭
    if (_evaDirector) {
        [_evaPlayer close];
        [_displayView teardown];
        [_evaDirector close];
    }
    
    EditViewController *edit = [[EditViewController alloc] initWithNibName:nil bundle:nil];
    edit.evaPath = self.evaPath;
//    edit.displayView = self.displayView;
    [self showViewController:edit sender:nil];
}


// 播放进度拖拽
- (IBAction)sliderValueChanged:(UISlider *)sender {
    if (self.evaPlayer == nil ) return;
    if (!_isSeek) {
        _isSeek = YES;
        _sliderBefore = self.playerState != kPLAYING;
        _lastProgress = 0;
    }
    [_evaPlayer pause];
    
    NSInteger seekTime = sender.value * self.totalTime;
    
    [self.evaPlayer seekTo:seekTime];
    _lastProgress = sender.value;
    NSInteger sliderTime = self.totalTime * _lastProgress;
    self.duration.text = [NSString stringWithFormat:@"%@/%@", [self evaFileTotalTime:sliderTime], [self evaFileTotalTime:self.totalTime]];
}

// 进度拖拽完成
- (IBAction)sliderCompleted:(UISlider *)sender {
    if (self.evaPlayer == nil ) return;
    if (_sliderBefore) {
        [self.evaPlayer previewFrame:self.totalTime * _lastProgress];
    }
    _isSeek = NO;
}

- (IBAction)lastFrame:(UIButton *)sender {
    if (self.evaPlayer == nil ) return;
    [self.evaPlayer pause];
    [self.evaPlayer seekTo:self.totalTime];
    self.slider.value = 1.0;
    [self.evaPlayer previewFrame:self.totalTime];
}

- (IBAction)firstFrame:(UIButton *)sender {
    if (self.evaPlayer == nil ) return;
    [self.evaPlayer pause];
    [self.evaPlayer seekTo:0];
    self.slider.value = self.lastProgress = 0.0;
    [self.evaPlayer previewFrame:0];
    
}


// 预览播放点击
- (IBAction)tapPreView: (UITapGestureRecognizer *)tap {
    
    if (self.evaPlayer == nil) return;
    
    if (self.playerState == kPLAYING) {
        [self.evaPlayer pause];

    } else {
        if (self.slider.value >= 0.99) {
            [self.evaPlayer seekTo:0];
            self.duration.text = [NSString stringWithFormat:@"00:00/%@", [self evaFileTotalTime:self.totalTime]];
        }
        [self.evaPlayer play];
    }
}

#pragma mark - TUPPlayerDelegate
- (void)onPlayerEvent:(TUPPlayerState)state withTimestamp:(NSInteger)ts
{
    self.playerState = state;
    //NSLog(@"当前时间 ===%ld", (long)ts);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (state == kDO_PAUSE || state == kEOS) {
            self.playBtn.hidden = NO;
        } else {
            self.playBtn.hidden = YES;
        }
        if (ts != 0) {
            self.lastProgress = [[NSString stringWithFormat:@"%.5f", ts * 1000.f / self.totalTime / 1000] floatValue];
        }
        
        //NSLog(@"进度条君要挺住 === %.5f", self.lastProgress);
        
        self.duration.text = [NSString stringWithFormat:@"%@/%@", [self evaFileTotalTime:self.pauseTime], [self evaFileTotalTime:self.totalTime]];
        
        if (self.lastProgress != 0) {
            self.slider.value = self.lastProgress;
            self.pauseTime = self.lastProgress * self.totalTime;
            
            //最后一秒不置为0
            if (self.lastProgress >= 0.99) {
                self.duration.text = [NSString stringWithFormat:@"%@/%@", [self evaFileTotalTime:self.totalTime], [self evaFileTotalTime:self.totalTime]];
            }
        }
        
        if (self.slider.value == 0 && self.lastProgress == 0) {
            self.duration.text = [NSString stringWithFormat:@"00:00/%@", [self evaFileTotalTime:self.totalTime]];
        }
        
    });
}

//时间转换
- (NSString *)evaFileTotalTime:(NSInteger)currentTime
{
    //NSLog(@"视频时间长度 == %ld", (long)self.totalTime);
    
    NSString *time = @"00:00";
    NSInteger duration = currentTime / 1000;
    if (duration <= 0) {
        return @"00:00";
    } else if (duration > 0 && duration < 10) {
        return [NSString stringWithFormat:@"00:0%ld", (long)duration];
    } else if (duration >= 10 && duration < 60) {
        return [NSString stringWithFormat:@"00:%ld", (long)duration];
    } else {
        NSInteger seconds = duration / (1000 * 60);
        NSString *secondStr;
        if (seconds > 0 && seconds < 10) {
            secondStr = [NSString stringWithFormat:@"0%ld", (long)seconds];
        } else {
            secondStr = [NSString stringWithFormat:@"%ld", (long)seconds];
        }
        NSInteger mSeconds = duration % (1000 * 60);
        NSString *mSecondStr;
        if (mSeconds > 0 && mSeconds < 10) {
            mSecondStr = [NSString stringWithFormat:@"0%ld", (long)mSeconds];
        } else {
            mSecondStr = [NSString stringWithFormat:@"%ld", (long)mSeconds];
        }
        time = [NSString stringWithFormat:@"%@:%@", secondStr, mSecondStr];
    }
    
    return time;
}

@end
