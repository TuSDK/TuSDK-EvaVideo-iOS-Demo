//
//  TAEModelItem.m
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2021/12/13.
//  Copyright © 2021 TuSdk. All rights reserved.
//

#import "TAEModelMediator.h"
#import <TuSDKPulseEva/TUPEvaModel.h>


#import "TuSDKFramework.h"
#define vOutPutSize CGSizeMake(540, 960)
#define hOutPutSize CGSizeMake(960, 540)


@implementation TAEItemTime

- (instancetype)init
{
    if (self = [super init]) {
        self.in_time = 0;
        self.out_time = 0;
    }
    return self;
}

@end

@implementation TAEModelTextItem

@end

@implementation TAEModelVideoItem

- (instancetype)init
{
    if (self = [super init]) {
        _audioMixWeight = 0.5;
        _crop = CGRectMake(0, 0, 1, 1);
        _maxSide = 0;
    }
    return self;
}

@end

@implementation TAEModelAudioItem

- (instancetype)init
{
    if (self = [super init])
    {
        _audioMixWeight = 0.5;
    }
    return self;
}

@end



@implementation TAEModelItem

- (instancetype)init
{
    if (self = [super init])
    {
        _isReplace = NO;
        _isSelected = NO;
        _isEdit = NO;

    }
    return self;
}

@end

#pragma mark - TAEModelMediator
@interface TAEModelMediator()

//eva文件目录
@property (nonatomic, copy) NSString *evaPath;
//临时文件数组，用于存放临时图片和视频路径
@property (nonatomic, strong) NSMutableArray *tempFileArray;
@end

@implementation TAEModelMediator

- (instancetype)initWithEvaPath:(NSString *)evaPath
{
    if (self = [super init])
    {
        self.tempFileArray = [NSMutableArray array];
        self.resource = [NSMutableArray array];
        self.textItems = [NSMutableArray array];
        self.videoItems = [NSMutableArray array];
        self.audioItems = [NSMutableArray array];
        self.evaPath = evaPath;
        self.isSilenceExport = NO;
        [self loadResource];
    }
    return self;
}

/**
 * 加载eva资源
 * @return 是否加载成功
 */
- (BOOL)loadResource;
{
    //资源加载
    TUPEvaModel *model = [[TUPEvaModel alloc] init:_evaPath];
    if (!model) {
        return NO;
    }
    
    self.resource = [self loadOrginalResource:model];
    
    //判断是否存在音频数据
    NSArray *audioAssets = [model listReplaceableAudioAssets];
    if (audioAssets.count != 0)
    {
        [self.audioItems removeAllObjects];
        self.audioItem = [[TAEModelAudioItem alloc] init];
        AudioReplaceItem *item = audioAssets.firstObject;
        self.audioItem.type = TAEModelAssetType_Audio;
        self.audioItem.Id = item.Id;
        self.audioItem.name = item.name;
        self.audioItem.resPath = item.resPath;
        self.audioItem.startTime = item.startTime;
        self.audioItem.endTime = item.endTime;
        
        [self.audioItems addObject:self.audioItem];
    }
    return YES;
}

/**
 * 音频资源
 * @return 音频资源
 */
- (BOOL)existAudio;
{
    //资源加载
    TUPEvaModel *model = [[TUPEvaModel alloc] init:_evaPath];
    if (!model) {
        return NO;
    }
    if (self.audioItems.count == 0 || !self.audioItem) {
        return NO;
    }
    
    return YES;
}

//加载原始数据
- (NSMutableArray *)loadOrginalResource:(TUPEvaModel *)model
{
    NSMutableArray *resources = [NSMutableArray array];
    [resources addObjectsFromArray:[model listReplaceableImageAssets]];
    [resources addObjectsFromArray:[model listReplaceableVideoAssets]];
    [resources addObjectsFromArray:[model listReplaceableTextAssets]];
    
    //用资源显示的开始帧进行排序
    [resources sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        
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
        
    //配置新数据
    NSMutableArray *dataSource = [NSMutableArray array];
    [self.videoItems removeAllObjects];
    [self.textItems removeAllObjects];
    for (int itemTag = 0; itemTag < resources.count; itemTag++)
    {
        id item = resources[itemTag];
        if ([item isKindOfClass:[TextReplaceItem class]])
        {
            TextReplaceItem *textReplaceItem = (TextReplaceItem *)item;
            TAEModelTextItem *textItem = [[TAEModelTextItem alloc] init];
            textItem.itemIndex = itemTag;
            textItem.type = TAEModelAssetType_Text;
            textItem.text = textReplaceItem.text;
            textItem.Id = textReplaceItem.Id;
            textItem.name = textReplaceItem.name;
            textItem.startTime = textReplaceItem.startTime;
            textItem.endTime = textReplaceItem.endTime;
            textItem.duration = textItem.endTime - textItem.startTime;
            
            NSMutableArray<TAEItemTime *> *itemTimes = [NSMutableArray array];
            for (ItemIOTimeItem *item in textReplaceItem.io_times) {
                TAEItemTime *time = [[TAEItemTime alloc] init];
                time.in_time = item.in_time;
                time.out_time = item.out_time;
                [itemTimes addObject:time];
            }
            textItem.io_times = [itemTimes copy];
            [dataSource addObject:textItem];
            
            [self.textItems addObject:textItem];
        }
        else if ([item isKindOfClass:[VideoReplaceItem class]])
        {
            VideoReplaceItem *videoReplaceItem = (VideoReplaceItem *)item;
            TAEModelVideoItem *videoItem = [[TAEModelVideoItem alloc] init];
            if (videoReplaceItem.type == kIMAGE_VIDEO)
            {
                //图片/视频
                videoItem.type = TAEModelAssetType_ImageOrVideo;
            }
            else if (videoReplaceItem.type == kIMAGE_ONLY)
            {
                //图片
                videoItem.type = TAEModelAssetType_Image;
            }
            else if (videoReplaceItem.type == kVIDEO_ONLY)
            {
                //视频
                videoItem.type = TAEModelAssetType_Video;
            }
            videoItem.itemIndex = itemTag;
            videoItem.Id = videoReplaceItem.Id;
            videoItem.name = videoReplaceItem.name;
            videoItem.startTime = videoReplaceItem.startTime;
            videoItem.endTime = videoReplaceItem.endTime;
            videoItem.isVideo = videoReplaceItem.isVideo;
            //videoItem.resPath = videoReplaceItem.resPath;
            videoItem.thumbnail = videoReplaceItem.thumbnail;
            videoItem.size = videoReplaceItem.size;
            videoItem.start = 0;
            videoItem.duration = videoItem.endTime - videoItem.startTime;
            
            NSMutableArray<TAEItemTime *> *itemTimes = [NSMutableArray array];
            for (ItemIOTimeItem *item in videoReplaceItem.io_times) {
                TAEItemTime *time = [[TAEItemTime alloc] init];
                time.in_time = item.in_time;
                time.out_time = item.out_time;
                [itemTimes addObject:time];
            }
            videoItem.io_times = [itemTimes copy];
            
            [dataSource addObject:videoItem];
            [self.videoItems addObject:videoItem];
        }
    }
    
    return dataSource;
}

+ (NSURL *)assetPath:(NSString *)path
{
    if (![path hasPrefix:@"file://"]) {
        path = [@"file://" stringByAppendingString:path];
    }
    return [NSURL URLWithString:path];
}

/**
 * 请求图片资产
 * @param path 图片路径
 * @param resultHandler 完成回调
 */
+ (void)requestImageWith:(NSString *)path resultHandle:(void(^)(UIImage *reslut))resultHandler
{
    if (!path) {
        resultHandler(nil);
        return;
    }
    NSURL *assetURL = [self assetPath:path];
    
    if ([self isLibraryAsset:assetURL]) {
        
        PHFetchResult *result = [PHAsset fetchAssetsWithALAssetURLs:@[assetURL] options:nil];
        PHAsset *asset = result.firstObject;
        if (!asset || asset.mediaType != PHAssetMediaTypeImage) return;
        
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.synchronous = YES;
        options.networkAccessAllowed = NO;
        
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
           
            resultHandler([UIImage imageWithData:imageData]);
        }];
    } else {
        NSData *imageData = [NSData dataWithContentsOfURL:assetURL];
        UIImage *resultImage = [UIImage imageWithData:imageData];
        resultHandler(resultImage);
    }
}
/**
 * 请求视频的图片封面
 * @param path  视频路径
 * @param cropRect 视频裁剪区域
 * @param resultHandler 完成回调
 */
+ (void)requestVideoImageWith:(NSString *)path cropRect:(CGRect)cropRect resultHandle:(void(^)(UIImage *reslut))resultHandler
{
    //如果裁剪区域不存在或者是为0，则置为(0, 0, 1, 1)
    if (CGRectEqualToRect(cropRect, CGRectNull) || CGRectEqualToRect(cropRect, CGRectZero)) {
        cropRect = CGRectMake(0, 0, 1, 1);
    }
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:path] options:nil];
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    assetGen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    
    CGFloat imageW = videoImage.size.width;
    CGFloat imageH = videoImage.size.height;
    //判断视频为横向还是竖向
    if (imageW > imageH) {
        videoImage = [videoImage lsqImageCorpWithPrecentRect:cropRect outputSize:hOutPutSize];
    } else {
        videoImage = [videoImage lsqImageCorpWithPrecentRect:cropRect outputSize:vOutPutSize];
    }
    
//    CGSize outPutSize = CGSizeMake(720, 1280);
    
    resultHandler(videoImage);
}

/**
 资源链接路径
 */
+ (BOOL)isLibraryAsset:(NSURL *)assetURL
{
    NSString *scheme = assetURL.scheme;
    return [scheme isEqualToString:@"assets-library"];
}

/**
 * 替换视频图片资源
 * @param videoItem  图片/视频 资源
 */
- (BOOL)replaceVideoItem:(TAEModelVideoItem *)videoItem;
{
    if (!videoItem) return NO;
    
    if (videoItem.resPath == nil) {
        videoItem.resPath = videoItem.replaceResPath;
    }
    [self.resource replaceObjectAtIndex:videoItem.itemIndex withObject:videoItem];
    
    
    for (NSInteger index = 0; index < self.videoItems.count; index++) {
        TAEModelVideoItem *item = self.videoItems[index];
        if (item.itemIndex == videoItem.itemIndex) {
            [self.videoItems replaceObjectAtIndex:index withObject:videoItem];
        }
    }
    return YES;
}

/**
 * 替换文字资源
 * @param textItem  图片/视频 资源
 */
- (BOOL)replaceTextItem:(TAEModelTextItem *)textItem;
{
    if (!textItem) return NO;
    [self.resource replaceObjectAtIndex:textItem.itemIndex withObject:textItem];
    
    for (NSInteger index = 0; index < self.textItems.count; index++) {
        TAEModelTextItem *item = self.textItems[index];
        if (item.itemIndex == textItem.itemIndex) {
            [self.textItems replaceObjectAtIndex:index withObject:textItem];
        }
    }
    return YES;
}
/**
 * 添加需要删除的资源：图片、视频
 * @param filePath  图片/视频 路径
 */
- (void)addTempFilePath:(NSString *)filePath;
{
    if (!filePath) return;
    [self.tempFileArray addObject:filePath];
}
/**
 * 请求图片的路径
 * @param image  图片
 * @param imageIndex 图片下标
 */
+ (void)requestImagePathWith:(UIImage *)image imageIndex:(NSInteger)imageIndex resultHandle:(void(^)(NSString *filePath))resultHandler;
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"result_%ld.png", (long)imageIndex]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        if (success) {
            NSLog(@"删除成功");
        }
    }
    BOOL result = [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
    if (result) {
        resultHandler(filePath);
    } else {
        resultHandler(nil);
    }
}

/**
 * 获取已替换图片视频数量
 * @return 已替换图片/视频数量
 */
- (NSInteger)replaceVideoCount;
{
    //无需替换资源数量
    NSInteger count = 0;
    //需要替换资源数量
    NSInteger replaceCount = 0;
    for (TAEModelVideoItem *videoItem in self.videoItems) {
        //判断是否需要替换
        if (!videoItem.enableReplace) {
            count++;
        } else {
            //需要替换
            if (videoItem.isReplace) {
                //已替换数量
                replaceCount++;
            }
        }
    }
    //如果为满素材资源，则可以直接跳过
    if (count == self.videoItems.count) return 0;
    
    NSInteger needReplaceCount = self.videoItems.count - replaceCount;
    return needReplaceCount;
}

/**
 * 是否允许重置
 * @return 是否允许重置
 */
- (BOOL)canReset;
{
    //如果音频被替换
    if (self.audioItem.isReplace) {
        return self.audioItem.isReplace;
    }
    //如果文字被替换
    for (TAEModelTextItem *textItem in self.textItems) {
        if (textItem.isReplace) {
            return textItem.isReplace;
        }
    }
    //如果音频被替换
    for (TAEModelVideoItem *videoItem in self.videoItems) {
        if (videoItem.isReplace) {
            return videoItem.isReplace;
        }
    }
    
    return NO;
}

/**
 * eva资源重置
 * @return 是否重置成功
 */
- (BOOL)reset;
{
    //删除所有临时路径
    [self.tempFileArray removeAllObjects];
    return [self loadResource];
}

/**
 * 删除所有的临时文件
 */
- (void)removeTempFilePath;
{
    //如果存有临时文件，则需要删除
    if (_tempFileArray && _tempFileArray.count > 0)
    {
        [_tempFileArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            [TuTSFileManager deletePath:obj];
            
        }];
    }
}

/**
 * 时长转换
 * @param currentTime 时长
 * @return 返回HH:mm:ss格式字符串
 */
- (NSString *)evaFileTotalTime:(NSInteger)currentTime;
{
    NSInteger seconds = currentTime / 1000;
    
    NSInteger hour = seconds / 3600;
    //format of hour
    NSString *str_hour = [NSString stringWithFormat:@"%02ld",hour];
    //format of minute
    NSString *str_minute = [NSString stringWithFormat:@"%02ld",(seconds%3600)/60];
    //format of second
    NSString *str_second = [NSString stringWithFormat:@"%02ld",seconds%60];
    
    if (hour > 0) {
        return [NSString stringWithFormat:@"%@:%@:%@",str_hour,str_minute,str_second];
    }
    return [NSString stringWithFormat:@"%@:%@",str_minute,str_second];
}

#pragma mark - setter getter
- (NSString *)filePath
{
    return self.evaPath;
}

/**
 * 图片/ 视频坑位资源数量
 */
- (NSInteger)imageVideoCount;
{
    return self.videoItems.count;
}

/**
 * 文字坑位资源数量
 */
- (NSInteger)textCount;
{
    return self.textItems.count;
}
/**
 * 音频坑位资源数量
 */
- (NSInteger)audioCount;
{
    return self.audioItems.count;
}



#pragma mark - deprecated 过期方法

/**
 * 请求视频的路径
 * @param asset  视频资源
 * @param videoIndex 视频下标
 */
+ (void)requestVideoPathWith:(AVURLAsset *)asset videoIndex:(NSInteger)videoIndex resultHandle:(void(^)(NSString *filePath, UIImage *fileImage))resultHandler;
{
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];

    assetGen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);

    CGFloat imageW = videoImage.size.width;
    CGFloat imageH = videoImage.size.height;
    //判断视频为横向还是竖向
    if (imageW > imageH) {
        videoImage = [videoImage lsqImageCorpWithPrecentRect:CGRectMake(0, 0, 1, 1) outputSize:hOutPutSize];

    } else {
        videoImage = [videoImage lsqImageCorpWithPrecentRect:CGRectMake(0, 0, 1, 1) outputSize:vOutPutSize];
    }

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"result_%ld.png", (long)videoIndex]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        if (success) {
            NSLog(@"删除成功");
        }
    }
    BOOL result = [UIImagePNGRepresentation(videoImage) writeToFile:filePath atomically:YES];
    if (result) {
        resultHandler(filePath, videoImage);
    } else {
        resultHandler(nil, nil);
    }
}

/**
 * 请求视频的路径
 * @param coverImage 封面图
 * @param videoIndex 视频下标
 */
+ (void)requestVideoPathWithImage:(UIImage *)coverImage videoIndex:(NSInteger)videoIndex resultHandle:(void(^)(NSString *filePath))resultHandler;
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"result_%ld.png", (long)videoIndex]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        if (success) {
            NSLog(@"删除成功");
        }
    }
    BOOL result = [UIImagePNGRepresentation(coverImage) writeToFile:filePath atomically:YES];
    if (result) {
        resultHandler(filePath);
    } else {
        resultHandler(nil);
    }
}

@end
