//
//  TTItemReplaceView.h
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2022/6/15.
//  Copyright © 2022 TuSdk. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class TTItemReplaceView;
typedef NS_ENUM(NSInteger, TTItemEditType) {
    /// 替换动作
    TTItemEditTypeReplace,
    /// 裁剪动作
    TTItemEditTypeCrop,
};

@protocol TTItemReplaceViewDelegate <NSObject>

@optional
/**
 * 编辑视图操作
 * @param view 视图
 * @param editType 编辑动作
 */
- (void)itemReplaceView:(TTItemReplaceView *)view editType:(TTItemEditType)editType;


@end

@interface TTItemReplaceView : UIView

@property (nonatomic, weak) id<TTItemReplaceViewDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
