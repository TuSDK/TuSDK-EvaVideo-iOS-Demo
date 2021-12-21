//
//  TAEWave.h
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2021/12/14.
//  Copyright © 2021 TuSdk. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TAEWave : UIView

/**
 * 设置进度 0~1
 */
@property (nonatomic, assign) CGFloat progress;

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
