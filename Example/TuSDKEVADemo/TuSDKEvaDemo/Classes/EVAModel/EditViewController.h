//
//  EditViewController.h
//  TuSDKEvaDemo
//
//  Created by tutu on 2019/6/26.
//  Copyright © 2019 TuSdk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TuSDKFramework.h"
#import <TuSDKPulse/TUPDisplayView.h>
#import "TAEModelMediator.h"
NS_ASSUME_NONNULL_BEGIN


/**
 编辑类
 */
@interface EditViewController : UIViewController

/**
 eva 资源加载器
 */
//@property (nonatomic, strong) TuSDKEvaTemplate *evaTemplate;

/**
 eva 资源加载器
 */
//@property (nonatomic, strong) TUPDisplayView *displayView;


@property (nonatomic, strong) TAEModelMediator *mediator;

@property (nonatomic, copy)void(^editCompleted)(TAEModelMediator *mediator);

@end

NS_ASSUME_NONNULL_END
