//
//  TAEExportManager.m
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2021/12/13.
//  Copyright © 2021 TuSdk. All rights reserved.
//

#import "TAEExportManager.h"

#import "TuPopupProgress.h"
#import "TuSDKFramework.h"

#import "TAEWaveProgress.h"



#pragma mark - 导出器配置
@implementation TAEExportOption

- (instancetype)init
{
    if (self = [super init])
    {
        _rangeStart = 0;
        _rangeDuration = -1;
        _scale = 0;
        _watermark = nil;
        _watermarkPosition = 1;
        _savePath = nil;
        _evaPath = nil;
    }
    return self;
}

@end

#pragma mark - 导出器
@interface TAEExportManager()<TUPProducerDelegate>
{
    BOOL _saveStatus;
}
//导出状态
@property (nonatomic, assign) TUPProducerState producerSate;

@property (nonatomic, strong) TUPEvaDirector *evaDirector;

@property (nonatomic, strong) TUPEvaDirectorProducer *producer;
//进度显示视图
@property (nonatomic, strong) TAEWaveProgress *waveProgress;
//保存视频路径
@property (nonatomic, copy) NSString *videoPath;

@end

@implementation TAEExportManager

static TAEExportManager *_exportManager;

/**
 *  导出工具
 *
 *  @return TAEExportManager
 */
+ (TAEExportManager *)shareManager
{
    static dispatch_once_t once = 0;
//    static TAEExportManager *manager = nil;
    dispatch_once(&once, ^{
        _exportManager = [[self alloc] init];
    });
    return _exportManager;
}

- (instancetype)init
{
    if (self = [super init])
    {
        _saveStatus = NO;
        _type = TAEExportType_Start;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackFromFront) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterFrontFromBack) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

#pragma mark - method
//开始导出
- (void)startExport
{
    if (!_option)
    {
        NSLog(@"Export Failed. option is nil");
        return;
    }
    if (!_mediator)
    {
        NSLog(@"Export Failed. mediator is nil");
        return;
    }
    
    //仅支持一个导出任务
    if (_type == TAEExportType_Wait) {
        NSLog(@"Export Failed. There is only one export task");
        return;
    }
    
    _producerSate = kDO_START;

    TUPEvaModel *model = [[TUPEvaModel alloc] init: self.option.evaPath];
    
    self.evaDirector = [[TUPEvaDirector alloc] init];
    [self.evaDirector openModel:model];
    
    for (int itemTag = 0; itemTag < _mediator.resource.count; itemTag++)
    {
        id item = _mediator.resource[itemTag];
        if ([item isKindOfClass:[TAEModelTextItem class]])
        {
            TAEModelTextItem *textItem = (TAEModelTextItem *)item;
            if (textItem.isReplace)
            {
                [self.evaDirector updateText:textItem.Id withText:textItem.text];
            }
        }
        else if ([item isKindOfClass:[TAEModelVideoItem class]])
        {
            TAEModelVideoItem *videoItem = (TAEModelVideoItem *)item;
            if (videoItem.isReplace)
            {
                //判断是否为图片
                if (videoItem.type == TAEModelAssetType_Image)
                {
                    TUPEvaReplaceConfig_ImageOrVideo *imageConfig = [[TUPEvaReplaceConfig_ImageOrVideo alloc] init];
                    imageConfig.start = videoItem.startTime;
                    imageConfig.duration = videoItem.endTime - videoItem.startTime;
                    imageConfig.audioMixWeight = videoItem.audioMixWeight;
                    [self.evaDirector updateImage:videoItem.Id withPath:videoItem.resPath andConfig:imageConfig];
                }
                else if (videoItem.type == TAEModelAssetType_Video)
                {
                    TUPEvaReplaceConfig_ImageOrVideo *config = [[TUPEvaReplaceConfig_ImageOrVideo alloc] init];
                    config.start = videoItem.start;
                    config.duration = videoItem.duration;
                    //设置导出视频最大尺寸
                    config.maxSide = 720;
                    config.crop = videoItem.crop;
                    //判断isVideo
                    if (videoItem.isVideo)
                    {
                        [self.evaDirector updateVideo:videoItem.Id withPath:videoItem.resPath andConfig:config];
                    }
                    else
                    {
                        [self.evaDirector updateImage:videoItem.Id withPath:videoItem.resPath andConfig:config];
                    }
                }
            }
        }
    }
    if (self.mediator.audioItem)
    {
        TUPEvaReplaceConfig_Audio *audioConfig = [[TUPEvaReplaceConfig_Audio alloc] init];
        audioConfig.start = 0;
        audioConfig.duration = self.option.rangeDuration;
        audioConfig.audioMixWeight = self.mediator.audioItem.audioMixWeight;
        [self.evaDirector updateAudio:self.mediator.audioItem.Id withPath:self.mediator.audioItem.resPath andConfig:audioConfig];
    }
    
    
    TUPProducer_OutputConfig *config = [[TUPProducer_OutputConfig alloc] init];
    config.rangeStart = _option.rangeStart;
    config.rangeDuration = _option.rangeDuration;
    config.watermark = _option.watermark;
    config.watermarkPosition = _option.watermarkPosition;
    config.scale = _option.scale;
    
    self.producer = (TUPEvaDirectorProducer *)[self.evaDirector newProducer];
    self.producer.delegate = self;
    self.producer.savePath = [@"file://" stringByAppendingString:_option.savePath];
    
    [self.producer setOutputConfig:config];
    [self.producer open];
    [self.producer start];
    
    //进度
    dispatch_async(dispatch_get_main_queue(), ^{
        [self buildProgressView];
    });
}

//销毁销毁
- (void)destory;
{
    _exportManager = nil;
}

//进入后台监听
- (void)enterBackFromFront
{
    //NSLog(@"进入后台");
    if (_type == TAEExportType_Wait)
    {
        if (self.producer)
        {
            [self.producer cancel];
        }
    }
    
}

- (void)enterFrontFromBack
{
    //NSLog(@"回到前台");
}


//取消导出
- (void)cancelExport
{
    _type = TAEExportType_Cancel;
    
    //无论导出成功失败，删除Cache 目录中的临时文件
    if ([TuTSFileManager isExistFileAtPath:_videoPath]) {
        [TuTSFileManager deletePath:_videoPath];
    }
    
    ///保存成功则直接销毁
    if (_saveStatus)
    {
        [self destoryProduct];
    }
    else
    {
        if (self.evaDirector)
        {
            [self.evaDirector resetProducer];
            [self.evaDirector close];
        }
    }
    
    [self destoryOption];
}

//销毁导出器
- (void)destoryProduct
{
    if (self.producer)
    {
        [self.producer close];
    }
    if (self.evaDirector)
    {
        [self.evaDirector resetProducer];
        [self.evaDirector close];
    }
}

//销毁配置参数
- (void)destoryOption
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self->_waveProgress) {
            [self->_waveProgress removeFromSuperview];
        }
    });
    
    if (_mediator)
    {
        _mediator = nil;
    }
    
    if (_option)
    {
        _option = nil;
    }
    _videoPath = nil;
    _type = TAEExportType_Start;
}

- (void)dealloc
{
    // 移除监听
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - TUPProducerDelegate
- (void)onProducerEvent:(TUPProducerState)state withTimestamp:(NSInteger)ts
{
    
    self.producerSate = state;
    _type = TAEExportType_Wait;
//    NSLog(@"导出状态 ==== %ld", state);
    dispatch_async(dispatch_get_main_queue(), ^{
        float percent = ts * 1.f / self.option.rangeDuration;
        self->_waveProgress.progress = percent;
//        NSLog(@"导出进度  ====== %.0f", percent * 100);
    });
    
    if (_producerSate == kEND) {
        _type = TAEExportType_Start;

        NSString *videoPath = [self.producer.savePath componentsSeparatedByString:@"file://"].lastObject;
        self.videoPath = videoPath;
        UISaveVideoAtPathToSavedPhotosAlbum(videoPath, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
    }
}

#pragma mark - 视频保存回调
// 视频保存回调
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo: (void *)contextInfo
{

    if (error == nil) {
        [TuPopupProgress showSuccessWithStatus:@"导出完成"];
//        NSLog(@"导出成功 ================ success");
        _saveStatus = YES;
        
    } else {
        NSLog(@"导出失败 ================ error");
        [TuPopupProgress showErrorWithStatus:@"导出失败"];
        
        _saveStatus = NO;
        
    }
    [self cancelExport];
}



#pragma mark - showProgress
 - (void)buildProgressView
{
    CGFloat marginX = 80;
    CGFloat marginY = marginX + 100;
    CGFloat width = marginX - 20;
    self.waveProgress = [[TAEWaveProgress alloc] initWithFrame:CGRectMake(lsqScreenWidth - marginX, marginY, width, width)];
    _waveProgress.progress = 0;
    //波浪背景颜色，深绿色
    _waveProgress.waveBackgroundColor = [UIColor colorWithRed:96/255.0f green:159/255.0f blue:150/255.0f alpha:1];
    //前层波浪颜色
    _waveProgress.backWaveColor = [UIColor colorWithRed:136/255.0f green:199/255.0f blue:190/255.0f alpha:1];
    //后层波浪颜色
    _waveProgress.frontWaveColor = [UIColor colorWithRed:28/255.0 green:203/255.0 blue:174/255.0 alpha:1];
    //字体
    _waveProgress.textFont = [UIFont boldSystemFontOfSize:15];
    //文字颜色
    _waveProgress.textColor = [UIColor whiteColor];
    [[UIApplication sharedApplication].keyWindow addSubview:_waveProgress];
    //开始波浪
    [_waveProgress start];
}

@end
