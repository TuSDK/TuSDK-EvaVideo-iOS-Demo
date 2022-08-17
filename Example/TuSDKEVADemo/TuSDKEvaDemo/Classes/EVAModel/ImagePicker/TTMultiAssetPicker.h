//
//  TTMultiAssetPicker.h
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2022/7/22.
//  Copyright © 2022 TuSdk. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AVURLAsset, PHAsset, TTMultiAssetPicker;

NS_ASSUME_NONNULL_BEGIN

/**
 * 保存的PHAsset组件
 */
@interface TTPHAssetItem : NSObject
/// asset唯一ID
@property (nonatomic, copy) NSString *assetID;
/// 已选择次数
@property (nonatomic, assign) NSInteger selectCount;

@property (nonatomic, assign) PHAsset *asset;

@end

typedef NS_ENUM(NSInteger, TTAssetMediaType)
{
    ///全部（图片 + 视频）
    TTAssetMediaTypeAll,
    /// 视频资源
    TTAssetMediaTypeVideo,
    /// 图片资源
    TTAssetMediaTypeImage,
};



@protocol TTMultiAssetPickerDelegate <NSObject>
@optional

/**
 * 点击单元格事件回调
 * @param picker 多视频选择器
 * @param indexPath 点击的 NSIndexPath 对象
 * @param phAsset 对应的 PHAsset 对象
 */
- (void)picker:(TTMultiAssetPicker *)picker didTapItemWithIndexPath:(NSIndexPath *)indexPath phAsset:(PHAsset *)phAsset;
/**
 * 点击选中按钮事件回调
 * @param picker 多视频选择器
 * @param indexPath 点击的 NSIndexPath 对象
 * @param phAsset 对应的 PHAsset 对象
 */
- (BOOL)picker:(TTMultiAssetPicker *)picker didSelectButtonItemWithIndexPath:(NSIndexPath *)indexPath phAsset:(PHAsset *)phAsset;


@end

@interface TTMultiAssetPicker : UICollectionViewController

/**
 * 图片选择器类型
 */
@property (nonatomic, assign) TTAssetMediaType assetMediaType;
/**
 * 提取的媒体类型 目前只支持图象和视频. 默认只有视频 （PHAssetMediaTypeVideo）
 * PHAssetMediaTypeImage   = 1,
 * PHAssetMediaTypeVideo   = 2,
 */
@property (nonatomic)NSArray<NSNumber *> *fetchMediaTypes;


/**
 * iCloud 请求中
 */
@property (nonatomic, assign, readonly) BOOL requesting;

/**
 * 是否禁止选择
 */
@property (nonatomic, assign, readonly) BOOL disableSelect;

/**
 * 是否禁止多选
 */
@property (nonatomic, assign) BOOL disableMultipleSelection;

@property (nonatomic, weak) id<TTMultiAssetPickerDelegate> delegate;

/**
 * 按索引获取 PHAsset
 * @param indexPathItem 索引
 * @return 索引对应的视频对象
 */
- (PHAsset *)phAssetAtIndexPathItem:(NSInteger)indexPathItem;

/**
 * 移除指定的PHAsset
 * @param asset 视频对象
 * @return 是否移除成功
 */
- (BOOL)removePHAsset:(PHAsset *)asset;


+ (instancetype)picker;

@end

NS_ASSUME_NONNULL_END
