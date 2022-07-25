//
//  EditViewController.m
//  TuSDKEvaDemo
//
//  Created by tutu on 2019/6/26.
//  Copyright © 2019 TuSdk. All rights reserved.
//

#import "EditDynamicViewController.h"
#import "EditCollectionViewCell.h"
#import "MusicView.h"
#import "VideoEditViewController.h"
#import "ImageEditViewController.h"

#import <TuSDKPulseEva/TUPEvaModel.h>
#import <TuSDKPulse/TUPProducer.h>
#import "TuEvaAsset.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MediaPlayer/MPVolumeView.h>
#import <TuSDKPulseEva/TUPDynEvaDirector.h>
#import "TuPopupProgress.h"

#import "TAEExportManager.h"
#import "TAEModelMediator.h"

//#import <GPUUtilization/GPUUtilization.h>

@implementation EditDynamicItem

@end

/** 视频支持的最大边界 */
static const NSUInteger lsqMaxOutputVideoSizeSide = 1080;

@interface EditDynamicViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate, TUPPlayerDelegate, TUPProducerDelegate>

{
    NSInteger _index;
    BOOL _producerCancel;
}
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewSuperHeight;
@property (weak, nonatomic) IBOutlet UIView *previewSuperView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *previewHeight;
@property (weak, nonatomic) IBOutlet UIView *replaceView;

@property (weak, nonatomic) IBOutlet UIView *preview;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UISlider *evaSlider;
@property (weak, nonatomic) IBOutlet UIButton *changeMusicBtn;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UISlider *volmSlider;
@property (weak, nonatomic) IBOutlet UIView *volumView;

///**总时长*/
//@property (nonatomic, strong) UILabel *totalTimelabel;
///**当前播放时长*/
//@property (nonatomic, strong) UILabel *currentPlaylabel;
///**剩余播放时长*/
//@property (nonatomic, strong) UILabel *resetTimelabel;
//@property (nonatomic, strong) UIView *timeView;

/**
 已经选择的路径
 */
@property (nonatomic, strong) NSString *selectedPath;

/**
 eva 播放器
 */
@property (nonatomic, strong) TUPDynEvaDirectorPlayer *evaPlayer;
@property (nonatomic, strong) TUPDynEvaDirector *evaDirector;

/**
 slider Befor
 */
@property (nonatomic, assign) BOOL sliderBefore;
/**
 是否seek
 */
@property (nonatomic, assign) BOOL isSeek;


/* 音乐选择器 */
@property (nonatomic, strong) MusicView *musiView;

/** 上次拖拽的进度 */
@property (nonatomic, assign) CGFloat lastProgress;

/**播放状态*/
@property (nonatomic, assign) TUPPlayerState playerState;

/**存储状态*/
@property (nonatomic, assign) TUPProducerState producerSate;

/**暂停时间*/
@property (nonatomic, assign) NSInteger pauseTime;

/**存储器*/
//@property (nonatomic, strong) TUPEvaProducer *producer;
@property (nonatomic, strong) TUPDynEvaDirectorProducer *producer;


/**音量视图*/
@property (nonatomic, strong) MPVolumeView *volumeView;
@property (nonatomic, strong) UISlider *volumeViewSlider;

/**eva总时长*/
@property (nonatomic, assign) NSInteger totalTime;

@property (nonatomic, assign) BOOL isStart;

@end


@implementation EditDynamicViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self commonInit];
    
    self.isStart = YES;
    _index = 999;
    // 添加后台、前台切换的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackFromFront) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterFrontFromBack) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    self.producerSate = kDO_START;
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    // 移除掉 Preview 避免两个playview的视图同时暂用内存渲染资源
    // 尤其是在低配置的机型上，需要注意
    NSMutableArray *childs = [NSMutableArray array];
    [self.navigationController.childViewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:NSClassFromString(@"EVAPreviewViewController")]) {
            [childs addObject:obj];
        }
    }];
    [self.navigationController setViewControllers:childs];

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
}



/**
 对象消耗回调
 */
- (void)dealloc {
    
    if (self.musiView) {
        [_musiView removeFromSuperview];
        _musiView = nil;
    }
    
    if (_evaDirector) {
        [_evaPlayer close];
        [_displayView teardown];
        [_evaDirector close];
    }

    
    
    // 希望可以及时回收FBO
    NSLog(@"EditViewController ------ dealloc");
    
    //注销系统音量监听
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

- (void)commonInit {
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
    self.navigationItem.title = @"";
    
    self.view.backgroundColor = [UIColor colorWithRed:19.0/255.0 green:19.0/255.0 blue:19.0/255.0 alpha:1.0];
    
    /**
     * 为了防止多次点击保存按钮触发重复保存的操作
     * 请在appDelegate里添加 [TuPopupProgress setDefaultMaskType:TuSDKProgressHUDMaskTypeClear];
     */
    UIButton *saveBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
    [saveBtn setTitle:@"保存" forState:UIControlStateNormal];
    [saveBtn setTitleColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    
    saveBtn.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    [saveBtn addTarget:self action:@selector(saveAction) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:saveBtn];
    
    
    [self.evaSlider setThumbImage:[UIImage imageNamed:@"circle_s_ic"] forState:UIControlStateNormal];
    self.evaSlider.value = 0.0;
    
    self.changeMusicBtn.layer.cornerRadius = 4;
    self.changeMusicBtn.layer.masksToBounds = YES;
    
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"EditCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"EditCollectionViewCell"];
    [self.collectionView reloadData];
        
    // evaplayer加载
    if (_evaPlayer == nil) {

        
        TUPEvaModel *model = [[TUPEvaModel alloc] init:self.evaPath modelType:TUPEvaModelType_DYNAMIC];

        [self.volumeView setVolumeThumbImage:[UIImage imageNamed:@"circle_b_ic"] forState:UIControlStateNormal];
        
        self.volmSlider.hidden = YES;
        [self.volumView addSubview:self.volumeView];
        
        self.volumeView.frame = CGRectMake(CGRectGetMinX(self.volmSlider.frame), 7, CGRectGetWidth(self.volmSlider.frame), CGRectGetHeight(self.volmSlider.frame));
        self.volumeViewSlider.frame = self.volumeView.bounds;
        [self.volumeViewSlider addTarget:self action:@selector(volumeValueChange:) forControlEvents:UIControlEventValueChanged];
        
        // 页面布局
        // 视频预览视图宽高，两边留边12pt
        CGFloat sWidth  = [UIScreen mainScreen].bounds.size.width;
        
        CGFloat tnHeight = [UIDevice lsqIsDeviceiPhoneX] ? (88 + 34) : 64;
        CGFloat sHeight = [UIScreen mainScreen].bounds.size.height - tnHeight - 270;
        CGSize videoSize = [model getSize];
        CGFloat vWidth  = videoSize.width;
        CGFloat vHeight = videoSize.height;

        CGFloat sliderWidth = sWidth;
        if (sWidth/sHeight > vWidth/vHeight) {
            // 视频偏宽
            if (sWidth * (vHeight/vWidth) > sHeight) {
                self.previewHeight.constant = sHeight;
                
                sliderWidth= sHeight * (vWidth/vHeight);

            } else {
                self.previewHeight.constant = sWidth * (vHeight/vWidth);
            }
        } else {
            if (sHeight * (vWidth/vHeight) > sWidth) {
                self.previewHeight.constant = sWidth * (vHeight/vWidth);
            } else {
                self.previewHeight.constant = sHeight;
                sliderWidth= sHeight * (vWidth/vHeight);
            }
        }
            self.previewSuperHeight.constant = self.previewHeight.constant + 10;
            
           
            [self setupPlayer:model];
            
        
        
        [self.view layoutIfNeeded];
                
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        self.volmSlider.value = audioSession.outputVolume;
        NSLog(@"系统媒体音量 === %.2f", audioSession.outputVolume);
        
        //系统音量监听
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeClicked:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        
//        //创建时长视图
//        [self creatShowTimeView];
    }
}
  
- (void)setupPlayer:(TUPEvaModel *)model
{
    self.displayView = [[TUPDisplayView alloc] init];
    [self.preview addSubview:self.displayView];
    [self.displayView setup:nil];
    
    self.displayView.frame = CGRectMake(0, 0, lsqScreenWidth, self.previewHeight.constant);
    
    self.evaDirector = [[TUPDynEvaDirector alloc] init];
    [self.evaDirector openModel:model];
    NSMutableArray *arrs = [NSMutableArray array];
    for (EditDynamicItem *item in self.items) {
        TUPEvaReplaceConfig_ImageOrVideo *config = [[TUPEvaReplaceConfig_ImageOrVideo alloc] init];
        config.path = item.path;
        [arrs addObject:config];
    }
    [self.evaDirector updateResource:[arrs copy]];
    self.evaPlayer = (TUPDynEvaDirectorPlayer *)[self.evaDirector newPlayer];
    [self.evaPlayer open];
    self.evaPlayer.delegate = self;
    
    self.totalTime = [self.evaPlayer getDuration];
    
    [self.displayView attachPlayer:self.evaPlayer];
    [self.evaPlayer play];
}
    

- (void)volumeClicked:(NSNotification *)noti
{
    NSDictionary *userInfo = noti.userInfo;
    float volume = [userInfo[@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    self.volmSlider.value = volume;
}

#pragma mark - back & front
- (void)enterBackFromFront {
    
    if (self.evaPlayer && self.playerState == kPLAYING) {
        
        [self.evaPlayer pause];
    }
    if (self.producer && self.producerSate == kWRITING) {
        
        self.producerSate = kDO_CANCEL;
        [self.producer cancel];
        [self.producer close];
        [self.evaDirector resetProducer];
        [TuPopupProgress dismiss];
        _producerCancel = YES;
    }    
}


- (void)enterFrontFromBack {
    
    //重新创建
    if (self.evaPlayer)
    {
        [self.evaPlayer previewFrame:self.pauseTime];
        [self.evaPlayer seekTo:self.pauseTime];
    }
}

- (void)volumeValueChange:(UISlider *)sender
{
    self.volumeViewSlider.value = sender.value;
}


#pragma mark - UICollectionDatasouce, UICollectionDelegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    EditCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EditCollectionViewCell" forIndexPath:indexPath];
    cell.text.text = @"";
    cell.backgroundImage.image = self.items[indexPath.row].coverImage;
    return cell;
}

#pragma mark - actions

// 音量改变
- (IBAction)volmValueChanged:(UISlider *)sender {
    
    self.volumeViewSlider.value = sender.value;
}

// 进度条值改变
- (IBAction)evaPregressValueChanged:(UISlider *)sender {
    if (self.evaPlayer == nil ) return;
    
    if (!_isSeek) {
        _isSeek = YES;
        _sliderBefore = self.playerState != kPLAYING;
    }
    [self.evaPlayer pause];
    
    // 将拖拽阈值放大
    if (abs(sender.value - _lastProgress) < 0.01) {
        return;
    }
    //拖动时间
    NSInteger seekTime = sender.value * [self.evaPlayer getDuration];
    _lastProgress = sender.value;
    [self.evaPlayer seekTo:seekTime];
}


// 进度条滑动完成
- (IBAction)evaSliderCompeleted:(UISlider *)sender {
    if (self.evaPlayer == nil ) return;

    [self.evaPlayer previewFrame:_lastProgress * [self.evaPlayer getDuration]];
    _isSeek = NO;
}


/**
 选择音乐
 */
- (IBAction)changeMusic:(UIButton *)sender {
    
    
    if (_displayView == nil) {
        //[[TuSDK shared].messageHub showToast:@"此资源不支持替换背景音乐"];
        return;
    }
    
    [self stopEvaPlayer];
    self.musiView.selectedMusicPath = _selectedPath;
    [UIView animateWithDuration:0.25 animations:^{
        self.musiView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    }];
    __weak typeof(self)weakSelf = self;
    [self.musiView setSelectedMusic:^(NSString * _Nonnull musicPath) {
        [UIView animateWithDuration:0.25 animations:^{
            weakSelf.musiView.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        }];
        if (musicPath == nil && weakSelf.selectedPath == nil) return;
        if ([musicPath isEqualToString:weakSelf.selectedPath]) return;
        weakSelf.selectedPath = musicPath;
        [weakSelf replaceEvaTemplate];
    }];
}


// 替换资源后，播放器重载资源
- (void)replaceEvaTemplate {

//    [self stopEvaPlayer];
    
    if (self.evaPlayer) {
        [self.evaPlayer pause];
    }
    
    //替换音乐
    [self.evaDirector updateAudioPath:self.selectedPath];
    [self.evaPlayer previewFrame:self.pauseTime];
    self.evaSlider.value = self.pauseTime / [self.evaPlayer getDuration];
}

// 点击视频视图
- (IBAction)tapPreview:(UITapGestureRecognizer *)sender {
   
    
    if (self.playerState == kPLAYING) {
        [self.evaPlayer pause];

    } else {
        if (self.evaSlider.value >= 0.99 || self.playerState == kEOS) {
            [self.evaPlayer seekTo:0];
        }
        [self.evaPlayer play];
    }
}


// 保存导出
- (void)saveAction
{
    NSString *msg = @"退出应用导出将被取消，是否确认导出?";
    UIAlertController *saveController = [UIAlertController alertControllerWithTitle:nil message:msg preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *receptionAction = [UIAlertAction actionWithTitle:@"导出" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
       
        [self receptionSaveAction];
        
    }];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [saveController addAction:receptionAction];
    [saveController addAction:cancelAction];
    
    [self presentViewController:saveController animated:YES completion:nil];

}

/**
 * 前台导出
 *
 */
- (void)receptionSaveAction
{
    self.totalTime = [self.evaPlayer getDuration];
    
    // 必须停止/暂停播放器
    [self.evaPlayer pause];
        
    NSString *savePath = [self generateTempFile];
//    NSLog(@"本地存储地址 == %@", savePath);

    _producerCancel = NO;
    
    /**
     导出配置，默认全部导出
     如果导出部分视频则需要配置 rangeStart 和 rangeDuration
     rangeStart ：导出起始时间
     rangeDuration ：导出视频长度
     */
    
    // 6S以下540P, 7P及以下的机型保持最高分辨率是中等，即720p，其它的保证原分辨率
    
    CGFloat scale = [UIDevice lsqDevicePlatform] <= TuDevicePlatform_iPhone7p ? ([UIDevice lsqDevicePlatform] < TuDevicePlatform_iPhone6s ? 0.5 : 0.67) : 1;
    
    TUPProducer_OutputConfig *config = [[TUPProducer_OutputConfig alloc] init];
    config.rangeStart = 0;
    config.rangeDuration = self.totalTime;
    config.watermark = [UIImage imageNamed:@"sample_watermark"];
    config.watermarkPosition = -1;
    config.scale = scale;

    self.producer = (TUPDynEvaDirectorProducer *)[self.evaDirector newProducer];
    self.producer.delegate = self;
    self.producer.savePath = [@"file://" stringByAppendingString:savePath];

    [self.producer setOutputConfig:config];
    [self.producer open];
    [self.producer start];
}


/**
*  生成临时文件路径
*
*  @return 文件路径
*/
- (NSString *) generateTempFile;
{
    NSString *path = [TuTSFileManager createDir:[TuTSFileManager pathInCacheWithDirPath:NSTemporaryDirectory() filePath:@""]];
    path = [NSString stringWithFormat:@"%@%f.mp4", path, [[NSDate date]timeIntervalSince1970]];
    
    unlink([path UTF8String]);
    
    return path;
}

// 暂停导出
- (void)stopEvaPlayer {
    if (_evaPlayer) {
        if (self.playerState == kPLAYING) {
            [_evaPlayer pause];
        }
        _evaSlider.value = 0.0;
        [_evaPlayer seekTo:0];
        [_evaPlayer previewFrame:0];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (MusicView *)musiView {
    if (!_musiView) {
        _musiView = [[MusicView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        [[UIApplication sharedApplication].keyWindow addSubview:_musiView];
    }
    return _musiView;
}

- (MPVolumeView *)volumeView
{
    if (!_volumeView) {
        _volumeView = [[MPVolumeView alloc] init];
        _volumeView.userInteractionEnabled = YES;
        [_volumeView sizeToFit];
        _volumeView.showsRouteButton = NO;
        for (UIView *view in _volumeView.subviews)
        {
            if ([view.class.description isEqualToString:@"MPVolumeSlider"])
            {
                self.volumeViewSlider = (UISlider *)view;
            }
        }
    }
    return _volumeView;
}




/**
 根据 videoSize 获取安全的size
 
 @param videoSize videoSize
 @return CGSize
 */
- (CGSize)safeVideoSize:(CGSize)videoSize
{
    /** 验证最小边界，如果大于1080降低分辨率 */
    CGFloat minSide = MIN(videoSize.width, videoSize.height);
    
    // 如果最小边大于 1080 则降低分辨率到1080
    if (minSide > lsqMaxOutputVideoSizeSide)
    {
        CGFloat scale =  lsqMaxOutputVideoSizeSide / minSide;
         return CGSizeMake(videoSize.width * scale, videoSize.height * scale);
    }
    
    return videoSize;
}

#pragma mark - TUPPlayerDelegate
- (void)onPlayerEvent:(TUPPlayerState)state withTimestamp:(NSInteger)ts
{
    self.playerState = state;

    //NSLog(@"当前时间 ===%ld", (long)ts);
    
//    if (state == kAUDIO_EOS)
//    {
//        [self.evaPlayer pause];
//        self.isStart = NO;
//    }
    
    if (self.isStart && ts != 0) {
        [self.evaPlayer pause];
        self.isStart = NO;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.playBtn.hidden = self.playerState == kPLAYING;

        NSInteger totalTime = [self.evaPlayer getDuration];
        self.lastProgress = [[NSString stringWithFormat:@"%.5f", ts * 1000.f / totalTime / 1000] floatValue];
//        NSLog(@"进度条 === %.5f", self.lastProgress);
        if (self.lastProgress != 0) {
            self.evaSlider.value = self.lastProgress;
            self.pauseTime = ts;
            
        }
        
//        self.totalTimelabel.text = [NSString stringWithFormat:@"总时长(TS) : %ld", totalTime];
//        self.currentPlaylabel.text = [NSString stringWithFormat:@"当前播放视频时间(TS) : %ld", self.pauseTime];
//        self.resetTimelabel.text = [NSString stringWithFormat:@"剩余时长 : %ld", totalTime - self.pauseTime];
        
        //NSLog(@"暂停时间=== %ld", self.pauseTime);
    });
}

#pragma mark - TUPProducerDelegate

- (void)onProducerEvent:(TUPProducerState)state withTimestamp:(NSInteger)ts
{
    if (_producerCancel || state == kDO_CANCEL) {

        return;
    }
    self.producerSate = state;
//    NSLog(@"视频时长 ===%ld", [self.evaPlayer getDuration]);
    NSLog(@"导出状态 === %ld", state);
    dispatch_async(dispatch_get_main_queue(), ^{
        
        float percent = ts * 1.f / self.totalTime;
        [TuPopupProgress showProgress:percent status:[NSString stringWithFormat:@"正在导出 %.0f%%",percent * 100]];
        
        //NSLog(@"导出进度 ==== %.2f", percent);
        if (self.producerSate == kEND) {
            NSString *videoPath = [self.producer.savePath componentsSeparatedByString:@"file://"].lastObject;
            UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }
    });
}


// 视频保存回调
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo
{

    if (error == nil) {
        [TuPopupProgress showSuccessWithStatus:@"导出完成"];
        //无论导出成功失败，删除Cache 目录中的临时文件
        if ([TuTSFileManager isExistFileAtPath:videoPath]) {
            [TuTSFileManager deletePath:videoPath];
        }

    } else {
        [TuPopupProgress showErrorWithStatus:@"导出失败"];
    }
    [self.evaPlayer seekTo:self.pauseTime];
    [self.evaPlayer previewFrame:self.pauseTime];
    [self.producer close];
    [self.evaDirector resetProducer];

}


@end
