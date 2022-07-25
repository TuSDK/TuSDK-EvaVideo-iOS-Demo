//
//  TUPEvaModel.h
//  TuSDKPulseEva
//
//  Created by Zoeric on 2020/06/20.
//  Copyright © 2020 tusdk.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN



typedef NS_ENUM(NSUInteger, TUPEvaModelAssetType) {
    //不可替换资源
    kNORMAL,
    //只替换图片
    kIMAGE_ONLY,
    //只替换视频
    kVIDEO_ONLY,
    //图片和视频
    kIMAGE_VIDEO,
    //蒙版视频
    kMASK,
    //文字
    kTEXT,
    //音频
    kAUDIO,
};

typedef NS_ENUM(NSUInteger, TUPEvaModelType) {
    TUPEvaModelType_STATIC = 1,
    TUPEvaModelType_DYNAMIC
};

@interface ItemIOTimeItem : NSObject

@property(nonatomic) NSInteger in_time;
@property(nonatomic) NSInteger out_time;

@end

@interface ReplaceItem : NSObject

@property(nonatomic) TUPEvaModelAssetType type;
@property(nonatomic, copy) NSString* Id;
@property(nonatomic, copy) NSString* name;
@property(nonatomic) NSInteger startTime;
@property(nonatomic) NSInteger endTime;
///时间片数组
@property(nonatomic) NSArray<ItemIOTimeItem *> *io_times;


@end


@interface TextReplaceItem : ReplaceItem

@property(nonatomic, copy) NSString* text;

@end



@interface VideoReplaceItem : ReplaceItem

//video / image / mask
@property(nonatomic) BOOL isVideo;
@property(nonatomic, copy) NSString* resPath;
@property(nonatomic, retain) UIImage* thumbnail;
@property(nonatomic) CGSize size;


@end


@interface MaskReplaceItem : ReplaceItem

@property(nonatomic, copy) NSString* resPath;
@property(nonatomic, retain) UIImage* thumbnail;

@end


@interface AudioReplaceItem : ReplaceItem

@property(nonatomic, copy) NSString* resPath;

@end

@interface DynReplaceItem : ReplaceItem

@property(nonatomic, assign) NSInteger width;
@property(nonatomic, assign) NSInteger height;
@property(nonatomic, copy) NSString *resPath;
@property(nonatomic, strong) UIImage *thumbnail;

@end

@interface TUPEvaReplaceConfig : NSObject {

}
@property(nonatomic) NSInteger start;//trim start
@property(nonatomic) NSInteger duration;//trim length
@property(nonatomic) int repeat; // 0: for none, 1: trailing frame/silence, 2: repeat
@end

@interface TUPEvaReplaceConfig_ImageOrVideo : TUPEvaReplaceConfig {
    
}
@property(nonatomic) CGRect crop;// src crop
@property(nonatomic) NSInteger maxSide;// input video's max-side
@property(nonatomic) float audioMixWeight;// audio mix weight
@property(nonatomic, copy) NSString *path; // 仅限动态模板使用 待替换素材的地址


- (void) unwrap:(void*)config;//EvaReplaceConfig_ImageOrVideo*

@end

@interface TUPEvaReplaceConfig_Audio : TUPEvaReplaceConfig {
    
}
@property(nonatomic) float audioMixWeight;


- (void) unwrap:(void*)config;//EvaReplaceConfig_Audio*

@end

@interface TUPEvaModel : NSObject {

    @package
    void* _impl;
}




//- (instancetype) initWithJson:(NSString*)path;

- (instancetype) init:(NSString*)path;

- (instancetype) init:(NSString*)path modelType:(TUPEvaModelType)modelType;
- (CGSize) getSize;

- (NSArray<TextReplaceItem*>*) listReplaceableTextAssets;

- (NSArray<VideoReplaceItem*>*) listReplaceableImageAssets;

- (NSArray<VideoReplaceItem*>*) listReplaceableVideoAssets;

- (NSArray<MaskReplaceItem*>*) listReplaceableMaskAssets;

- (NSArray<AudioReplaceItem*>*) listReplaceableAudioAssets;

+ (void)clearAllCaches;

@end

NS_ASSUME_NONNULL_END
