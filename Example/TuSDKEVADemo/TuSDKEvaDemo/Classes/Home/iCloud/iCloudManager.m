//
//  iCoudManager.m
//  TuSDKEvaDemo
//
//  Created by 言有理 on 2022/3/14.
//  Copyright © 2022 TuSdk. All rights reserved.
//

#import "iCloudManager.h"
#import "TTDocument.h"
@implementation iCloudManager
+ (BOOL)iCloudEnable {
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSURL *url = [manager URLForUbiquityContainerIdentifier:nil];

    if (url != nil) {
        
        return YES;
    }
    
    NSLog(@"iCloud 不可用");
    return NO;
}
+ (void)downloadWithDocumentURL:(NSURL*)url callBack:(downloadBlock)block {
    
    TTDocument *iCloudDoc = [[TTDocument alloc] initWithFileURL:url];
    
    [iCloudDoc openWithCompletionHandler:^(BOOL success) {
        if (success) {
            
            [iCloudDoc closeWithCompletionHandler:^(BOOL success) {
                NSLog(@"关闭成功");
            }];
            
            if (block) {
                block(iCloudDoc.data);
            }
            
        }
    }];
}
@end
