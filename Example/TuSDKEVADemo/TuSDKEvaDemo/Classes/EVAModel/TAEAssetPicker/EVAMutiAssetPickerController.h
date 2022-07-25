//
//  EVAMutiAssetPickerController.h
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2022/6/8.
//  Copyright © 2022 TuSdk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TAEModelMediator.h"

NS_ASSUME_NONNULL_BEGIN

@interface EVAMutiAssetPickerController : UIViewController
/// 文件路径
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, strong) TAEModelMediator *evaMediator;

@end

NS_ASSUME_NONNULL_END
