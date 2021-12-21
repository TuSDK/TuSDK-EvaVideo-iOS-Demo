//
//  TAEModelItem.h
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2021/12/13.
//  Copyright © 2021 TuSdk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TAEModelAssetType)
{
    TAEModelAssetType_Text,          //文字
    TAEModelAssetType_Video,         //视频
    TAEModelAssetType_Image,         //图片
    TAEModelAssetType_ImageOrVideo,  //图片视频
    TAEModelAssetType_Audio,         //音频
    TAEModelAssetType_Mask           //蒙版视频
};

/**
 * 资源
 */
@interface TAEModelItem : NSObject

//资源类型
@property (nonatomic, assign) TAEModelAssetType type;
//资源ID
@property (nonatomic, copy) NSString *Id;
//资源名称
@property (nonatomic, copy) NSString *name;
//起始时间
@property (nonatomic, assign) NSInteger startTime;
//截止时间
@property (nonatomic, assign) NSInteger endTime;
//是否替换
@property (nonatomic, assign) BOOL isReplace;

@end

/**
 * 文字资源
 */
@interface TAEModelTextItem : TAEModelItem
//文字
@property (nonatomic, copy) NSString *text;

@end

/**
 * 图片视频资源
 */
@interface TAEModelVideoItem : TAEModelItem
//是否为视频
@property (nonatomic, assign) BOOL isVideo;
//资源路径
@property (nonatomic, copy) NSString *resPath;
//封面图
@property (nonatomic, retain) UIImage *thumbnail;
//尺寸
@property (nonatomic, assign) CGSize size;
//音量
@property (nonatomic, assign) float audioMixWeight;
//范围
@property (nonatomic, assign) CGRect crop;
//最大尺寸
@property (nonatomic, assign) NSInteger maxSide;
//资源开始时间
@property (nonatomic, assign) NSInteger start;
//持续时长
@property (nonatomic, assign) NSInteger duration;
@end
/**
 * 音频资源
 */
@interface TAEModelAudioItem : TAEModelItem
//资源路径
@property(nonatomic, copy) NSString *resPath;

//音量
@property (nonatomic, assign) float audioMixWeight;

@end


@interface TAEModelMediator : NSObject

/**
 * 音频资源
 */
@property (nonatomic, strong) TAEModelAudioItem *audioItem;
//资源目录
@property (nonatomic, copy) NSArray *resource;
//是否静默导出，默认为NO
@property (nonatomic, assign) BOOL isSilenceExport;


- (instancetype)initWithEvaPath:(NSString *)evaPath;

//加载资源
- (void)loadResource;

/**
 * 替换视频图片资源
 * @param videoItem  图片/视频 资源
 * @param itemIndex 资源位置
 */
- (void)replaceVideoItem:(TAEModelVideoItem *)videoItem withIndex:(NSInteger)itemIndex;

/**
 * 替换文字资源
 * @param textItem  图片/视频 资源
 * @param itemIndex 资源位置
 */
- (void)replaceTextItem:(TAEModelTextItem *)textItem withIndex:(NSInteger)itemIndex;

/**
 * 添加需要删除的资源：图片、视频
 * @param filePath  图片/视频 路径
 */
- (void)addTempFilePath:(NSString *)filePath;

/**
 * 删除所有的临时文件
 */
- (void)removeTempFilePath;

@end

NS_ASSUME_NONNULL_END
