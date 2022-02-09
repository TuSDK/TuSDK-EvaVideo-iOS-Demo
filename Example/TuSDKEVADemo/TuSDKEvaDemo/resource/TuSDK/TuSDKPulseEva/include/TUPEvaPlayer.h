//
//  TUPAVPlayer.h
//  TuSDKPulse
//
//  Created by tutu on 2020/6/15.
//  Copyright © 2020 tusdk.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TUPPlayer.h"
#import "TUPEvaModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface TUPEvaPlayer : TUPPlayer


//- (BOOL) openPath:(NSString*)path;

- (BOOL) openModel:(TUPEvaModel*)model;



- (BOOL) updateText:(NSString*)Id withText:(NSString*) text;

- (BOOL) updateImage:(NSString*)Id withPath:(NSString*) path andConfig:(TUPEvaReplaceConfig_ImageOrVideo*)config;

- (BOOL) updateVideo:(NSString*)Id withPath:(NSString*) path andConfig:(TUPEvaReplaceConfig_ImageOrVideo*)config;

- (BOOL) updateAudio:(NSString*)Id withPath:(NSString*) path andConfig:(TUPEvaReplaceConfig_Audio*)config;


@end

NS_ASSUME_NONNULL_END
