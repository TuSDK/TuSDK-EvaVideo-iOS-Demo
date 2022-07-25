//
//  TTMutiAssetPickSelectCell.h
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2022/6/8.
//  Copyright © 2022 TuSdk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TAEModelMediator.h"
NS_ASSUME_NONNULL_BEGIN

@interface TTMutiAssetPickSelectCell : UICollectionViewCell

@property (nonatomic, strong) TAEModelVideoItem *item;
/// 关闭按钮
@property (nonatomic, strong) UIButton *closeButton;


@end

NS_ASSUME_NONNULL_END
