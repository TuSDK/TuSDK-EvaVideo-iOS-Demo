//
//  TUPDynEvaDirector.h
//  TuSDKPulseEva
//
//  Created by 言有理 on 2022/4/11.
//  Copyright © 2022 tusdk.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TuSDKPulse/TUPBase.h>
#import <TuSDKPulse/TUPPlayer.h>
#import <TuSDKPulse/TUPProducer.h>

#import "TuSDKPulseEva/TUPEvaModel.h"
NS_ASSUME_NONNULL_BEGIN

@interface TUPDynEvaDirectorPlayer : TUPPlayer
- (instancetype) initWithImpl:(void*) impl;
- (BOOL) open;
@end


@interface TUPDynEvaDirectorProducer : TUPProducer
- (instancetype) initWithImpl:(void*) impl;
- (BOOL) open;
@end


@interface TUPDynEvaDirector : TUPBase

- (BOOL)openModel:(TUPEvaModel*)model;

- (BOOL)updateResource:(NSArray <TUPEvaReplaceConfig_ImageOrVideo *>*)configList;

- (BOOL)updateAudioPath:(nullable NSString *)audioPath;

- (void)close;

- (TUPPlayer*) newPlayer;
- (void) resetPlayer;

- (TUPProducer*) newProducer;
- (void) resetProducer;

- (NSInteger) getDuration;




@end
NS_ASSUME_NONNULL_END
