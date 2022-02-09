//
//  TAEModelItem.m
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2021/12/13.
//  Copyright © 2021 TuSdk. All rights reserved.
//

#import "TAEModelMediator.h"
#import "TuSDKFramework.h"

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
        self.resource = [NSArray array];
        self.evaPath = evaPath;
        self.isSilenceExport = NO;
    }
    return self;
}

//加载数据
- (void)loadResource
{
    //资源加载
    TUPEvaModel *model = [[TUPEvaModel alloc] init:_evaPath];
    
    
    self.resource = [self loadOrginalResource:model];
    
    //判断是否存在音频数据
    NSArray *audioAssets = [model listReplaceableAudioAssets];
    if (audioAssets.count != 0)
    {
        self.audioItem = [[TAEModelAudioItem alloc] init];
        AudioReplaceItem *item = audioAssets.firstObject;
        self.audioItem.type = TAEModelAssetType_Audio;
        self.audioItem.Id = item.Id;
        self.audioItem.name = item.name;
        self.audioItem.resPath = item.resPath;
        self.audioItem.startTime = item.startTime;
        self.audioItem.endTime = item.endTime;
    }    
}

//加载原始数据
- (NSArray *)loadOrginalResource:(TUPEvaModel *)model
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
    for (int itemTag = 0; itemTag < resources.count; itemTag++)
    {
        id item = resources[itemTag];
        if ([item isKindOfClass:[TextReplaceItem class]])
        {
            TextReplaceItem *textReplaceItem = (TextReplaceItem *)item;
            TAEModelTextItem *textItem = [[TAEModelTextItem alloc] init];
            textItem.type = TAEModelAssetType_Text;
            textItem.text = textReplaceItem.text;
            textItem.Id = textReplaceItem.Id;
            textItem.name = textReplaceItem.name;
            textItem.startTime = textReplaceItem.startTime;
            textItem.endTime = textReplaceItem.endTime;
            [dataSource addObject:textItem];
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
            videoItem.Id = videoReplaceItem.Id;
            videoItem.name = videoReplaceItem.name;
            videoItem.startTime = videoReplaceItem.startTime;
            videoItem.endTime = videoReplaceItem.endTime;
            videoItem.isVideo = videoReplaceItem.isVideo;
            videoItem.resPath = videoReplaceItem.resPath;
            videoItem.thumbnail = videoReplaceItem.thumbnail;
            videoItem.size = videoReplaceItem.size;
            [dataSource addObject:videoItem];
        }
    }
    
    return [dataSource copy];
}

/**
 * 替换视频图片资源
 * @param videoItem  图片/视频 资源
 * @param itemIndex 资源位置
 */
- (void)replaceVideoItem:(TAEModelVideoItem *)videoItem withIndex:(NSInteger)itemIndex;
{
    NSMutableArray *dataSource = [NSMutableArray array];
    [dataSource addObjectsFromArray:self.resource];
    [dataSource replaceObjectAtIndex:itemIndex withObject:videoItem];
    self.resource = [dataSource copy];
}

/**
 * 替换文字资源
 * @param textItem  图片/视频 资源
 * @param itemIndex 资源位置
 */
- (void)replaceTextItem:(TAEModelTextItem *)textItem withIndex:(NSInteger)itemIndex;
{
    NSMutableArray *dataSource = [NSMutableArray array];
    [dataSource addObjectsFromArray:self.resource];
    [dataSource replaceObjectAtIndex:itemIndex withObject:textItem];
    self.resource = [dataSource copy];
}
/**
 * 添加需要删除的资源：图片、视频
 * @param filePath  图片/视频 路径
 */
- (void)addTempFilePath:(NSString *)filePath;
{
    [self.tempFileArray addObject:filePath];
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

@end
