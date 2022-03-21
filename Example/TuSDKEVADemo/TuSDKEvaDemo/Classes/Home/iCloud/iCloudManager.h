//
//  iCoudManager.h
//  TuSDKEvaDemo
//
//  Created by 言有理 on 2022/3/14.
//  Copyright © 2022 TuSdk. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef void(^downloadBlock)(id obj);
@interface iCloudManager : NSObject
+ (BOOL)iCloudEnable;

+ (void)downloadWithDocumentURL:(NSURL*)url callBack:(downloadBlock)block;
@end

NS_ASSUME_NONNULL_END
