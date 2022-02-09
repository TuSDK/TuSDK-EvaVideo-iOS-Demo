//
//  TuTouchImageView.m
//  TuSDK
//
//  Created by Clear Hu on 15/1/5.
//  Copyright (c) 2015年 tusdk.com. All rights reserved.
//

#import "TuTouchImageView.h"
//#import "TuSDKPulseCore/tools/TuTSBundle.h"
//#import "TuSDKPulseCore/tools/TuTSScreen+Extend.h"
//#import "TuSDKPulseCore/secrets/TuStatistics.h"
//#import "TuSDKPulseCore/tools/TuTSLog.h"
#import "TuSDKPulseCore.h"
/**
 *  图片编辑视图 (旋转，缩放)
 */
@implementation TuTouchImageView
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
    // lsqLDebug(@"lsqInitView: %@", NSStringFromCGRect(self.frame));
    // 包装视图
    _wrapView = [UIScrollView initWithFrame:self.bounds];
    _wrapView.multipleTouchEnabled = YES;
    _wrapView.delegate = self;
    _wrapView.showsHorizontalScrollIndicator = NO;
    _wrapView.showsVerticalScrollIndicator = NO;
    _wrapView.alwaysBounceVertical = YES;
    _wrapView.alwaysBounceHorizontal = YES;
    // PS：必须以原始图片视图大小作为缩放标准,既_wrapView.zoomScale = _wrapView.minimumZoomScale必须从1开始
    // 否则会加大计算难度
    _wrapView.zoomScale = _wrapView.minimumZoomScale = 1.0;
    _wrapView.maximumZoomScale = 3.0;
    [self addSubview:_wrapView];
    
    // 图片包装类 (处理缩放)
    _imageWrapView = [UIView initWithFrame:_wrapView.bounds];
    [_wrapView addSubview:_imageWrapView];
    
    // 图片视图
    _imageView = [UIImageView initWithFrame:_wrapView.bounds];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    //_imageView.backgroundColor = lsqRGB(56, 45, 211);
    [_imageWrapView addSubview:_imageView];
    [self bindDoubelCilck];
}

// 图片方向
-(UIImageOrientation)imageOrientation;
{
    return _imageView.image.imageOrientation;
}

// 缩放倍数
-(CGFloat)zoomScale;
{
    return _wrapView.zoomScale;
}

/**
 *  更新布局
 */
- (void)needUpdateLayout;
{
    _wrapView.frame = self.bounds;
    _imageWrapView.frame = self.bounds;
    _imageView.frame = self.bounds;
    if (_cutRegionView) {
        _cutRegionView.frame = self.bounds;
        [_cutRegionView needUpdateLayout];
    }
}

// 绑定双击放大缩小事件
- (void)bindDoubelCilck;
{
    UITapGestureRecognizer *doubelGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleGesture:)];
    doubelGesture.numberOfTapsRequired = 2;
    [_wrapView addGestureRecognizer:doubelGesture];
}

// 处理双击手势
- (void)doubleGesture:(id)sender;
{
    if (_wrapView.zoomScale == _wrapView.minimumZoomScale) {
        [_wrapView setZoomScale:_wrapView.maximumZoomScale animated:YES];
    }else{
        [_wrapView setZoomScale:_wrapView.minimumZoomScale animated:YES];
    }
}

/**
 *  旋转和裁剪 裁剪区域视图
 *
 *  @return 旋转和裁剪 裁剪区域视图
 */
-(TuMaskRegionView *)cutRegionView;
{
    if (!_cutRegionView) {
        _cutRegionView = [TuMaskRegionView initWithFrame:_wrapView.bounds];
        [self insertSubview:_cutRegionView aboveSubview:_wrapView];

        // 边缘线颜色
        _cutRegionView.edgeSideColor = lsqRGBA(255, 255, 255, 0.5);
        // 边缘线宽度
        _cutRegionView.edgeSideWidth = 2;
    }
    return _cutRegionView;
}

/**
 *  设置区域长宽比例
 *
 *  @param regionRatio 区域长宽比例
 */
- (void)setRegionRatio:(CGFloat)regionRatio;
{
    _regionRatio = regionRatio;
    self.cutRegionView.regionRatio = _regionRatio;
}

/**
 *  设置图片
 *
 *  @param image           图片
 *  @param orginDirectionX 原图是否为横向图片
 */
- (void)setImage:(UIImage *)image;
{
    if (!image) return;
    
    CGRect contentRect = [self contentRectWithSize:image.size];
    [_imageView lsqSetSize:contentRect.size];
    [_imageWrapView lsqSetSize:contentRect.size];
    
    _imageView.image = image;
}

/**
 *  计算内容位置
 *
 *  @param size 内容长宽
 *
 *  @return 内容位置
 */
- (CGRect)contentRectWithSize:(CGSize)size;
{
    CGRect regionRect = CGRectZero;
    
    if (self.regionRatio > 0) {
        regionRect = self.cutRegionView.regionRect;
    }
    return [self contentRectWithSize:size regionRect:regionRect];
}

/**
 *  计算内容位置
 *
 *  @param size       内容长宽
 *  @param regionRect 选取比例
 *
 *  @return 内容位置
 */
- (CGRect)contentRectWithSize:(CGSize)size regionRect:(CGRect)regionRect;
{
    CGRect contentRect = CGRectZero;
    // 开启裁剪
    if (!CGRectIsEmpty(regionRect)){
        // 内容选区
        contentRect = [UIView convertViewSize:regionRect.size scaleAspectFillWithSize:size];
        // top, left, bottom, right
        _wrapView.contentInset = UIEdgeInsetsMake(regionRect.origin.y, regionRect.origin.x, regionRect.origin.y, regionRect.origin.x);
        _wrapView.contentOffset = CGPointMake((contentRect.size.width - regionRect.size.width) * 0.5 - regionRect.origin.x,
                                              (contentRect.size.height - regionRect.size.height) * 0.5 - regionRect.origin.y);
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
    }else{
        contentRect = [_wrapView convertScaleAspectFitWithSize:size];
        // top, left, bottom, right
        _wrapView.contentInset = UIEdgeInsetsMake(contentRect.origin.y, contentRect.origin.x, contentRect.origin.y, contentRect.origin.x);
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    _wrapView.contentSize = contentRect.size;
    
    return contentRect;
}

#pragma mark - changeRegionRatio
/**
 *  改变图片区域长宽比例
 *
 *  @param regionRatio 图片区域长宽比例
 */
- (void)changeRegionRatio:(CGFloat)regionRatio;
{
    if (_isInAniming || regionRatio == self.regionRatio) return;
    
    _regionRatio = regionRatio;
    
    [self setAnimingState:YES];
    
    CGRect regionRect = [self.cutRegionView changeRegionRatio:regionRatio];
    if (_regionRatio <= 0)
    {
        regionRect = CGRectZero;
    }

    [UIView animateWithDuration:0.3 animations:^{
        _wrapView.zoomScale = _wrapView.minimumZoomScale;
        
        CGRect contentRect = [self contentRectWithSize:_imageView.image.size regionRect:regionRect];
        // 当图片长宽不变时，设置图片视图缩放会失败
        if (CGSizeEqualToSize(contentRect.size, _imageView.lsqGetSize)) {
            [_imageView lsqSetSize:CGSizeMake(contentRect.size.width + 0.01f, contentRect.size.height + 0.01f)];
        }
        [_imageView lsqSetSize:contentRect.size];
        [_imageWrapView lsqSetSize:contentRect.size];
        
    } completion:^(BOOL finished) {
        
        [self setAnimingState:NO];
    }];
}

#pragma mark - changeImage
/**
 *  改变图片方向
 *
 *  @param changed 图片方向改变
 */
- (void)changeImage:(lsqImageChange)changed;
{
    if (_isInAniming) return;
    [self setAnimingState:YES];
    
    [UIView animateWithDuration:0.3 animations:^{
        _wrapView.zoomScale = _wrapView.minimumZoomScale;
        switch (changed) {
            case lsqImageChangeTurnLeft:
                [self resizeWithTrun: YES];
                break;
            case lsqImageChangeTurnRight:
                [self resizeWithTrun: NO];
                break;
            case lsqImageChangeMirrorHorizontal:
                [self mirrorWithHorizontal: YES];
                break;
            case lsqImageChangeMirrorVertical:
                [self mirrorWithHorizontal: NO];
                break;
            default:
                break;
        }
    } completion:^(BOOL finished) {
        switch (changed) {
            case lsqImageChangeTurnLeft:
                [self resizeCompletedWithTrun: YES];
                break;
            case lsqImageChangeTurnRight:
                [self resizeCompletedWithTrun: NO];
                break;
            case lsqImageChangeMirrorHorizontal:
                [self mirrorCompletedWithHorizontal:YES];
                break;
            case lsqImageChangeMirrorVertical:
                [self mirrorCompletedWithHorizontal:NO];
                break;
            default:
                break;
        }
        [self setAnimingState:NO];
    }];
    
    [self appendStatistics:changed];
}

// 加入统计
- (void)appendStatistics:(lsqImageChange)changed;
{
    NSInteger actType = 0;
    switch (changed) {
        case lsqImageChangeTurnLeft:
            actType = tkc_editCuter_action_trun_left;
            break;
        case lsqImageChangeTurnRight:
            actType = tkc_editCuter_action_trun_right;
            break;
        case lsqImageChangeMirrorHorizontal:
            actType = tkc_editCuter_action_mirror_horizontal;
            break;
        case lsqImageChangeMirrorVertical:
            actType = tkc_editCuter_action_mirror_vertical;
            break;
        default:
            break;
    }
    if (actType != 0) {
        // sdk统计代码，请不要加入您的应用
        [TuStatistics appendWithComponentIdt:actType];
    }
}

// 设置滤镜视图禁用状态
// 当图形正处于旋转和缩放状态时，需要禁用，否则会造成图形方向错误
- (void)setAnimingState:(BOOL)isInAniming;
{
    _isInAniming = isInAniming;
    if (self.delegate) {
        [self.delegate onTuSDKICTouchImageView:self inAniming:_isInAniming];
    }
}

/**
 *  旋转时重置长宽
 *
 *  @param isLeft 是否向左旋转
 */
- (void)resizeWithTrun:(BOOL)isLeft;
{
    CGRect contentRect = [self contentRectWithSize:CGSizeMake(_imageView.lsqGetSize.height, _imageView.lsqGetSize.width)];
    CGFloat pi = isLeft ? -M_PI : M_PI;
    
    _imageView.transform = CGAffineTransformMakeRotation(pi * 0.5);
    _imageView.frame = CGRectMake(0, 0, contentRect.size.width, contentRect.size.height);
    
    //[self logDebug:@"resizeWithTrun"];
}

/**
 *  旋转完成
 *
 *  @param isLeft 是否向左旋转
 */
- (void)resizeCompletedWithTrun:(BOOL)isLeft;
{
    _imageView.transform = CGAffineTransformIdentity;
    if (isLeft) {
        _imageView.image = [_imageView.image lsqChangeTurnLeft];
    }else{
        _imageView.image = [_imageView.image lsqChangeTurnRight];
    }
    
    [_imageView lsqSetSize:CGSizeMake(_imageView.lsqGetSizeHeight, _imageView.lsqGetSizeWidth)];
    [_imageView lsqSetOrigin:CGPointZero];
    [_imageWrapView lsqSetSize:_imageView.lsqGetSize];
}

/**
 *  水平镜像
 *
 *  @param isHorizontal 是否水平镜像
 */
- (void)mirrorWithHorizontal:(BOOL)isHorizontal;
{
    CATransform3D rotationAndPerspectiveTransform;
    if (isHorizontal) {
        rotationAndPerspectiveTransform = CATransform3DMakeRotation(M_PI, 0.0f, 1.0f, 0.0f);
    }else{
        rotationAndPerspectiveTransform = CATransform3DMakeRotation(M_PI, 1.0f, 0.0f, 0.0f);
    }
    
    rotationAndPerspectiveTransform.m34 = 1.0 / -500.0;
    
    [self contentRectWithSize:_imageView.lsqGetSize];
    _imageView.layer.transform = rotationAndPerspectiveTransform;
}

/**
 *  水平镜像完成
 *
 *  @param isHorizontal 是否水平镜像
 */
- (void)mirrorCompletedWithHorizontal:(BOOL)isHorizontal;
{
    _imageView.layer.transform = CATransform3DIdentity;
    if (isHorizontal) {
        [_imageView setImage:[_imageView.image lsqChangeMirrorHorizontal]];
    }else{
        [_imageView setImage:[_imageView.image lsqChangeMirrorVertical]];
    }
}

#pragma mark - UIScrollViewDelegate
-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView;
{
    // [self logDebug:@"Zooming"];
    return _imageWrapView;
}

//- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
//{
//    [self logDebug:@"Scrolling"];
//}

// 打印调试信息
- (void)logDebug:(NSString *)funcName;
{
    lsqLDebug(@"%@ \r1-imageView: %@ \r2-imageWrapView:%@ \r3-contentSize: %@ \r4-contentInset: %@ \r5-contentOffset: %@ \r",
              funcName,
              NSStringFromCGRect(_imageView.frame),
              NSStringFromCGRect(_imageWrapView.frame),
              NSStringFromCGSize(_wrapView.contentSize),
              NSStringFromUIEdgeInsets(_wrapView.contentInset),
              NSStringFromCGPoint(_wrapView.contentOffset));
}

/**
 *  是否正在动作
 *
 *  @return 是否正在动作
 */
- (BOOL)inActioning;
{
    return _isInAniming || _wrapView.inActioning;
}

/**
 *  计算图片裁剪区域百分比
 *
 *  @return 图片裁剪区域百分比
 */
- (CGRect)countImageCutRect;
{
    CGRect rect = CGRectZero;
    
    if (self.regionRatio <= 0 || !_cutRegionView) return rect;
    
    rect.size.width = _imageView.lsqGetSizeWidth * _wrapView.zoomScale;
    rect.size.height = _imageView.lsqGetSizeHeight * _wrapView.zoomScale;
    
    rect.origin.x = (_wrapView.contentOffset.x + _wrapView.contentInset.left) / rect.size.width;
    rect.origin.y = (_wrapView.contentOffset.y + _wrapView.contentInset.top) / rect.size.height;
    
    rect.size.width = _cutRegionView.regionRect.size.width / rect.size.width;
    rect.size.height = _cutRegionView.regionRect.size.height / rect.size.height;
    
    return rect;
}

/**
 *  恢复图片缩放选区位置
 *
 *  @param zoomRect  缩放选区
 *  @param zoomScale 缩放倍数
 */
- (void)restoreWithZoomRect:(CGRect)zoomRect zoomScale:(CGFloat)zoomScale;
{
    if (CGRectIsEmpty(zoomRect))return;
    
    _wrapView.zoomScale = zoomScale;
    
    CGFloat width = _imageView.lsqGetSizeWidth * zoomScale;
    CGFloat heigth = _imageView.lsqGetSizeHeight * zoomScale;
    
    CGFloat offsetX = zoomRect.origin.x * width - _wrapView.contentInset.left;
    CGFloat offsetY = zoomRect.origin.y * heigth - _wrapView.contentInset.top;
    
    _wrapView.contentOffset = CGPointMake(offsetX, offsetY);
}

@end
