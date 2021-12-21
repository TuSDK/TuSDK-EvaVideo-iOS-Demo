//
//  TuEvaAsset.m
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2020/8/6.
//  Copyright © 2020 TuSdk. All rights reserved.
//

#import "TuEvaAsset.h"
#import <Photos/Photos.h>
@implementation TuEvaAsset

- (instancetype)initWithAssetPath:(NSString *)path
{
    if (self = [super init]) {
        if (![path hasPrefix:@"file://"]) {
            path = [@"file://" stringByAppendingString:path];
        }
        _assetURL = [NSURL URLWithString:path];
    }
    return self;
}

/**
 请求图片资产
 
 @param resultHandler 完成回调
 @since v1.0.0
 */
- (void)requestImageWithResultHandler:(void (^)(UIImage *__nullable result))resultHandler
{
    
    if (!resultHandler) return;
    
    if ([self isLibraryAsset]) {
     
        PHFetchResult *result = [PHAsset fetchAssetsWithALAssetURLs:@[self.assetURL] options:nil];
        PHAsset *asset = result.firstObject;
        
        if (!asset || asset.mediaType != PHAssetMediaTypeImage) return;
        
        PHImageRequestOptions * options = [[PHImageRequestOptions alloc] init];
        options.synchronous = YES;
        options.networkAccessAllowed = NO;
        
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            resultHandler([UIImage imageWithData:imageData]);

        }];
        
    } else {
        
        NSData *imageData = [NSData dataWithContentsOfURL:self.assetURL];
        UIImage *image = [UIImage imageWithData:imageData];
        resultHandler(image);    }
}

/**
 资源链接路径
 */
- (BOOL)isLibraryAsset
{
    NSString *scheme = self.assetURL.scheme;
    return [scheme isEqualToString:@"assets-library"];
}

@end
