/********************************************************
 * @file    : TuPanelBar.h
 * @project : TuSDKVideoDemo
 * @author  : Copyright © http://tutucloud.com/
 * @date    : 2020-08-01
 * @brief   : 组合面板标签栏
*********************************************************/
#import <UIKit/UIKit.h>


@class TuPanelBar;

@protocol TuPanelTabbarDelegate <NSObject>
@optional
- (void)panelBar:(TuPanelBar *)bar didSwitchFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
- (BOOL)panelBar:(TuPanelBar *)bar canSwitchFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
@end


@interface TuPanelBar : UIControl
@property (nonatomic, strong) NSArray *itemTitles; //  标签栏各项标题
@property (nonatomic, strong) UIFont *itemTitleFont; // 标签项字体
@property (nonatomic, assign) CGFloat itemWidth; // 标签项宽度，默认 -1，设置 -1 则根据标签项内容自适应宽度
@property (nonatomic, assign) CGFloat itemsSpacing; // 标签栏各项间的间隔
@property (nonatomic, strong) UIColor *itemNormalColor; // 标签项正常显示状态的颜色
@property (nonatomic, strong) UIColor *itemSelectedColor; // 标签项选中状态的颜色
@property (nonatomic, assign) CGSize trackerSize; // 标签栏标记游标尺寸

@property (nonatomic, assign) NSInteger selectedIndex; // 选中索引，设置其值可更新 UI

@property (nonatomic, weak) id<TuPanelTabbarDelegate> delegate;

- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated;

@end


