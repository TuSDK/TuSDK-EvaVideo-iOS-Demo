//
//  TAEWave.m
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2021/12/14.
//  Copyright © 2021 TuSdk. All rights reserved.
//

#import "TAEWave.h"

@interface TAEWave()
{
    //前层波浪
    CAShapeLayer *_backWaveLayer;
    //后层波浪
    CAShapeLayer *_frontWaveLayer;
    //定时刷新器
    CADisplayLink *_timeDisplayLink;
    //曲线振幅
    CGFloat _waveAmplitude;
    //曲线角速度
    CGFloat _wavePalstance;
    //曲线坐标
    CGFloat _waveX;
    CGFloat _waveY;
    //曲线移动速度
    CGFloat _waveMoveSpeed;
}

@end

@implementation TAEWave

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self buildDefaultView];
        [self buildWaveConfig];
    }
    return self;
}

//创建默认视图
- (void)buildDefaultView
{
    //初始化
    _backWaveLayer = [[CAShapeLayer alloc] init];
    _frontWaveLayer = [[CAShapeLayer alloc] init];
    
    [self.layer addSublayer:_backWaveLayer];
    [self.layer addSublayer:_frontWaveLayer];
    
    self.layer.cornerRadius = self.bounds.size.width / 2;
    self.layer.masksToBounds = YES;
}

//配置数据
- (void)buildWaveConfig
{
    //振幅
    _waveAmplitude = 10;
    //角速度
    _wavePalstance = M_PI / self.bounds.size.width;
    //坐标
    _waveX = 0;
    _waveY = self.bounds.size.height;
    //x轴移动速度
    _waveMoveSpeed = _wavePalstance * 1.5;
}

- (void)updateWave:(CADisplayLink *)link
{
    _waveX += _waveMoveSpeed;
    [self updateWaveY];
    [self updateWave1];
    [self updateWave2];
}

//更新偏距的大小 直到达到目标偏距 让wave有一个匀速增长的效果
- (void)updateWaveY
{
    CGFloat targetY = self.bounds.size.height - _progress * self.bounds.size.height;
    if (_waveY < targetY) {
        _waveY += 2;
    }
    if (_waveY > targetY ) {
        _waveY -= 2;
    }
}

- (void)updateWave1
{
    //波浪宽度
    CGFloat waterWaveWidth = self.bounds.size.width;
    //初始化运动路径
    CGMutablePathRef path = CGPathCreateMutable();
    //设置起始位置
    CGPathMoveToPoint(path, nil, 0, _waveY);
    //初始化波浪其实Y为偏距
    CGFloat y = _waveY;
    //正弦曲线公式为： y=Asin(ωx+φ)+k;
    for (float x = 0.0f; x <= waterWaveWidth ; x++) {
        y = _waveAmplitude * cos(_wavePalstance * x + _waveX) + _waveY;
        CGPathAddLineToPoint(path, nil, x, y);
    }
    //填充底部颜色
    CGPathAddLineToPoint(path, nil, waterWaveWidth, self.bounds.size.height);
    CGPathAddLineToPoint(path, nil, 0, self.bounds.size.height);
    CGPathCloseSubpath(path);
    _backWaveLayer.path = path;
    CGPathRelease(path);
}

- (void)updateWave2
{
    //波浪宽度
    CGFloat waterWaveWidth = self.bounds.size.width;
    //初始化运动路径
    CGMutablePathRef path = CGPathCreateMutable();
    //设置起始位置
    CGPathMoveToPoint(path, nil, 0, _waveY);
    //初始化波浪其实Y为偏距
    CGFloat y = _waveY;
    //正弦曲线公式为： y=Asin(ωx+φ)+k;
    for (float x = 0.0f; x <= waterWaveWidth ; x++) {
        y = _waveAmplitude * sin(_wavePalstance * x + _waveX) + _waveY;
        CGPathAddLineToPoint(path, nil, x, y);
    }
    //添加终点路径、填充底部颜色
    CGPathAddLineToPoint(path, nil, waterWaveWidth, self.bounds.size.height);
    CGPathAddLineToPoint(path, nil, 0, self.bounds.size.height);
    CGPathCloseSubpath(path);
    _frontWaveLayer.path = path;
    CGPathRelease(path);
    
}

#pragma mark - setter
- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
}

- (void)setWaveBackgroundColor:(UIColor *)waveBackgroundColor
{
    self.backgroundColor = waveBackgroundColor;
}

- (void)setBackWaveColor:(UIColor *)backWaveColor
{
    _backWaveLayer.fillColor = backWaveColor.CGColor;
    _backWaveLayer.strokeColor = backWaveColor.CGColor;
}

- (void)setFrontWaveColor:(UIColor *)frontWaveColor
{
    _frontWaveLayer.fillColor = frontWaveColor.CGColor;
    _frontWaveLayer.strokeColor = frontWaveColor.CGColor;
}

#pragma mark -
#pragma mark 功能方法

//开始
- (void)start
{
    //以屏幕刷新速度为周期刷新曲线的位置
    _timeDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateWave:)];
    [_timeDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

//停止
- (void)stop
{
    if (_timeDisplayLink) {
        [_timeDisplayLink invalidate];
        _timeDisplayLink = nil;
    }
}


- (void)dealloc
{
    [self stop];
    if (_backWaveLayer) {
        [_backWaveLayer removeFromSuperlayer];
        _backWaveLayer = nil;
    }
    if (_frontWaveLayer) {
        [_frontWaveLayer removeFromSuperlayer];
        _frontWaveLayer = nil;
    }
}



@end
