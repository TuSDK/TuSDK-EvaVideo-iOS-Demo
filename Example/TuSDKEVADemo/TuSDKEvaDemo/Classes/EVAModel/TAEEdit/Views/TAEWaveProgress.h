//
//  TAEWareProgress.h
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2021/12/14.
//  Copyright © 2021 TuSdk. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TAEWaveProgress : UIView

/**
 * 进度 0~1
 */
@property (nonatomic ,assign) CGFloat progress;
/**
 * 文字颜色
 */
@property (nonatomic ,strong) UIColor *textColor;
/**
 * 文字字体
 */
@property (nonatomic ,strong) UIFont *textFont;
/**
 * 前层波浪颜色
 */
@property (nonatomic ,strong) UIColor *frontWaveColor;
/**
 * 后层波浪颜色
 */
@property (nonatomic ,strong) UIColor *backWaveColor;
/**
 * 波浪背景色
 */
@property (nonatomic ,strong) UIColor *waveBackgroundColor;

/**
 * 开始
 */
- (void)start;
/**
 * 停止
 */
- (void)stop;

@end

NS_ASSUME_NONNULL_END
