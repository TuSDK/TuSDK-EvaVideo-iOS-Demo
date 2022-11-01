//
//  TAEModelItem.h
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2021/12/13.
//  Copyright © 2021 TuSdk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>
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

@interface TAEItemTime : NSObject

@property(nonatomic) NSInteger in_time;
@property(nonatomic) NSInteger out_time;

@end

/**
 * 资源
 */
@interface TAEModelItem : NSObject

/// 资源类型
@property (nonatomic, assign) TAEModelAssetType type;
/// 资源ID
@property (nonatomic, copy) NSString *Id;
/// 资源名称
@property (nonatomic, copy) NSString *name;
/// 起始时间
@property (nonatomic, assign) NSInteger startTime;
/// 截止时间
@property (nonatomic, assign) NSInteger endTime;
///持续时长
@property (nonatomic, assign) NSInteger duration;
/// 是否替换
@property (nonatomic, assign) BOOL isReplace;
/// 是否选中
@property (nonatomic, assign) BOOL isSelected;
/// 标签
@property (nonatomic, assign) NSInteger itemIndex;
///时间片数组
@property(nonatomic) NSArray *io_times;
///是否编辑
@property (nonatomic, assign) BOOL isEdit;

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
///是否为视频坑位
@property (nonatomic, assign) BOOL isVideo;
///是否选择为视频资源
@property (nonatomic, assign) BOOL isSelectVideo;
///资源路径
@property (nonatomic, copy) NSString *resPath;
///已替换资源路径
@property (nonatomic, copy) NSString *replaceResPath;
///封面图
@property (nonatomic, retain) UIImage *thumbnail;
///原始图片地址（坑位为图片时使用）
@property (nonatomic, retain) UIImage *originalImage;
///尺寸
@property (nonatomic, assign) CGSize size;
/// 是否需要替换
@property (nonatomic, assign) BOOL enableReplace;
///音量
@property (nonatomic, assign) float audioMixWeight;
///范围
@property (nonatomic, assign) CGRect crop;
///最大尺寸
@property (nonatomic, assign) NSInteger maxSide;
///资源开始时间
@property (nonatomic, assign) NSInteger start;
/// 原始视频资源
@property (nonatomic, assign) PHAsset *asset;

@end
/**
 * 音频资源
 */
@interface TAEModelAudioItem : TAEModelItem
///资源路径
@property(nonatomic, copy) NSString *resPath;
///音量
@property (nonatomic, assign) float audioMixWeight;

@end


@interface TAEModelMediator : NSObject

///音频资源
@property (nonatomic, strong) TAEModelAudioItem *audioItem;
///资源目录
@property (nonatomic, strong) NSMutableArray *resource;
///是否静默导出，默认为NO
@property (nonatomic, assign) BOOL isSilenceExport;
///文字组件数组
@property (nonatomic, strong) NSMutableArray<TAEModelTextItem *> *textItems;
/// 视频、图片组件数组
@property (nonatomic, strong) NSMutableArray<TAEModelVideoItem *> *videoItems;
/// 音频组件数组
@property (nonatomic, strong) NSMutableArray<TAEModelAudioItem *> *audioItems;
/// eva资源路径
@property (nonatomic, readonly) NSString *filePath;
/// 音量
@property (nonatomic, assign) float weight;

/**
 * 初始化中间件
 * @param evaPath 文件路径
 */
- (instancetype)initWithEvaPath:(NSString *)evaPath;


/**
 * 图片/ 视频坑位资源数量
 */
- (NSInteger)imageVideoCount;

/**
 * 文字坑位资源数量
 */
- (NSInteger)textCount;

/**
 * 音频坑位资源数量
 */
- (NSInteger)audioCount;

/**
 * 加载eva资源
 * @return 是否加载成功
 */
- (BOOL)loadResource;

/**
 * 音频资源
 * @return 音频资源
 */
- (BOOL)existAudio;

/**
 * 获取已替换图片视频数量
 * @return 已替换图片/视频数量
 */
- (NSInteger)replaceVideoCount;

/**
 * 是否允许重置
 * @return 是否允许重置
 */
- (BOOL)canReset;

/**
 * eva资源重置
 * @return 是否重置成功
 */
- (BOOL)reset;

/**
 * 请求图片资产
 * @param path 图片路径
 * @param resultHandler 完成回调
 */
+ (void)requestImageWith:(NSString *)path resultHandle:(void(^)(UIImage *reslut))resultHandler;

/**
 * 请求图片的路径
 * @param image  图片
 * @param imageIndex 图片下标
 */
+ (void)requestImagePathWith:(UIImage *)image imageIndex:(NSInteger)imageIndex resultHandle:(void(^)(NSString *filePath))resultHandler;

/**
 * 请求视频的图片封面
 * @param path  视频路径
 * @param cropRect 视频裁剪区域
 * @param resultHandler 完成回调
 */
+ (void)requestVideoImageWith:(NSString *)path cropRect:(CGRect)cropRect resultHandle:(void(^)(UIImage *reslut))resultHandler;

/**
 * 替换视频图片资源
 * @param videoItem  图片/视频 资源
 */
- (BOOL)replaceVideoItem:(TAEModelVideoItem *)videoItem;

/**
 * 替换文字资源
 * @param textItem  图片/视频 资源
 */
- (BOOL)replaceTextItem:(TAEModelTextItem *)textItem;

/**
 * 添加需要删除的资源：图片、视频
 * @param filePath  图片/视频 路径
 */
- (void)addTempFilePath:(NSString *)filePath;

/**
 * 删除所有的临时文件
 */
- (void)removeTempFilePath;

/**
 * 时长转换
 * @param currentTime 时长
 * @return 返回HH:mm:ss格式字符串
 */
- (NSString *)evaFileTotalTime:(NSInteger)currentTime;


// MARK: 弃用方法
/**
 * 请求视频的路径 - 方法已弃用
 * @param asset 视频资源
 * @param videoIndex 视频下标
 */
+ (void)requestVideoPathWith:(AVURLAsset *)asset videoIndex:(NSInteger)videoIndex resultHandle:(void(^)(NSString *filePath, UIImage *fileImage))resultHandler;
/**
 * 请求视频的路径 - 方法已弃用
 * @param coverImage 视频封面
 * @param videoIndex 视频下标
 */
+ (void)requestVideoPathWithImage:(UIImage *)coverImage videoIndex:(NSInteger)videoIndex resultHandle:(void(^)(NSString *filePath))resultHandler;


@end

NS_ASSUME_NONNULL_END
