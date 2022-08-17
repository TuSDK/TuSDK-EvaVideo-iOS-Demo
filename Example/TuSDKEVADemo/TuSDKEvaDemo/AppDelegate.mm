//
//  AppDelegate.m
//  TuSDKEvaDemo
//
//  Created by sprint on 2019/5/26.
//  Copyright © 2019 TuSdk. All rights reserved.
//

#import "AppDelegate.h"
#import "TuSDKFramework.h"
#import "TuPopupProgress.h"
#import "TAEExportManager.h"
#ifdef DEBUG
//#import <DoraemonKit/DoraemonManager.h>
#endif
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [TUCCore initSdkWithAppKey:@"9573fb1a49c35b1c-04-ewdjn1"];
    // 可选: 设置日志输出级别 (默认不输出)
    [TUCCore setLogLevel:TuLogLevelDEBUG];
    // 设置弹框时，背景按钮不可点击
    [TuPopupProgress setDefaultMaskType:TuSDKProgressHUDMaskTypeClear];
    
#ifdef DEBUG
//    [[DoraemonManager shareInstance] install];
#endif
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        BuglyConfig *config = [[BuglyConfig alloc] init];
//        config.reportLogLevel = BuglyLogLevelWarn;
//        [Bugly startWithAppId:@"ef72f7b463" config:config];
//    });
    
    
    // 添加文件引入
    //#import <TuSDK/TuSDK.h>
    // 版本号输出
    //NSLog(@"TuSDK.framework 的版本号 : %@",lsqSDKVersion);
    //NSLog(@"TuSDKVideo.framework 的版本号 : %@",lsqVideoVersion);
    //NSLog(@"TuSDKEva.framework 的版本号 : %@",lsqEvaVersion);
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[TAEExportManager shareManager] destory];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    // 接收到内存警告
    NSLog(@"=========================================");
    NSLog(@"++++++++++++++内存警告+++++++++++++++++++++");
    NSLog(@"=========================================");
}
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    

    if (url) {
        NSString *fileName = url.lastPathComponent; // 从路径中获得完整的文件名（带后缀）
        // path 类似这种格式：file:///private/var/mobile/Containers/Data/Application/83643509-E90E-40A6-92EA-47A44B40CBBF/Documents/Inbox/jfkdfj123a.pdf
        NSString *path = url.absoluteString; // 完整的url字符串
        path = [self URLDecodedString:path]; // 解决url编码问题
        
        NSMutableString *string = [[NSMutableString alloc] initWithString:path];

        if ([path hasPrefix:@"file://"]) { // 通过前缀来判断是文件
            // 去除前缀：/private/var/mobile/Containers/Data/Application/83643509-E90E-40A6-92EA-47A44B40CBBF/Documents/Inbox/jfkdfj123a.pdf
            [string replaceOccurrencesOfString:@"file://" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, path.length)];

            // 此时获取到文件存储在本地的路径，就可以在自己需要使用的页面使用了
            NSDictionary *dict = @{@"fileName":fileName,
                                   @"filePath":string};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FileNotification" object:nil userInfo:dict];

            return YES;
        }
    }
    
    return YES;
}

// 当文件名为中文时，解决url编码问题
- (NSString *)URLDecodedString:(NSString *)str {
    NSString *decodedString=(__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)str, CFSTR(""), CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding));
    NSLog(@"decodedString = %@",decodedString);
    return decodedString;
}


@end
