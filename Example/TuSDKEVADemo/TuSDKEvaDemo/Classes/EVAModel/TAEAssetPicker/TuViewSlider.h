/********************************************************
 * @file    : TuViewSlider.h
 * @project : TuSDKVideoDemo
 * @author  : Copyright © http://tutucloud.com/
 * @date    : 2020-08-01
 * @brief   : 页面切换控件
*********************************************************/

#import <UIKit/UIKit.h>

@protocol ViewSliderDataSource, ViewSliderDelegate;

@interface TuViewSlider : UIView

@property (nonatomic, weak) IBOutlet id<ViewSliderDataSource> dataSource;

@property (nonatomic, weak) IBOutlet id<ViewSliderDelegate> delegate;

@property (nonatomic, strong, readonly) UIView *currentView; // 当前视图

@property (nonatomic, assign) NSInteger selectedIndex; // 选中索引

@property (nonatomic, assign) BOOL disableSlide; // 引用手势滑动切换

@end


@protocol ViewSliderDataSource <NSObject>
- (NSInteger)numberOfViewsInSlider:(TuViewSlider *)slider;
- (UIView *)viewSlider:(TuViewSlider *)slider viewAtIndex:(NSInteger)index;
@end


@protocol ViewSliderDelegate <NSObject>
- (void)viewSlider:(TuViewSlider *)slider switchingFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex progress:(CGFloat)progress;
- (void)viewSlider:(TuViewSlider *)slider didSwitchToIndex:(NSInteger)index;
- (void)viewSlider:(TuViewSlider *)slider didSwitchBackIndex:(NSInteger)index;

@end

