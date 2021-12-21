//
//  VideoEditViewController.h
//  TuSDKEvaDemo
//
//  Created by tutu on 2019/6/26.
//  Copyright © 2019 TuSdk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

#import "TuSDKFramework.h"

NS_ASSUME_NONNULL_BEGIN

@interface VideoEditViewController : UIViewController


/**
 选用裁剪的长宽
 */
@property (nonatomic, assign) CGSize cutSize;

/**
 素材时长
 */
@property (nonatomic, assign) NSInteger durationTime;

/**
 选取的视频
 */
@property (nonatomic, strong) NSArray<AVURLAsset *> *inputAssets;

/**
 时长
 */
@property (nonatomic, assign) CMTime duration;

/**
 选择确定后的回调
 */
@property (nonatomic, copy) void(^editCompleted)(TUPEvaReplaceConfig_ImageOrVideo *config, NSString *savePath);

/**
 资源文件路径
 */
@property (nonatomic, strong) NSString *filePath;


@end

NS_ASSUME_NONNULL_END
