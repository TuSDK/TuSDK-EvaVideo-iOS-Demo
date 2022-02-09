//
//  TUPDirector.h
//  TuSDKPulse
//
//  Created by tutu on 2020/8/14.
//  Copyright © 2020 tusdk.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TUPBase.h"
#import "TUPPlayer.h"
#import "TUPProducer.h"

#import "TUPEvaModel.h"


NS_ASSUME_NONNULL_BEGIN
//
//@class TUPPlayer;
//@class TUPProducer;
//


@interface TUPEvaDirectorPlayer : TUPPlayer
- (instancetype) initWithImpl:(void*) impl;
- (BOOL) open;
@end


@interface TUPEvaDirectorProducer : TUPProducer
- (instancetype) initWithImpl:(void*) impl;
- (BOOL) open;
@end


@interface TUPEvaDirector : TUPBase


- (BOOL) openModel:(TUPEvaModel*)model;

- (void) close;



- (BOOL) updateText:(NSString*)Id withText:(NSString*) text;

- (BOOL) updateImage:(NSString*)Id withPath:(NSString*) path andConfig:(TUPEvaReplaceConfig_ImageOrVideo*)config;

- (BOOL) updateVideo:(NSString*)Id withPath:(NSString*) path andConfig:(TUPEvaReplaceConfig_ImageOrVideo*)config;

- (BOOL) updateAudio:(NSString*)Id withPath:(NSString*) path andConfig:(TUPEvaReplaceConfig_Audio*)config;


- (TUPPlayer*) newPlayer;
- (void) resetPlayer;

- (TUPProducer*) newProducer;
- (void) resetProducer;

- (NSInteger) getDuration;




@end

NS_ASSUME_NONNULL_END
