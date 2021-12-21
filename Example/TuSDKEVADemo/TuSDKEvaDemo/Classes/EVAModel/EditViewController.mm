//
//  EditViewController.m
//  TuSDKEvaDemo
//
//  Created by tutu on 2019/6/26.
//  Copyright © 2019 TuSdk. All rights reserved.
//

#import "EditViewController.h"
#import "EditCollectionViewCell.h"
#import "MusicView.h"
#import "VideoEditViewController.h"
#import "ImageEditViewController.h"
#import "MultiAssetPicker.h"

#import <TuSDKPulseEva/TUPEvaPlayer.h>
#import <TuSDKPulseEva/TUPEvaModel.h>
#import <TuSDKPulseEva/TUPEvaProducer.h>
#import <TuSDKPulse/TUPProducer.h>
#import "TuEvaAsset.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MediaPlayer/MPVolumeView.h>
#import <TuSDKPulseEva/TUPEvaDirector.h>
#import <TuSDKPulseEva/TUPEvaProducer.h>
#import "TuPopupProgress.h"

#import "TAEExportManager.h"
#import "TAEModelMediator.h"

//#import <GPUUtilization/GPUUtilization.h>

typedef NS_ENUM(NSUInteger, TuSelectFilePathState) {
    TuSelectFilePathMusicState,
    TuSelectFilePathImageState,
    TuSelectFilePathVideoState
};

/** 视频支持的最大边界 */
static const NSUInteger lsqMaxOutputVideoSizeSide = 1080;

@interface EditViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, MultiPickerDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate, TUPPlayerDelegate, TUPProducerDelegate>

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
@property (weak, nonatomic) IBOutlet UIButton *resetBtn;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textFiledBottom;
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
 已选择的资源类型
 */
@property (nonatomic, assign) TuSelectFilePathState selectPathState;

/**
 orgResources
 */
@property (nonatomic, strong) NSMutableArray *orgResources;
/**
 changeState
 */
@property (nonatomic, strong) NSMutableArray *statusResources;

/**
 eva 播放器
 */
@property (nonatomic, strong) TUPEvaDirectorPlayer *evaPlayer;
@property (nonatomic, strong) TUPEvaDirector *evaDirector;

@property (nonatomic, strong) NSMutableArray *imageResources;
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

@property (nonatomic, strong) TUPEvaReplaceConfig_ImageOrVideo *evaConfig;
/**
 视频config
 */
@property (nonatomic, strong) TUPEvaReplaceConfig_ImageOrVideo *videoConfig;

/**存储器*/
//@property (nonatomic, strong) TUPEvaProducer *producer;
@property (nonatomic, strong) TUPEvaDirectorProducer *producer;
/**是否重置*/
@property (nonatomic, assign) BOOL isReset;

/**音量视图*/
@property (nonatomic, strong) MPVolumeView *volumeView;
@property (nonatomic, strong) UISlider *volumeViewSlider;

/**eva总时长*/
@property (nonatomic, assign) NSInteger totalTime;

@property (nonatomic, assign) BOOL isStart;

@property (nonatomic, strong) TAEModelMediator *mediator;

@end


@implementation EditViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self commonInit];
    
    self.isStart = YES;
    _index = 999;
    // 添加后台、前台切换的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackFromFront) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterFrontFromBack) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    self.producerSate = kDO_START;
    
//    {
//
//
//        //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            UILabel * gpuLabel = [[UILabel alloc] init];
//            gpuLabel.backgroundColor = [UIColor whiteColor];
//            gpuLabel.font = [UIFont fontWithName:@"Courier" size:14];
//            gpuLabel.text = @"GPU:  0%";
//            gpuLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
//            [gpuLabel sizeToFit];
//
//            CGRect rect = gpuLabel.frame;
//            rect.origin.x = 10.f;
//            rect.origin.y = 200;//application.statusBarFrame.size.height;
//            gpuLabel.frame = rect;
//            [self.view addSubview:gpuLabel];
//
//            NSTimer *timer = [NSTimer timerWithTimeInterval:0.5
//                                                    repeats:YES
//                                                      block:^(NSTimer * timer) {
//                                                          [GPUUtilization fetchCurrentUtilization:^(GPUUtilization *current) {
//                                                              gpuLabel.text = [NSString stringWithFormat:@"GPU: %2zd%%", current.deviceUtilization];
//                                                          }];
//                                                      }];
//            [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
//        //});
//    }
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

    //清除临时图片、视频文件
    if (self.mediator && !self.mediator.isSilenceExport) {
        [self.mediator removeTempFilePath];
        self.mediator = nil;
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
    
    [self resetOrgResoures];
    
    [self.evaSlider setThumbImage:[UIImage imageNamed:@"circle_s_ic"] forState:UIControlStateNormal];
    self.evaSlider.value = 0.0;
    
    self.changeMusicBtn.layer.cornerRadius = 4;
    self.changeMusicBtn.layer.masksToBounds = YES;
    self.resetBtn.layer.cornerRadius = 4;
    self.resetBtn.layer.masksToBounds = YES;
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"EditCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"EditCollectionViewCell"];
    [self.collectionView reloadData];
    

    
    // 监听键盘
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    // evaplayer加载
    if (_evaPlayer == nil) {

        
        TUPEvaModel *model = [[TUPEvaModel alloc] init:self.evaPath];

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
            
           
            [self setupPlayer];
            
        
        
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
  
- (void)setupPlayer
{
    TUPEvaModel *model = [[TUPEvaModel alloc] init:self.evaPath];
    self.displayView = [[TUPDisplayView alloc] init];
    [self.preview addSubview:self.displayView];
    [self.displayView setup:nil];
    
    self.displayView.frame = CGRectMake(0, 0, lsqScreenWidth, self.previewHeight.constant);
    
    self.evaDirector = [[TUPEvaDirector alloc] init];
    [self.evaDirector openModel:model];
    
    self.evaPlayer = (TUPEvaDirectorPlayer *)[self.evaDirector newPlayer];
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
    return _orgResources.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    EditCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EditCollectionViewCell" forIndexPath:indexPath];
    id model = _orgResources[indexPath.row];
    id item = self.mediator.resource[indexPath.row];
    if ([item isKindOfClass:[TAEModelTextItem class]])
    {
        //文本
        cell.backgroundImage.hidden = YES;
        cell.typeText.hidden = YES;
        cell.text.hidden = NO;
        TAEModelTextItem *textItem = (TAEModelTextItem *)item;
        if (textItem.isReplace) {
            // 替换的
            cell.text.textColor = [UIColor whiteColor];
        } else {
            // 没有替换的
            cell.text.textColor = [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1];
        }
        cell.text.text = textItem.text;
    }
    if ([model isKindOfClass:[TextReplaceItem class]]) {
        
    } else {
        // 图片，视频
        cell.backgroundImage.hidden = NO;
        cell.typeText.hidden = NO;
        cell.text.hidden = YES;
        VideoReplaceItem *origin = model;
        if (origin.type == kIMAGE_VIDEO) {
            cell.typeText.text = @"图片/视频 ";
        } else if (origin.type == kIMAGE_ONLY) {
            cell.typeText.text = @" 图片 ";
        } else if (origin.type == kVIDEO_ONLY) {
            cell.typeText.text = @" 视频 ";
        } else if (origin.type == kAUDIO) {
            cell.typeText.text = @" 音频 ";
        } else if (origin.type == kMASK) {
            cell.typeText.text = @"蒙版视频 ";
        } else {

        }
        // 解决加载大图卡顿的问题
        cell.tag = indexPath.row;
        CGRect imageBounds = cell.backgroundImage.bounds;
        NSString *itemStatus = self.statusResources[indexPath.row];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            
            TuEvaAsset *asset = [[TuEvaAsset alloc] initWithAssetPath:origin.resPath];
            if (itemStatus.integerValue == 1) {
                
                // video
                UIImage *image = [self getVideoPreViewImage:[NSURL URLWithString:origin.resPath] itemFlag:indexPath.row isFirst:NO];
                if (self->_index == 999) {
                    [self.imageResources replaceObjectAtIndex:indexPath.item withObject:image];
                }
                
                [self setImage:image forCell:cell inBounds:imageBounds atIndex:indexPath.row];
                
            } else {
                [asset requestImageWithResultHandler:^(UIImage * _Nullable result) {
                    if (result != nil)
                    {
                        UIImage *image = result;
                        if (self->_index == 999) {
                            [self.imageResources replaceObjectAtIndex:indexPath.item withObject:image];
                        }
                        [self setImage:image forCell:cell inBounds:imageBounds atIndex:indexPath.row];
                    }
                    else
                    {
                        NSString *filePath = [@"file://" stringByAppendingString:origin.resPath];
                        UIImage *image = [self getVideoPreViewImage:[NSURL URLWithString:filePath] itemFlag:indexPath.row isFirst:YES];
                        [self setImage:image forCell:cell inBounds:imageBounds atIndex:indexPath.row];
                    }
                }];
            }
        });
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    _index = indexPath.row;
    
    [self stopEvaPlayer];
    id model = _orgResources[indexPath.row];
    
    if ([model isKindOfClass:[TextReplaceItem class]]) {
        // 去编辑文本
        TextReplaceItem *textAsset = (TextReplaceItem *)model;
        _textField.text = textAsset.text;
        [_textField becomeFirstResponder];
        
        
    } else {
        // 去编辑图片、视频
        MultiAssetPicker *picker = [MultiAssetPicker picker];
        picker.disableMultipleSelection = YES;
        VideoReplaceItem *origin = (VideoReplaceItem*)model;
        if (origin.type == kIMAGE_VIDEO) {
            picker.fetchMediaTypes = @[@(PHAssetMediaTypeImage),@(PHAssetMediaTypeVideo)];
        } else if (origin.type == kVIDEO_ONLY) {
            picker.fetchMediaTypes = @[@(PHAssetMediaTypeVideo)];
        } else if (origin.type == kIMAGE_ONLY) {
            picker.fetchMediaTypes = @[@(PHAssetMediaTypeImage)];
        }
        picker.navigationItem.title = @"素材选择";
        picker.delegate = self;
        picker.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
        [self showViewController:picker sender:nil];
    }
}

- (void)setImage:(UIImage *)image forCell:(EditCollectionViewCell *)cell inBounds:(CGRect)imageBounds atIndex:(NSInteger)index {
    
    //redraw image using device context
    CGSize size = image.size;
    if (image.size.width > image.size.height) {
        // 宽图片
        size = CGSizeMake(imageBounds.size.width, imageBounds.size.width * (image.size.height/image.size.width));
    } else {
        // 高图片
        size = CGSizeMake(imageBounds.size.height * (image.size.width/image.size.height), imageBounds.size.height);
    }
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //set image on main thread, but only if index still matches up
    dispatch_async(dispatch_get_main_queue(), ^{
        if (index == cell.tag) {
            cell.backgroundImage.image = image;
            if (self->_index != 999 && self.imageResources.count == self.orgResources.count) {
                [self.imageResources replaceObjectAtIndex:self->_index withObject:image];
            }
        }
    });
}

// 获取视频第一帧
- (UIImage*)getVideoPreViewImage:(NSURL *)path itemFlag:(NSInteger)itemFlag isFirst:(BOOL)isFirst
{
    if (!isFirst)
    {
        if (itemFlag != _index && self.imageResources.count == self.orgResources.count) {
            return self.imageResources[itemFlag];
        }
    }
        
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:path options:nil];
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    assetGen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    
    CGSize outPutSize = CGSizeMake(720, 1280);
    
    if (self.videoConfig == nil)
    {
        videoImage = [videoImage lsqImageCorpWithPrecentRect:CGRectMake(0, 0, 1, 1) outputSize:outPutSize];
    }
    else
    {
        videoImage = [videoImage lsqImageCorpWithPrecentRect:self.videoConfig.crop outputSize:outPutSize];
    }
    
    if (videoImage != nil)
    {
        if (self.imageResources.count != 0 && self.imageResources.count == self.orgResources.count) {
            
            if (isFirst)
            {
                [self.imageResources replaceObjectAtIndex:itemFlag withObject:videoImage];

            }
            else
            {
                [self.imageResources replaceObjectAtIndex:_index withObject:videoImage];

            }
        }
    }
    
    return videoImage;
}

#pragma mark - MultiPickerDelegate
- (void)picker:(MultiAssetPicker *)picker didTapItemWithIndexPath:(NSIndexPath *)indexPath phAsset:(PHAsset *)phAsset {
    
    VideoReplaceItem *asset = _orgResources[_index];
    __weak typeof(asset)weakAsset = asset;
    __weak typeof(self)weakSelf = self;
    
    if (asset.isVideo)
    {
        self.selectPathState = TuSelectFilePathVideoState;
    }
    else
    {
        self.selectPathState = TuSelectFilePathImageState;
    }
    
    [self requestAVAsset:phAsset completion:^(PHAsset *inputPhAsset, NSObject *returnValue) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            weakSelf.isReset = YES;
            if (inputPhAsset.mediaType == PHAssetMediaTypeVideo) {

                // 去进行视频编辑
                
                VideoEditViewController *edit = [[VideoEditViewController alloc] initWithNibName:nil bundle:nil];
                AVURLAsset *assets = (AVURLAsset *)returnValue;
                NSLog(@"视频输出路径 === %@", assets.URL);
                
                edit.filePath = [assets.URL.absoluteString componentsSeparatedByString:@"file://"].lastObject;
                
                edit.inputAssets = @[(AVAsset *)returnValue];
                edit.durationTime = weakAsset.endTime - weakAsset.startTime;
                edit.cutSize = weakAsset.size;

                [edit setEditCompleted:^(TUPEvaReplaceConfig_ImageOrVideo * _Nonnull config, NSString *savePath) {
                    weakSelf.videoConfig = config;
                    weakSelf.selectedPath = [savePath componentsSeparatedByString:@"file://"].lastObject;
                    [self.mediator addTempFilePath:weakSelf.selectedPath];
                    [weakSelf.navigationController popToViewController:weakSelf animated:YES];
                    [weakSelf.statusResources replaceObjectAtIndex:self->_index withObject:@"1"];
                    weakAsset.resPath = assets.URL.absoluteString;
                    [weakSelf.collectionView reloadData];
                    [weakSelf replaceEvaTemplate];
                }];
                [picker showViewController:edit sender:nil];
            }
            if (inputPhAsset.mediaType == PHAssetMediaTypeImage) {
                // 去图片编辑
                ImageEditViewController *edit = [[ImageEditViewController alloc] initWithNibName:nil bundle:nil];
                edit.inputImage = (UIImage *)returnValue;
                edit.index = self->_index;
                edit.cutSize = weakAsset.size;
                [edit setEditCompleted:^(NSURL * _Nonnull outputUrl) {
                    [weakSelf.navigationController popToViewController:weakSelf animated:YES];
                    [self.mediator addTempFilePath:outputUrl.path];
                    [weakSelf.statusResources replaceObjectAtIndex:self->_index withObject:@"0"];
                    weakSelf.selectedPath = [outputUrl.absoluteString componentsSeparatedByString:@"file://"].lastObject;
                    weakAsset.resPath = weakSelf.selectedPath;
                    [weakSelf.collectionView reloadData];
                    [weakSelf replaceEvaTemplate];
                }];
                [picker showViewController:edit sender:nil];
            }
        });
    }];
}

#pragma mark - actions

// 音量改变
- (IBAction)volmValueChanged:(UISlider *)sender {
    self.evaConfig.audioMixWeight = sender.value;
    
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
    
    TUPEvaModel *model = [[TUPEvaModel alloc] init:_evaPath];
    if (_displayView == nil || model == nil || self.mediator.audioItem == nil) {
        //[[TuSDK shared].messageHub showToast:@"此资源不支持替换背景音乐"];
        return;
    }
    
    [self stopEvaPlayer];
    self.selectPathState = TuSelectFilePathMusicState;
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
        self->_isReset = YES;
    }];
}


/**
 一键重置，将资源重置回源资源
 */
- (IBAction)reset:(UIButton *)sender {

    if (!self.isReset) return;
    
    [self stopEvaPlayer];
    _index = 999;

    [self.evaPlayer close];
    [self.displayView teardown];
    [self.evaDirector close];
    
    [self.imageResources removeAllObjects];
    [_orgResources removeAllObjects];
    [self.statusResources removeAllObjects];
        
    if (self.mediator) {
        self.mediator = nil;
    }
    
    [self resetOrgResoures];
    
    _selectedPath = nil;
    [self.collectionView reloadData];
    
    //重载播放器
    [self setupPlayer];

    self.isReset = NO;
    
    [self.evaPlayer seekTo:0];
    [self.evaPlayer previewFrame:0];
}


// 替换资源后，播放器重载资源
- (void)replaceEvaTemplate {

//    [self stopEvaPlayer];
    
    if (self.evaPlayer) {
        [self.evaPlayer pause];
    }
    
    //替换音乐
    if (self.selectedPath && self.selectPathState  == TuSelectFilePathMusicState) {
        TUPEvaReplaceConfig_Audio *audioConfig = [[TUPEvaReplaceConfig_Audio alloc] init];
        audioConfig.start = 0;
        audioConfig.duration = [self.evaPlayer getDuration];
        audioConfig.audioMixWeight = self.volmSlider.value;
        
        //资源替换
        self.mediator.audioItem.isReplace = YES;
        self.mediator.audioItem.audioMixWeight = self.volmSlider.value;
        self.mediator.audioItem.resPath = self.selectedPath;
        [self.evaDirector updateAudio:self.mediator.audioItem.Id withPath:self.mediator.audioItem.resPath andConfig:audioConfig];
    }
    //替换图片
    if (self.selectedPath && self.selectPathState == TuSelectFilePathImageState) {
        //选中的图片资源
        VideoReplaceItem *asset = _orgResources[_index];
        TUPEvaReplaceConfig_ImageOrVideo *imageConfig = [[TUPEvaReplaceConfig_ImageOrVideo alloc] init];
        imageConfig.start = self.videoConfig.start;
        imageConfig.duration = self.videoConfig.duration;
        imageConfig.audioMixWeight = self.volmSlider.value;
        
        [self.evaDirector updateImage:asset.Id withPath:self.selectedPath andConfig:imageConfig];
        
        TAEModelVideoItem *item = self.mediator.resource[_index];
        item.Id = item.Id;
        item.type = TAEModelAssetType_Image;
        item.isReplace = YES;
        item.resPath = self.selectedPath;
        item.isVideo = NO;
        item.audioMixWeight = self.volmSlider.value;
        [self.mediator replaceVideoItem:item withIndex:_index];
        
    }
    //替换视频
    if (self.selectedPath && self.selectPathState == TuSelectFilePathVideoState) {
        //选中的视频资源,根据isVideo字段判断相对应涂层
        VideoReplaceItem *asset = _orgResources[_index];

        TAEModelVideoItem *item = self.mediator.resource[_index];
        item.Id = item.Id;
        item.isReplace = YES;
        item.resPath = self.selectedPath;
        item.isVideo = asset.isVideo;
        item.type = TAEModelAssetType_Video;
        item.crop = self.videoConfig.crop;
        item.start = self.videoConfig.start;
        item.duration = self.videoConfig.duration;
        item.maxSide = self.videoConfig.maxSide;
        
        if (asset.isVideo) {
        
            [self.evaDirector updateVideo:asset.Id withPath:self.selectedPath andConfig:self.videoConfig];
        } else {

            [self.evaDirector updateImage:asset.Id withPath:self.selectedPath andConfig:self.videoConfig];
            
        }
        [self.mediator replaceVideoItem:item withIndex:_index];

    }
    
    [self.evaPlayer previewFrame:self.pauseTime];
    self.evaSlider.value = self.pauseTime / [self.evaPlayer getDuration];
    
    //选择素材后不需要跳到起始帧
//    dispatch_async(dispatch_get_global_queue(DISPATCH_TARGET_QUEUE_DEFAULT, 0), ^{
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//
//            [self.evaPlayer seekTo:0];
//            [self.evaPlayer previewFrame:0];
//            self.evaSlider.value = self.lastProgress = 0.0;
//        });
//    });
}


// 重置源资源
- (void)resetOrgResoures {
    // 资源排序
    TUPEvaModel *model = [[TUPEvaModel alloc] init:_evaPath];
    
    [self.orgResources addObjectsFromArray:[model listReplaceableImageAssets]];
    [self.orgResources addObjectsFromArray:[model listReplaceableVideoAssets]];
    [self.orgResources addObjectsFromArray:[model listReplaceableTextAssets]];
    [self.imageResources addObjectsFromArray:self.orgResources];


    // 用资源显示的开始帧进行排序
    [self.orgResources sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSInteger start1 = 0.0, start2 = 0.0;
        if ([obj1 isKindOfClass:[VideoReplaceItem class]]) {
            VideoReplaceItem *imageItem = (VideoReplaceItem *)obj1;
            start1 = imageItem.startTime;
        } else if ([obj1 isKindOfClass:[TextReplaceItem class]]) {
            TextReplaceItem *textItem = (TextReplaceItem *)obj1;
            start1 = textItem.startTime;
        }
        if ([obj2 isKindOfClass:[VideoReplaceItem class]]) {
            VideoReplaceItem *imageItem = (VideoReplaceItem *)obj2;
            start2 = imageItem.startTime;
        } else if ([obj2 isKindOfClass:[TextReplaceItem class]]) {
            TextReplaceItem *textItem = (TextReplaceItem *)obj2;
            start2 = textItem.startTime;
        }
        return [[NSNumber numberWithInteger:start1] compare:[NSNumber numberWithInteger:start2]];
    }];
    
    for (NSInteger itemTag = 0; itemTag < self.orgResources.count; itemTag++) {
        [self.statusResources addObject:@"0"];
    }
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.mediator = [[TAEModelMediator alloc] initWithEvaPath:self.evaPath];
//        [self.mediator loadResource];
//    });
    
    self.mediator = [[TAEModelMediator alloc] initWithEvaPath:self.evaPath];
    [self.mediator loadResource];
}


// 点击视频视图
- (IBAction)tapPreview:(UITapGestureRecognizer *)sender {
    // 先处理键盘
    if ([_textField isFirstResponder]) {
        [_textField resignFirstResponder];
        return;
    }
    
    if (self.playerState == kPLAYING) {
        [self.evaPlayer pause];

    } else {
        if (self.evaSlider.value >= 0.99) {
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
    UIAlertAction *receptionAction = [UIAlertAction actionWithTitle:@"前台导出" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
       
        [self receptionSaveAction];
        
    }];
    UIAlertAction *silenceAction = [UIAlertAction actionWithTitle:@"静默导出" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self silenceSaveAction];
        
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [saveController addAction:receptionAction];
    [saveController addAction:silenceAction];
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

    self.producer = (TUPEvaDirectorProducer *)[self.evaDirector newProducer];
    self.producer.delegate = self;
    self.producer.savePath = [@"file://" stringByAppendingString:savePath];

    [self.producer setOutputConfig:config];
    [self.producer open];
    [self.producer start];
}
/**
 * 静默导出
 *
 */
- (void)silenceSaveAction
{
    /**
     导出配置，默认全部导出
     如果导出部分视频则需要配置 rangeStart 和 rangeDuration
     rangeStart ：导出起始时间
     rangeDuration ：导出视频长度
     */
    
    // 6S以下540P, 7P及以下的机型保持最高分辨率是中等，即720p，其它的保证原分辨率
    
    CGFloat scale = [UIDevice lsqDevicePlatform] <= TuDevicePlatform_iPhone7p ? ([UIDevice lsqDevicePlatform] < TuDevicePlatform_iPhone6s ? 0.5 : 0.67) : 1;
    
    dispatch_queue_t export_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(export_queue, ^{
        TAEExportOption *option = [[TAEExportOption alloc] init];
        option.rangeStart = 0;
        option.rangeDuration = self.totalTime;
        option.watermark = [UIImage imageNamed:@"sample_watermark"];
        option.watermarkPosition = -1;
        option.scale = scale;
        option.savePath = [self generateTempFile];
        option.evaPath = self.evaPath;
        
        [TAEExportManager shareManager].mediator = self.mediator;
        [TAEExportManager shareManager].option = option;
        [[TAEExportManager shareManager] startExport];
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


#pragma mark - textEdit
- (void)keyboardWillHide:(NSNotification *)note {
    _textFiledBottom.constant = -64.0;
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillShow:(NSNotification *)note {
    NSDictionary *userInfo = [note userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    _textFiledBottom.constant = keyboardRect.size.height;
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.text.length <= 0) {
        //[[TuSDK shared].messageHub showToast:@"输入的内容不能为空"];
        return NO;
    }
    
    self.isReset = YES;
    
    self.selectPathState = TuSelectFilePathMusicState;

    TextReplaceItem *textAsset = _orgResources[_index];
    [self.evaDirector updateText:textAsset.Id withText:textField.text];
    
    //替换文字资源
    TAEModelTextItem *textItem = self.mediator.resource[_index];
    textItem.isReplace = YES;
    textItem.text = textField.text;
    [self.mediator replaceTextItem:textItem withIndex:_index];

    textAsset.text = textField.text;
    [self.collectionView reloadData];
    
    [self replaceEvaTemplate];
    [textField resignFirstResponder];
    
    return YES;
}


#pragma mark - load media
/**
 请求 PHAsset
 
 @param phAsset PHAsset 文件对象
 @param completion 完成后的操作
 */
- (void)requestAVAsset:(PHAsset *)phAsset completion:(void (^)(PHAsset *inputPhAsset, NSObject *returnValue))completion {
    
    if (phAsset.mediaType == PHAssetMediaTypeImage) {
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.networkAccessAllowed = YES;
        options.synchronous = YES;
        // 配置请求
        options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            if (progress == 1.0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [TuPopupProgress dismiss];
                });
            } else {
                [TuPopupProgress showProgress:progress status:@"iCloud 同步中"];
            }
        };
        
        CGSize outputSize = [self safeVideoSize:CGSizeMake(phAsset.pixelWidth, phAsset.pixelWidth)];
        
        [[PHImageManager defaultManager] requestImageForAsset:phAsset targetSize:outputSize contentMode:PHImageContentModeDefault options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
            if (completion) completion(phAsset, result);
        }];
        
    } else {
        
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.networkAccessAllowed = YES;
        // 配置请求
        options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            
            if (progress == 1.0) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [TuPopupProgress dismiss];
                });
            } else {
                [TuPopupProgress showProgress:progress status:@"iCloud 同步中"];
            }
            
        };
        
        [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
            
            if (completion) completion(phAsset, asset);
        }];
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

- (NSMutableArray *)statusResources
{
    if (!_statusResources) {
        _statusResources = [NSMutableArray array];
    }
    return _statusResources;
}

- (NSMutableArray *)orgResources
{
    if (!_orgResources) {
        _orgResources = [NSMutableArray array];
    }
    return _orgResources;;
}

- (NSMutableArray *)imageResources
{
    if (!_imageResources) {
        _imageResources = [NSMutableArray array];
    }
    return _imageResources;
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
        //NSLog(@"进度条 === %.5f", self.lastProgress);
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

    [self.mediator addTempFilePath:videoPath];
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

#pragma mark - 时间UI
//- (void)creatShowTimeView
//{
//    _timeView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
//    _timeView.backgroundColor = UIColor.blackColor;
//    [self.view addSubview:_timeView];
//
//    _totalTimelabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 190, 20)];
//    _totalTimelabel.textColor = UIColor.redColor;
//    _totalTimelabel.font = [UIFont systemFontOfSize:12];
//    [_timeView addSubview:_totalTimelabel];
//
//    _currentPlaylabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 40, 190, 20)];
//    _currentPlaylabel.textColor = UIColor.redColor;
//    _currentPlaylabel.font = [UIFont systemFontOfSize:12];
//    [_timeView addSubview:_currentPlaylabel];
//
//    _resetTimelabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 70, 190, 20)];
//    _resetTimelabel.textColor = UIColor.redColor;
//    _resetTimelabel.font = [UIFont systemFontOfSize:12];
//    [_timeView addSubview:_resetTimelabel];
//}

@end
