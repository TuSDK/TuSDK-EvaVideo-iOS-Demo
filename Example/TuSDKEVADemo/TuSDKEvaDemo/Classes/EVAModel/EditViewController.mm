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

#import "TuEvaAsset.h"
#import <MediaPlayer/MediaPlayer.h>
#import <MediaPlayer/MPVolumeView.h>

#import "TuPopupProgress.h"
#import "TTItemReplaceView.h"
#import "TAEExportManager.h"
#import "TTDirectorMediator.h"
#import <Masonry/Masonry.h>
//#import <GPUUtilization/GPUUtilization.h>

typedef NS_ENUM(NSUInteger, TuSelectFilePathState) {
    TuSelectFilePathMusicState,
    TuSelectFilePathImageState,
    TuSelectFilePathVideoState
};

/** 视频支持的最大边界 */
static const NSUInteger lsqMaxOutputVideoSizeSide = 1080;

@interface EditViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, MultiPickerDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate , TTItemReplaceViewDelegate, TTDirectorMediatorDelegate>

{
    BOOL _producerCancel;
    //是否允许select标记
    BOOL _canSelect;
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

/**当前播放时长*/
@property (nonatomic, strong) UILabel *currentTimelabel;
/**总时长*/
@property (nonatomic, strong) UILabel *totalTimelabel;

/**
 已经选择的路径
 */
@property (nonatomic, strong) NSString *selectedPath;

/**
 已选择的资源类型
 */
@property (nonatomic, assign) TuSelectFilePathState selectPathState;

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

/**音量视图*/
@property (nonatomic, strong) MPVolumeView *volumeView;
@property (nonatomic, strong) UISlider *volumeViewSlider;

/**eva总时长*/
@property (nonatomic, assign) NSInteger totalTime;

//@property (nonatomic, assign) BOOL isStart;
/// 选中的文字模块
@property (nonatomic, strong) TAEModelTextItem *selectTextItem;
/// 选中的视频图片模块
@property (nonatomic, strong) TAEModelVideoItem *selectVideoItem;
/// 选中的index
@property (nonatomic, assign) NSInteger selectIndex;
/// 操作视图
@property (nonatomic, strong) TTItemReplaceView *itemReplaceView;
/// eva模型中间件
@property (nonatomic, strong) TTDirectorMediator *directorMediator;
/// displayViewRect
@property (nonatomic, assign) CGRect displayRect;

@end


@implementation EditViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.selectIndex = 0;
    
    [self commonInit];
    
//    self.isStart = YES;

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
    
    if (self.directorMediator) {
        [self.directorMediator destory];
    }

    //清除临时图片、视频文件
    if (self.mediator && !self.mediator.isSilenceExport) {
        self.mediator = nil;
    }
    
    // 希望可以及时回收FBO
    NSLog(@"TUEVA:EditViewController ------ dealloc");
    
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
    

    
    // 监听键盘
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    
    self.directorMediator = [[TTDirectorMediator alloc] init];
    self.directorMediator.delegate = self;
    [self.directorMediator setup:self.mediator.filePath];
    

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
    CGSize videoSize = [self.directorMediator modelSize];
    CGFloat vWidth  = videoSize.width;
    CGFloat vHeight = videoSize.height;
    
    self.displayRect = CGRectZero;
    
    CGFloat sliderWidth = sWidth;
    if (sWidth/sHeight > vWidth/vHeight) {
        // 视频偏宽
        if (sWidth * (vHeight/vWidth) > sHeight) {
            self.previewHeight.constant = sHeight;
            
            sliderWidth = sHeight * (vWidth/vHeight);
            
        } else {
            self.previewHeight.constant = sWidth * (vHeight/vWidth);
        }
//        self.previewSuperView.frame = CGRectMake(0, 0, CGRectGetWidth(self.preview.frame), self.previewHeight.constant);
//        self.displayRect = CGRectMake(0, 0, CGRectGetWidth(self.preview.frame), self.previewHeight.constant);
        self.previewSuperHeight.constant = self.previewHeight.constant + 10;
        
    } else {
        if (sHeight * (vWidth/vHeight) > sWidth) {
            self.previewHeight.constant = sWidth * (vHeight/vWidth);
        } else {
            self.previewHeight.constant = sHeight;
            sliderWidth= sHeight * (vWidth/vHeight);
        }
//        self.previewSuperView.frame = CGRectMake(0, (sHeight - self.previewHeight.constant) / 2, CGRectGetWidth(self.preview.frame), self.previewHeight.constant);
//        self.displayRect = CGRectMake(0, (sHeight - self.previewHeight.constant) / 2, CGRectGetWidth(self.preview.frame), self.previewHeight.constant);
    }
    self.displayRect = CGRectMake(0, 0, CGRectGetWidth(self.preview.frame), self.previewHeight.constant);
    
    
    
    [self setupPlayer];

    [self.view layoutIfNeeded];
    
//    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
//    self.volmSlider.value = audioSession.outputVolume;
//    NSLog(@"TUEVA::系统媒体音量 === %.2f", audioSession.outputVolume);
    
    //系统音量监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(volumeClicked:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    //        //创建时长视图
    //        [self creatShowTimeView];
    [self creatTimeView];
}

/**
 * 播放器设置
 */
- (void)setupPlayer
{
    [self.directorMediator setupView:self.preview rect:self.displayRect];
    self.totalTime = [self.directorMediator getDuration];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //如果素材选择页面存在替换，则需要替换
        for (id item in self.mediator.resource) {
            if ([item isKindOfClass:[TAEModelVideoItem class]]) {
                TAEModelVideoItem *videoItem = (TAEModelVideoItem *)item;
                if (videoItem.isReplace) {
                    
                    videoItem.audioMixWeight = self.volmSlider.value;
                    [self.directorMediator updateVideoOrImage:videoItem];
                }
            }
            TAEModelItem *modelItem = (TAEModelItem *)item;
            modelItem.isSelected = NO;
        }
        [self.directorMediator seekTo:0];
        [self.directorMediator previewFrame:0];
    });
    
    //首次进入编辑页时，默认选中第一个坑位
    for (int index = 0; index < self.mediator.resource.count; index++) {
        TAEModelItem *item = self.mediator.resource[index];
        item.isSelected = index == 0 ? YES : NO;
    }
}

#pragma mark - voice change
/**
 * 系统音量监听
 */
- (void)volumeClicked:(NSNotification *)noti
{
    NSDictionary *userInfo = noti.userInfo;
    float volume = [userInfo[@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    self.volmSlider.value = volume;
}

/**
 * 系统音量变化
 */
- (void)volumeValueChange:(UISlider *)sender
{
    self.volumeViewSlider.value = sender.value;
    NSLog(@"TUEVA::音量变化===%.2f", sender.value);
}

// 音量改变
- (IBAction)volmValueChanged:(UISlider *)sender {
    self.volumeViewSlider.value = sender.value;
}

#pragma mark - setter getter
- (void)setMediator:(TAEModelMediator *)mediator
{
    _mediator = mediator;
}

#pragma mark - back & front
- (void)enterBackFromFront {
    
    if (self.playerState == kPLAYING) {
        [self.directorMediator pause];
    }
    if (self.producerSate == kWRITING) {
        
        self.producerSate = kDO_CANCEL;
        //取消 - 关闭 - 重置
        [self.directorMediator cancelProducer];
        [self.directorMediator closeProducer];
        [self.directorMediator resetProducer];
        [TuPopupProgress dismiss];
        _producerCancel = YES;
    }    
}


- (void)enterFrontFromBack {
    
    //重新创建
    [self.directorMediator previewFrame:self.pauseTime];
    [self.directorMediator seekTo:self.pauseTime];
}



#pragma mark - UICollectionDatasouce, UICollectionDelegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.mediator.resource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    EditCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EditCollectionViewCell" forIndexPath:indexPath];
    id item = self.mediator.resource[indexPath.item];
    cell.item = item;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    //额外添加的间隔时间
    NSInteger extraDuration = 300;
    if (self.playerState == kPLAYING) {
        [self.directorMediator pause];
    }
    
    id item = self.mediator.resource[indexPath.item];
    if ([item isKindOfClass:[TAEModelTextItem class]]) {
        TAEModelTextItem *textItem = (TAEModelTextItem *)item;
        _selectTextItem = textItem;
        _selectVideoItem = nil;
    }
    if ([item isKindOfClass:[TAEModelVideoItem class]]) {
        TAEModelVideoItem *videoItem = (TAEModelVideoItem *)item;
        _selectTextItem = nil;
        _selectVideoItem = videoItem;
    }
    
    //判断当前item与点选是否一致
    if (_selectIndex != indexPath.item) {
        [self.itemReplaceView removeFromSuperview];
        self.itemReplaceView = nil;
        for (TAEModelItem *item in self.mediator.resource) {
            item.isSelected = NO;
        }
        
        //选中了文字坑位
        if (!_selectVideoItem && _selectTextItem) {
            _selectTextItem.isSelected = YES;
            if (extraDuration > _selectTextItem.duration / 2) {
                extraDuration = _selectTextItem.duration / 2;
            }
            
            [self.directorMediator seekTo:_selectTextItem.startTime + extraDuration];
            [self.directorMediator previewFrame:_selectTextItem.startTime + extraDuration];
        }
        
        //选中了视频图片坑位
        if (_selectVideoItem && !_selectTextItem) {
            _selectVideoItem.isSelected = YES;
            if (extraDuration > _selectVideoItem.duration / 2) {
                extraDuration = _selectVideoItem.duration / 2;
            }
            
            [self.directorMediator seekTo:_selectVideoItem.startTime + extraDuration];
            [self.directorMediator previewFrame:_selectVideoItem.startTime + extraDuration];
        }
        
//        id item = self.mediator.resource[indexPath.item];
//        if ([item isKindOfClass:[TAEModelTextItem class]]) {
//            TAEModelTextItem *textItem = (TAEModelTextItem *)item;
//            _selectTextItem = textItem;
//            _selectVideoItem = nil;
//            textItem.isSelected = YES;
//
//            if (extraDuration > textItem.duration / 2) {
//                extraDuration = textItem.duration / 2;
//            }
//
//            [self.directorMediator seekTo:textItem.startTime + extraDuration];
//            [self.directorMediator previewFrame:textItem.startTime + extraDuration];
//        }
//        if ([item isKindOfClass:[TAEModelVideoItem class]]) {
//            TAEModelVideoItem *videoItem = (TAEModelVideoItem *)item;
//            _selectTextItem = nil;
//            _selectVideoItem = videoItem;
//            videoItem.isSelected = YES;
//
//            if (extraDuration > videoItem.duration / 2) {
//                extraDuration = videoItem.duration / 2;
//            }
//
//            [self.directorMediator seekTo:videoItem.startTime + extraDuration];
//            [self.directorMediator previewFrame:videoItem.startTime + extraDuration];
//        }
        _selectIndex = indexPath.item;
        [collectionView reloadData];

    } else {
        //点选一致的情况下，如果是视频图片item则弹出替换选择页面
        if (_selectVideoItem && !_selectTextItem) {
            //获取当前cell在屏幕中的位置
            if (!_itemReplaceView) {
                CGRect cellRect = [self getSelectCellRectAtSuperView];
                [self creatItemEditViewWithRect:cellRect];
            } else {
                [self.itemReplaceView removeFromSuperview];
                self.itemReplaceView = nil;
            }
            
        }
        if (!_selectVideoItem && _selectTextItem) {
            _textField.text = _selectTextItem.text;
            [_textField becomeFirstResponder];
        }
    }
}



#pragma mark - resource replace
//获取当前cell在屏幕中的位置
- (CGRect)getSelectCellRectAtSuperView;
{
    if (_selectVideoItem) {
        
        //获取当前选中item的位置
        NSInteger selectIndex = [self.mediator.resource indexOfObject:_selectVideoItem];
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:selectIndex inSection:0];
        
        UICollectionViewCell *cell = [self collectionView:self.collectionView cellForItemAtIndexPath:indexPath];
        
        CGRect cellRect = [_collectionView convertRect:cell.frame toView:self.view];
        NSLog(@"TUEVA::Cell在屏幕中的位置==%@", NSStringFromCGRect(cellRect));
        return cellRect;
    }
    return CGRectZero;
}

- (void)creatItemEditViewWithRect:(CGRect)rect
{
    CGFloat width = 120;
    CGFloat height = 60;
    CGFloat minY = rect.origin.y - height - 10;
    CGFloat minX = rect.origin.x;
    if (_selectVideoItem.itemIndex == self.mediator.resource.count - 1) {
        minX = rect.origin.x + rect.size.width - width - 10;
    }
    self.itemReplaceView = [[TTItemReplaceView alloc] initWithFrame:CGRectMake(minX, minY, width, height)];
    self.itemReplaceView.delegate = self;
    [self.view addSubview:self.itemReplaceView];
}

/// 替换素材
- (void)replaceResource
{
    [self.itemReplaceView removeFromSuperview];
    // 去编辑图片、视频
    MultiAssetPicker *picker = [MultiAssetPicker picker];
    picker.disableMultipleSelection = YES;
    if (_selectVideoItem.type == TAEModelAssetType_ImageOrVideo) {
        picker.fetchMediaTypes = @[@(PHAssetMediaTypeImage),@(PHAssetMediaTypeVideo)];
    } else if (_selectVideoItem.type == TAEModelAssetType_Image) {
        picker.fetchMediaTypes = @[@(PHAssetMediaTypeImage)];
    } else if (_selectVideoItem.type == TAEModelAssetType_Video) {
        picker.fetchMediaTypes = @[@(PHAssetMediaTypeVideo)];
    }
    picker.navigationItem.title = @"素材选择";
    picker.delegate = self;
    picker.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
    [self showViewController:picker sender:nil];
}

/// 编辑素材
- (void)editResource
{
    [self.itemReplaceView removeFromSuperview];
    //Demo里为无素材坑位模板，只有替换了素材后才能对素材进行编辑操作
    if (_selectVideoItem.isReplace && _selectVideoItem) {
        if (_selectVideoItem.isSelectVideo) {
            //视频素材
            VideoEditViewController *edit = [[VideoEditViewController alloc] initWithNibName:nil bundle:nil];

            edit.filePath = _selectVideoItem.replaceResPath;

            edit.durationTime = _selectVideoItem.endTime - _selectVideoItem.startTime;
            edit.cutSize = _selectVideoItem.size;

            [edit setEditCompleted:^(TUPEvaReplaceConfig_ImageOrVideo * _Nonnull config, NSString *savePath) {

                [self.navigationController popToViewController:self animated:YES];
                self.selectVideoItem.isEdit = YES;
                [self updateVideoResource:config path:savePath videoPath:self.selectVideoItem.replaceResPath];
                self.selectPathState = TuSelectFilePathVideoState;
                [self replaceEvaTemplate];

            }];
            [self showViewController:edit sender:nil];
            
        } else {
            //图片素材
            ImageEditViewController *edit = [[ImageEditViewController alloc] initWithNibName:nil bundle:nil];
            //输入原始图片素材
            edit.inputImage = self.selectVideoItem.originalImage;
            edit.index = self.selectVideoItem.itemIndex;
            edit.cutSize = self.selectVideoItem.size;
            [edit setEditCompleted:^(NSURL * _Nonnull outputUrl) {
                [self.navigationController popToViewController:self animated:YES];
                self.selectVideoItem.isEdit = YES;
                [self updateImageResource:outputUrl];
                self.selectPathState = TuSelectFilePathImageState;
                [self replaceEvaTemplate];
            }];
            [self showViewController:edit sender:nil];
        }
    }
}

#pragma mark - MultiPickerDelegate
- (void)picker:(MultiAssetPicker *)picker didTapItemWithIndexPath:(NSIndexPath *)indexPath phAsset:(PHAsset *)phAsset {

    [self.navigationController popToViewController:self animated:YES];
    __weak typeof(self)weakSelf = self;
    
    __weak typeof(self.selectVideoItem)weakAsset = self.selectVideoItem;
    
    if (self.selectVideoItem.isVideo)
    {
        self.selectPathState = TuSelectFilePathVideoState;
    }
    else
    {
        self.selectPathState = TuSelectFilePathImageState;
    }
    
    [self requestAVAsset:phAsset completion:^(PHAsset *inputPhAsset, NSObject *returnValue) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (inputPhAsset.mediaType == PHAssetMediaTypeVideo) {
                
                // 去进行视频编辑
                AVURLAsset *asset = (AVURLAsset *)returnValue;
                NSString *videoPath = asset.URL.absoluteString;
                [TAEModelMediator requestVideoPathWith:asset videoIndex:weakAsset.itemIndex resultHandle:^(NSString * _Nonnull filePath, UIImage * _Nonnull fileImage) {
                    [weakSelf updateVideoResource:nil path:filePath videoPath:videoPath image:fileImage];
                    [weakSelf replaceEvaTemplate];
                    [TuPopupProgress dismiss];
                }];
            }
            if (inputPhAsset.mediaType == PHAssetMediaTypeImage) {

                UIImage *image = (UIImage *)returnValue;
                self.selectVideoItem.originalImage = image;
                [TAEModelMediator requestImagePathWith:image imageIndex:weakAsset.itemIndex resultHandle:^(NSString * _Nonnull filePath) {
                    if (!filePath) return;
                    [weakSelf updateImageResource:[NSURL fileURLWithPath:filePath]];
                    [weakSelf replaceEvaTemplate];
                    
                }];
            }
        });
    }];
}

/**
 * 更新图片资源
 * @param fileUrl 图片路径
 */
- (void)updateImageResource:(NSURL *)fileUrl
{
    self.selectedPath = [fileUrl.absoluteString componentsSeparatedByString:@"file://"].lastObject;

    __weak typeof(self)weakSelf = self;
    
    [TAEModelMediator requestImageWith:self.selectedPath resultHandle:^(UIImage * _Nonnull reslut) {
        
        [weakSelf.mediator addTempFilePath:fileUrl.path];

        weakSelf.selectVideoItem.resPath = self.selectedPath;
        weakSelf.selectVideoItem.replaceResPath = self.selectedPath;
        weakSelf.selectVideoItem.isReplace = YES;
        weakSelf.selectVideoItem.isSelectVideo = NO;
        weakSelf.selectVideoItem.thumbnail = reslut;

        [weakSelf.mediator replaceVideoItem:self.selectVideoItem];
        [weakSelf.collectionView reloadData];
        
        if (weakSelf.editCompleted) {
            weakSelf.editCompleted(weakSelf.mediator);
        }
    }];
}

/**
 * 更新视频图片资源
 * @param config 视频裁剪配置
 * @param path 视频裁剪后路径
 * @param videoPath 源视频路径
 */
- (void)updateVideoResource:(TUPEvaReplaceConfig_ImageOrVideo *)config path:(NSString *)path videoPath:(NSString *)videoPath
{
    self.selectedPath = [path componentsSeparatedByString:@"file://"].lastObject;
    __weak typeof(self)weakSelf = self;
    
    [TAEModelMediator requestVideoImageWith:self.selectedPath cropRect:config.crop resultHandle:^(UIImage * _Nonnull reslut) {
        
        [weakSelf.mediator addTempFilePath:self.selectedPath];
        
        weakSelf.selectVideoItem.isReplace = YES;
        weakSelf.selectVideoItem.isSelectVideo = YES;
        weakSelf.selectVideoItem.replaceResPath = videoPath;
        weakSelf.selectVideoItem.resPath = videoPath;
        weakSelf.selectVideoItem.thumbnail = reslut;
        
        if (config) {
            weakSelf.selectVideoItem.crop = config.crop;
            weakSelf.selectVideoItem.start = config.start;
            weakSelf.selectVideoItem.duration = config.duration;
            weakSelf.selectVideoItem.maxSide = config.maxSide;
        }
    
        [weakSelf.mediator replaceVideoItem:self.selectVideoItem];
        [weakSelf.collectionView reloadData];
        
        if (weakSelf.editCompleted) {
            weakSelf.editCompleted(weakSelf.mediator);
        }
    }];
}

/**
 * 更新视频图片资源
 * @param config 视频裁剪配置
 * @param path 视频裁剪后路径
 * @param videoPath 源视频路径
 * @param image 封面图
 */
- (void)updateVideoResource:(TUPEvaReplaceConfig_ImageOrVideo *)config path:(NSString *)path videoPath:(NSString *)videoPath image:(UIImage *)image
{
    self.selectedPath = videoPath;
    [self.mediator addTempFilePath:self.selectedPath];
    self.selectVideoItem.isReplace = YES;
    self.selectVideoItem.isSelectVideo = YES;
    self.selectVideoItem.replaceResPath = self.selectedPath;
    self.selectVideoItem.thumbnail = image;
    if (config) {
        self.selectVideoItem.crop = config.crop;
        self.selectVideoItem.start = config.start;
        self.selectVideoItem.duration = config.duration;
        self.selectVideoItem.maxSide = config.maxSide;
    }
    
    [self.mediator replaceVideoItem:self.selectVideoItem];
    [self.collectionView reloadData];
    
    if (self.editCompleted) {
        self.editCompleted(self.mediator);
    }
}

#pragma mark - actions

// 进度条值改变
- (IBAction)evaPregressValueChanged:(UISlider *)sender {
    
    if (!_isSeek) {
        _isSeek = YES;
        _sliderBefore = self.playerState != kPLAYING;
    }
    [self.directorMediator pause];
    
    // 将拖拽阈值放大
    if (abs(sender.value - _lastProgress) < 0.01) {
        return;
    }
    //拖动时间
    NSInteger seekTime = sender.value * self.totalTime;
    _lastProgress = sender.value;
    [self.directorMediator seekTo:seekTime];
}


// 进度条滑动完成
- (IBAction)evaSliderCompeleted:(UISlider *)sender {

    NSInteger seekTime = _lastProgress * self.totalTime;
    [self.directorMediator previewFrame:seekTime];
    _isSeek = NO;
    NSLog(@"TUEVA:进度条滑动完成");
    
    for (int index = 0; index < self.mediator.resource.count; index++) {
        TAEModelItem *item = self.mediator.resource[index];
        NSArray<TAEItemTime *> *times = item.io_times;
        for (TAEItemTime *time in times) {
            if (seekTime >= time.in_time && seekTime <= time.out_time) {
                
                if (!item.isSelected) {
                    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
                    item.isSelected = YES;
                    self->_selectIndex = index;
                }
                
            } else {
                if (item.isSelected) {
                    item.isSelected = NO;
                }
            }
        }
        
    }
    [self.collectionView reloadData];
}


/**
 选择音乐
 */
- (IBAction)changeMusic:(UIButton *)sender {
    
    if (![self.mediator existAudio]) {
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
    }];
}

// 替换资源后，播放器重载资源
- (void)replaceEvaTemplate {
    
    [self.directorMediator pause];
    
    //替换音乐
    if (self.selectedPath && self.selectPathState  == TuSelectFilePathMusicState) {

        //资源替换
        self.mediator.audioItem.isReplace = YES;
        self.mediator.audioItem.audioMixWeight = self.volmSlider.value;
        self.mediator.audioItem.resPath = self.selectedPath;
        [self.directorMediator updateAudio:self.mediator.audioItem];
    }
    //替换图片
    if (self.selectedPath && self.selectPathState == TuSelectFilePathImageState) {
        // 如果选择的不为视频图片图层则不替换

        if (!_selectVideoItem) return;

        _selectVideoItem.audioMixWeight = self.volmSlider.value;
//        _selectVideoItem.replaceResPath = self.selectedPath;
        
        [self.mediator replaceVideoItem:_selectVideoItem];
        [self.directorMediator updateVideoOrImage:_selectVideoItem];

    }
    //替换视频
    if (self.selectedPath && self.selectPathState == TuSelectFilePathVideoState) {
        //选中的视频资源,根据isVideo字段判断相对应涂层

        _selectVideoItem.audioMixWeight = self.volmSlider.value;
        _selectVideoItem.replaceResPath = self.selectedPath;
        [self.mediator replaceVideoItem:_selectVideoItem];

        [self.directorMediator updateVideoOrImage:_selectVideoItem];
    }
    [self.directorMediator previewFrame:self.pauseTime];
    self.evaSlider.value = self.pauseTime / self.totalTime;
    
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


// 点击视频视图
- (IBAction)tapPreview:(UITapGestureRecognizer *)sender {
    // 先处理键盘
    if ([_textField isFirstResponder]) {
        [_textField resignFirstResponder];
        return;
    }
    
    if (self.playerState == kPLAYING) {
        [self.directorMediator pause];

    } else {
        if (self.evaSlider.value >= 0.99) {
            [self.directorMediator seekTo:0];
        }
        [self.directorMediator play];
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
    _producerCancel = NO;
    
    [self.directorMediator startProducer];
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
        option.evaPath = self.mediator.filePath;
        
        [TAEExportManager shareManager].mediator = self.mediator;
        [TAEExportManager shareManager].option = option;
        [[TAEExportManager shareManager] startExport];
    });
}

/**
 * 生成临时文件路径
 * @return 文件路径
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

    if (self.playerState == kPLAYING) {
        [self.directorMediator pause];
    }
    _evaSlider.value = 0.0;
    [self.directorMediator seekTo:0];
    [self.directorMediator previewFrame:0];
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
        
    if (!_selectTextItem) return NO;
    
    //替换文字资源
    _selectTextItem.isReplace = YES;
    _selectTextItem.text = textField.text;
    [self.mediator replaceTextItem:_selectTextItem];
    [self.directorMediator updateText:_selectTextItem];

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
        CGFloat minSide = MIN(phAsset.pixelWidth, phAsset.pixelHeight);
        
        if (minSide <= 540) {
            [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                
                if (completion) completion(phAsset, asset);
            }];
        } else {
            [TuPopupProgress showWithStatus:@"处理中.."];
            
            [[PHImageManager defaultManager] requestExportSessionForVideo:phAsset options:options exportPreset:AVAssetExportPreset960x540 resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {

                TTDirectorMediator *mediator = [[TTDirectorMediator alloc] init];
                NSString *filePath = [mediator generateTempFile];
                exportSession.outputURL = [NSURL fileURLWithPath:filePath];
                exportSession.shouldOptimizeForNetworkUse = YES;
                exportSession.outputFileType = AVFileTypeMPEG4;
                [exportSession exportAsynchronouslyWithCompletionHandler:^{

                    if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                        AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:filePath]];
//                        NSLog(@"TUEVA::压缩后的视频路径==%@", filePath);
                        [self.mediator addTempFilePath:filePath];
//                        NSLog(@"TUEVA::导出后的视频路径==%@", [NSURL fileURLWithPath:filePath]);
                        if (completion) completion(phAsset, asset);
                    }
                }];
            }];
        }
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

#pragma mark - TTItemReplaceViewDelegate
- (void)itemReplaceView:(TTItemReplaceView *)view editType:(TTItemEditType)editType
{
    _selectVideoItem.isSelected = YES;

    switch (editType) {
        case TTItemEditTypeReplace:
            [self replaceResource];
            break;
        case TTItemEditTypeCrop:
            [self editResource];
            break;
        default:
            break;
    }
}

#pragma mark - TUPPlayerDelegate、TTDirectorMediatorDelegate
//- (void)onPlayerEvent:(TUPPlayerState)state withTimestamp:(NSInteger)ts
/**
 * eva播放器回调
 * @param state 播放器状态
 * @param ts 时间
 */
- (void)directorMediatorPlayerEvent:(TUPPlayerState)state withTimestamp:(NSInteger)ts;
{
    self.playerState = state;
    NSLog(@"TUEVA:播放状态 ===%ld", (long)state);
    NSLog(@"TUEVA:播放时间 ===%ld", (long)ts);

    dispatch_async(dispatch_get_main_queue(), ^{
        
        self.playBtn.hidden = self.playerState == kPLAYING;
        if (self.playerState == kAUDIO_EOS) {
            self.playBtn.hidden = YES;
        }
        if(self.playerState == kPLAYING && self.itemReplaceView) {
            [self.itemReplaceView removeFromSuperview];
        }

        NSInteger totalTime = [self.directorMediator getDuration];
        self.totalTimelabel.text = [self.mediator evaFileTotalTime:totalTime];

        self.lastProgress = [[NSString stringWithFormat:@"%.5f", ts * 1000.f / totalTime / 1000] floatValue];
        //NSLog(@"TUEVA:进度条 === %.5f", self.lastProgress);
        if (self.lastProgress != 0) {
            self.evaSlider.value = self.lastProgress;
            self.pauseTime = ts;
            self.currentTimelabel.text = [self.mediator evaFileTotalTime:self.lastProgress * totalTime];
        }

        //在播放过程中切换选中状态
        if (state == kPLAYING) {
//            if (!self->_canSelect) return;
#if 0
            //两种动画方式 1、符合时间的所有坑位均选中高亮
            for (int index = 0; index < self.mediator.resource.count; index++) {
                TAEModelItem *item = self.mediator.resource[index];
                if (self.pauseTime >= item.startTime && self.pauseTime <= item.endTime) {

                    if (!item.isSelected) {
                        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
                        item.isSelected = YES;
                        self->_selectIndex = index;
                    }

                } else {
                    if (item.isSelected) {
                        item.isSelected = NO;
                    }
                }
            }
#endif
            
#if 1
            //2、顺序选中高亮
            for (int index = 0; index < self.mediator.resource.count; index++) {
                TAEModelItem *item = self.mediator.resource[index];
                if (self.pauseTime >= item.startTime && self.pauseTime <= item.endTime) {

                    if (self->_selectIndex > index) {
                        if (item.isSelected) {
                            item.isSelected = NO;
                            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
                        }
                    } else {
                        if (!item.isSelected) {
                            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
                            item.isSelected = YES;
                            self->_selectIndex = index;
                            [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
                        }
                    }
                } else {
                    if (item.isSelected) {
                        item.isSelected = NO;
                        [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
                    }
                }
            }
#endif
//            [self.collectionView reloadData];
        }
        
        //播放完成则置为0
        if (state == kEOS)
        {
            //播放完成后全部重置为未选中状态
            for (int index = 0; index < self.mediator.resource.count; index++) {
                TAEModelItem *item = self.mediator.resource[index];
                item.isSelected = index == 0 ? YES : NO;
            }
            self.currentTimelabel.text = [self.mediator evaFileTotalTime:0];
            self.selectIndex = 0;
            self.evaSlider.value = 0;
            [self.directorMediator seekTo:0];
            [self.directorMediator previewFrame:0];
            
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
            [self.collectionView reloadData];
        }
        
        //首次进来时如果音量为不为1则置为最大
        if (self.playerState == kDO_PAUSE) {
            if (!self->_canSelect) {
                self->_canSelect = YES;
                
                //默认将系统音量调整到最大
                if (self.volumeViewSlider.value < 1.0) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                        [self.volumeViewSlider setValue:1.0 animated:NO];
                        [self.volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
                    });
                }
            }
        }
        
//        self.totalTimelabel.text = [NSString stringWithFormat:@"总时长(TS) : %ld", totalTime];
//        self.currentPlaylabel.text = [NSString stringWithFormat:@"当前播放视频时间(TS) : %ld", self.pauseTime];
//        self.resetTimelabel.text = [NSString stringWithFormat:@"剩余时长 : %ld", totalTime - self.pauseTime];
        //NSLog(@"暂停时间=== %ld", self.pauseTime);
    });
}

#pragma mark - TUPProducerDelegate、TTDirectorMediatorDelegate
/**
 * eva导出器回调
 * @param state 播放器状态
 * @param ts 时间
 */
//- (void)onProducerEvent:(TUPProducerState)state withTimestamp:(NSInteger)ts
- (void)directorMediatorProducerEvent:(TUPProducerState)state withTimestamp:(NSInteger)ts;
{
    if (_producerCancel || state == kDO_CANCEL) {

        return;
    }
    self.producerSate = state;
//    NSLog(@"TUEVA::视频时长 ===%ld", [self.evaPlayer getDuration]);
    NSLog(@"TUEVA::导出状态 === %ld", state);
    dispatch_async(dispatch_get_main_queue(), ^{
        
        float percent = ts * 1.f / self.totalTime;
        [TuPopupProgress showProgress:percent status:[NSString stringWithFormat:@"正在导出 %.0f%%",percent * 100]];
        
        //NSLog(@"导出进度 ==== %.2f", percent);
        if (self.producerSate == kEND) {
            NSString *videoPath = [[self.directorMediator producerPath] componentsSeparatedByString:@"file://"].lastObject;
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
    [self.directorMediator seekTo:self.pauseTime];
    [self.directorMediator previewFrame:self.pauseTime];
    [self.directorMediator closeProducer];
    [self.directorMediator resetProducer];

}

#pragma mark - 时间UI
- (void)creatTimeView
{
    //总时长
    self.totalTimelabel = [[UILabel alloc] init];
    self.totalTimelabel.textColor = [UIColor whiteColor];
    self.totalTimelabel.textAlignment = NSTextAlignmentRight;
    self.totalTimelabel.font = [UIFont systemFontOfSize:13];
    [self.view addSubview:self.totalTimelabel];
    [self.totalTimelabel mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.right.offset(-10);
        make.centerY.mas_equalTo(self.evaSlider);
//        make.bottom.offset(0);
    }];
    
    self.currentTimelabel = [[UILabel alloc] init];
    self.currentTimelabel.textColor = [UIColor whiteColor];
    self.currentTimelabel.font = [UIFont systemFontOfSize:13];
    self.currentTimelabel.text = [self.mediator evaFileTotalTime:0];
    [self.view addSubview:self.currentTimelabel];
    [self.currentTimelabel mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.offset(10);
        make.centerY.mas_equalTo(self.evaSlider);
//        make.bottom.offset(0);
    }];
}

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

