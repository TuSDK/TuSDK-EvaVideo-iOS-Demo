//
//  TuMaskRegionView.m
//  TuSDK
//
//  Created by Clear Hu on 14/12/17.
//  Copyright (c) 2014年 tusdk.com. All rights reserved.
//

#import "TuMaskRegionView.h"
#import "TuSDKPulseCore.h"
/**
 *  裁剪区域视图
 */
@interface TuMaskRegionView(){
    // 动画对象
    TuTSAnimation *_anim;
    // 目标区域
    CGRect _toRect;
    // 相差区域
    CGRect _reduceRect;
}

/**
 *  动画对象
 */
@property (nonatomic, retain)TuTSAnimation *anim;
@end

@implementation TuMaskRegionView
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self lsqInitView];
    }
    return self;
}
/**
 *  初始化视图
 */
- (void)lsqInitView;
{
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = NO;
    // 边缘覆盖区域颜色
    _edgeMaskColor = lsqRGBA(0, 0, 0, 0.5);;
    // 边缘线颜色
    _edgeSideColor = [UIColor clearColor];
    // 边缘线宽度
    _edgeSideWidth = 0;
}

/**
 *  更新布局
 */
- (void)needUpdateLayout;
{
    self.regionRatio = self.regionRatio;
}

// 动画对象
-(TuTSAnimation *)anim;
{
    if (!_anim){
        _anim = [TuTSAnimation animWithDuration:0.26
                                             tween:[TuTweenQuintEaseOut tween]
                                             block:^(TuTSAnimation *anim, NSTimeInterval step) {
                                                 [self applyAnimationWithStep:step];
        }];
    }
    return _anim;
}

/**
 *  执行动画步骤
 *
 *  @param step 步进值 0-1
 */
- (void)applyAnimationWithStep:(NSTimeInterval)step;
{
    step = 1 - step;
    _regionRect = CGRectMake(_toRect.origin.x - _reduceRect.origin.x * step,
                             _toRect.origin.y - _reduceRect.origin.y * step,
                             _toRect.size.width - _reduceRect.size.width * step,
                             _toRect.size.height - _reduceRect.size.height * step);
    [self setNeedsDisplay];
}

/**
 *  改变范围比例 (使用动画)
 *
 *  @param regionRatio 范围比例
 *
 *  @return 确定的选取方位
 */
- (CGRect)changeRegionRatio:(CGFloat)regionRatio;
{
    if (_regionRatio == regionRatio) return _reduceRect;
    _regionRatio = regionRatio;
    
    CGFloat alpha = regionRatio > 0 ? 1 : 0;

    [UIView animateWithDuration:0.26 animations:^{
        self.alpha = alpha;
    }];
    
    // 目标区域
    _toRect = [self convertScaleAspectFitWithRatio:_regionRatio];

    _reduceRect = CGRectMake(_toRect.origin.x - _regionRect.origin.x,
                             _toRect.origin.y - _regionRect.origin.y,
                             _toRect.size.width - _regionRect.size.width,
                             _toRect.size.height - _regionRect.size.height);
    
    [self.anim start];

    return _toRect;
}

/**
 *  区域长宽比例
 *
 *  @param regionRatio 区域长宽比例
 */
- (void)setRegionRatio:(CGFloat)regionRatio;
{
    _regionRatio = regionRatio;
    
    if (_regionRatio > 0) {
        self.alpha = 100;
    }else{
        self.alpha = 0;
    }

    // 选区信息
    _regionRect = [self convertScaleAspectFitWithRatio:_regionRatio];

    [self setNeedsDisplay];
}

// 绘制选区视图
-(void)drawRect:(CGRect)rect;
{
    if (CGRectIsEmpty(_regionRect)) return;

    if (_edgeMaskColor) {
        // 绘制背景
        [_edgeMaskColor setFill];
        UIRectFill(self.bounds);
    }
    
    // 绘制镂空区域
    [[UIColor clearColor] setFill];
    UIRectFill(_regionRect);
    
    float mid = _edgeSideWidth * 0.5f;
    
    // 绘制边缘框
    if (_edgeSideColor && _edgeSideWidth > 0) {
        [_edgeSideColor setStroke];
        UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(_regionRect.origin.x + mid, _regionRect.origin.y + mid, _regionRect.size.width - _edgeSideWidth, _regionRect.size.height - _edgeSideWidth)];
        path.lineWidth = _edgeSideWidth;
        //填充矩形
        [path stroke];
    }

}

- (void)viewWillDestory;
{
    if (_anim) {
        [_anim destory];
        _anim = nil;
    }
}
@end
