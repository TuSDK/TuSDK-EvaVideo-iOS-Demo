//
//  TAEWaveProgress.m
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2021/12/14.
//  Copyright © 2021 TuSdk. All rights reserved.
//

#import "TAEWaveProgress.h"
#import "TAEWave.h"

@interface TAEWaveProgress()
{
    TAEWave *_wave;
    UILabel *_progressLabel;
}

@end

@implementation TAEWaveProgress

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self buildDefaultView];
    }
    return self;
}

- (void)buildDefaultView
{
    _wave = [[TAEWave alloc] initWithFrame:self.bounds];
    _wave.center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    [self addSubview:_wave];
    
    _progressLabel = [[UILabel alloc] initWithFrame:self.bounds];
    _progressLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:_progressLabel];
}

#pragma mark - setter
- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    _wave.progress = progress;
    _progressLabel.text = [NSString stringWithFormat:@"%.0f%%", progress * 100];
}

- (void)setTextFont:(UIFont *)textFont
{
    _progressLabel.font = textFont;
}

- (void)setTextColor:(UIColor *)textColor
{
    _progressLabel.textColor = textColor;
}

- (void)setWaveBackgroundColor:(UIColor *)waveBackgroundColor
{
    _wave.waveBackgroundColor = waveBackgroundColor;
}

- (void)setBackWaveColor:(UIColor *)backWaveColor
{
    _wave.backWaveColor = backWaveColor;
}

- (void)setFrontWaveColor:(UIColor *)frontWaveColor
{
    _wave.frontWaveColor = frontWaveColor;
}

#pragma mark - method
- (void)start
{
    [_wave start];
}

- (void)stop
{
    [_wave stop];
}

- (void)dealloc
{
    [_wave stop];
    for (UIView *view in self.subviews)
    {
        [view removeFromSuperview];
    }
}

@end
