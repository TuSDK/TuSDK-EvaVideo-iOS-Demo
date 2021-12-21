//
//  TuEvaAsset.h
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2020/8/6.
//  Copyright © 2020 TuSdk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TuEvaAsset : NSObject

/**
 资源完整路径
 @since v1.0.0 ([NSURL fileURLWithPath])
 */
@property (nonatomic) NSURL *assetURL;

- (instancetype)initWithAssetPath:(NSString *)path;

- (void)requestImageWithResultHandler:(void (^)(UIImage *__nullable result))resultHandler;

@end

NS_ASSUME_NONNULL_END
