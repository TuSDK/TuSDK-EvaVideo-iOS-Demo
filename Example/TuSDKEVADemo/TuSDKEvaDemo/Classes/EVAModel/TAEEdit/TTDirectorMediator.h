//
//  TTDirectorMediator.h
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2022/6/16.
//  Copyright © 2022 TuSdk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TAEModelMediator.h"

#import <TuSDKPulse/TUPDisplayView.h>
#import <TuSDKPulseEva/TUPEvaProducer.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TTDirectorMediatorDelegate <NSObject>

@optional
/**
 * eva播放器回调
 * @param state 播放器状态
 * @param ts 时间
 */
- (void)directorMediatorPlayerEvent:(TUPPlayerState)state withTimestamp:(NSInteger)ts;
/**
 * eva导出器回调
 * @param state 播放器状态
 * @param ts 时间
 */
- (void)directorMediatorProducerEvent:(TUPProducerState)state withTimestamp:(NSInteger)ts;

@end

@interface TTDirectorMediator : NSObject

@property (nonatomic, weak) id<TTDirectorMediatorDelegate> delegate;

/**
 * 第一步 : eva 模型创建
 * @param evaPath 文件路径
 * @return 创建成功
 */
- (BOOL)setup:(NSString *)evaPath;
/**
 * 第二步 : 加载eva播放器
 * @param rootView 播放器承载背景视图
 * @param rect frame
 * @return 是否加载成功
 */
- (BOOL)setupView:(UIView *)rootView rect:(CGRect)rect;


#pragma mark - 渲染
/**
 * 替换视频坑位
 * @param videoItem 视频组件
 * @return 替换成功
 */
- (BOOL)updateVideoOrImage:(TAEModelVideoItem *)videoItem;

/**
 * 替换文字坑位
 * @param textItem 文字组件
 * @return 替换成功
 */
- (BOOL)updateText:(TAEModelTextItem *)textItem;

/**
 * 替换背景音乐坑位
 * @param audioItem 音乐组件
 * @return 替换成功
 */
- (BOOL)updateAudio:(TAEModelAudioItem *)audioItem;

#pragma mark - 播放器相关
/**
 * 定位到指定时间
 * @param time 时间
 * @return 跳转成功
 */
- (BOOL)seekTo:(NSInteger)time;
/**
 * 画面定位到指定时间
 * @param time 时间
 * @return 跳转成功
 */
- (BOOL)previewFrame:(NSInteger)time;

/// 重置
- (void)reset;

/// 销毁
- (void)destory;
/// 暂停
- (BOOL)pause;
/// 播放
- (BOOL)play;

#pragma mark - 导出
/// 开始导出
- (void)startProducer;
/// 取消导出器
- (void)cancelProducer;
/// 关闭导出器
- (void)closeProducer;
/// 重置导出器
- (void)resetProducer;

/// 导出路径
- (NSString *)producerPath;
/**
 * 生成临时文件路径
 * @return 文件路径
 */
- (NSString *)generateTempFile;
/**
 * 获取视频总时长
 * @return 视频总时长
 */
- (NSInteger)getDuration;
/**
 * 获取模型尺寸
 * @return 视频模型尺寸
 */
- (CGSize)modelSize;

@end

NS_ASSUME_NONNULL_END
