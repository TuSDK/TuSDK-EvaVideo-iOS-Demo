//
//  TTMultiAssetPickerCell.h
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2022/7/22.
//  Copyright © 2022 TuSdk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTMultiAssetPickerCell : UICollectionViewCell

/**
 缩略图视图
 */
@property (nonatomic, strong, readonly) UIImageView *imageView;

/**
 选中按钮
 */
@property (nonatomic, strong, readonly) UIButton *selectButton;

/**
 时间标签
 */
@property (nonatomic, strong, readonly) UILabel *timeLabel;

/**
 选择标签
 */
@property (nonatomic, strong, readonly) UILabel *tagLabel;

/**
 选中按钮事件回调
 */
@property (nonatomic, copy) void (^selectButtonActionHandler)(TTMultiAssetPickerCell *cell, UIButton *sender);

/**
 视频时长
 */
@property (nonatomic, assign) NSTimeInterval duration;

/**
 选中序号
 */
@property (nonatomic, assign) NSInteger selectedIndex;


/**
 设置视频资产
 */
@property (nonatomic,assign)PHAsset *asset;

@end

NS_ASSUME_NONNULL_END
