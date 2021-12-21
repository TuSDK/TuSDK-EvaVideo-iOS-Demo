//
//  TAEExportManager.h
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2021/12/13.
//  Copyright © 2021 TuSdk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <TuSDKPulseEva/TUPEvaProducer.h>
#import <TuSDKPulseEva/TUPEvaDirector.h>
#import "TAEModelMediator.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, TAEExportType)
{
    TAEExportType_Wait,          //等待
    TAEExportType_Start,         //开始
    TAEExportType_Cancel         //暂停
};


/**
 *  导出配置器
 */
@interface TAEExportOption : NSObject
//区间起点
@property (nonatomic) int64_t rangeStart;
//区间长度
@property (nonatomic) int64_t rangeDuration;
@property (nonatomic) double scale;
//水印位置
@property (nonatomic) int watermarkPosition;
//水印图片
@property (nonatomic) UIImage* watermark;
//保存路径
@property (nonatomic, copy) NSString *savePath;
//文件源路径
@property (nonatomic, copy) NSString *evaPath;

@end

@interface TAEExportManager : NSObject
//配置资源
@property (nonatomic, strong) TAEExportOption *option;
//资源数据
@property (nonatomic, strong) TAEModelMediator *mediator;
//等待类型
@property (nonatomic, assign) TAEExportType type;

+ (TAEExportManager *)shareManager;

//开始导出
- (void)startExport;
//取消导出
- (void)cancelExport;
//销毁
- (void)destory;

@end

NS_ASSUME_NONNULL_END
