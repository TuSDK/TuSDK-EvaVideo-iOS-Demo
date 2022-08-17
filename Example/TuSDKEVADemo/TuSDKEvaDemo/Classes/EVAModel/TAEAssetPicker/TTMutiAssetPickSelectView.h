//
//  TTMutiAssetPickSelectView.h
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2022/6/8.
//  Copyright © 2022 TuSdk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TAEModelMediator.h"

/// 按钮操作状态
typedef NS_ENUM(NSInteger, TTMutiAssetPickSelectType) {
    TTMutiAssetPickSelectUnKnow,  //未知动作
    TTMutiAssetPickSelectNext,    //下一步
};

NS_ASSUME_NONNULL_BEGIN
@class TTMutiAssetPickSelectView;
@protocol TTMutiAssetPickSelectViewDelegate <NSObject>

@optional
/**
 * 素材资源选择动作
 * @param selectType 按钮操作状态
 */
- (void)mutiAssetPickerSelectView:(TTMutiAssetPickSelectView *)view selectAction:(TTMutiAssetPickSelectType)selectType;
/**
 * 选中的素材资源
 * @param selectItem  选中组件
 */
- (void)mutiAssetPickerSelectView:(TTMutiAssetPickSelectView *)view selectItem:(TAEModelVideoItem *)selectItem;

/**
 * 删除选中素材资源
 * @param selectItem  选中组件
 */
- (void)mutiAssetPickerSelectView:(TTMutiAssetPickSelectView *)view deleteItem:(TAEModelVideoItem *)selectItem;

@end

@interface TTMutiAssetPickSelectView : UIView
/// 是否在当前控制器
@property (nonatomic, assign) BOOL isCurrent;
@property (nonatomic, weak) id<TTMutiAssetPickSelectViewDelegate> delegate;
@property (nonatomic, strong) TAEModelMediator *mediator;
/// 获取已选择总数
@property (nonatomic, assign, readonly) NSInteger selectCount;

/// 更新数据
- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
