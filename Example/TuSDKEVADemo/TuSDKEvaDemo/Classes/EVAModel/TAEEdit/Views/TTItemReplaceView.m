//
//  TTItemReplaceView.m
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2022/6/15.
//  Copyright © 2022 TuSdk. All rights reserved.
//

#import "TTItemReplaceView.h"
#import "TuSDKFrameWork.h"
@implementation TTItemReplaceView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setupView];
    }
    return self;
}

- (void)setupView;
{
    self.backgroundColor = [UIColor whiteColor];
    self.layer.cornerRadius = 5;
    
    CGFloat width = CGRectGetWidth(self.frame);
    
    UIView *replaceView = [self setupViewWithImageName:@"icon_replace" title:@"替换" index:TTItemEditTypeReplace];
    [self addSubview:replaceView];
    [replaceView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.top.bottom.offset(0);
        make.width.mas_equalTo(width / 2);
    }];
    
    UIView *cropView = [self setupViewWithImageName:@"icon_crop" title:@"裁剪" index:TTItemEditTypeCrop];
    [self addSubview:cropView];
    [cropView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.right.top.bottom.offset(0);
        make.width.mas_equalTo(width / 2);
    }];
    
}

//创建默认视图
- (UIView *)setupViewWithImageName:(NSString *)imageName title:(NSString *)title index:(NSInteger)index
{
    UIView *view = [[UIView alloc] init];
    view.tag = index;
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    [view addSubview:imageView];
    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.centerX.mas_equalTo(view);
        make.bottom.mas_equalTo(view.mas_centerY);
        make.width.height.mas_equalTo(20);
    }];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.font = [UIFont systemFontOfSize:10];
    [view addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.right.offset(0);
        make.top.mas_equalTo(imageView.mas_bottom).offset(5);
    }];
    
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewGestureAction:)];
    [view addGestureRecognizer:gestureRecognizer];

    
    return view;
}

- (void)viewGestureAction:(UITapGestureRecognizer *)gesture
{
    UIView *view = gesture.view;
    NSLog(@"TT:当前操作页面点选动作===%ld", (long)view.tag);
    if ([self.delegate respondsToSelector:@selector(itemReplaceView:editType:)]) {
        [self.delegate itemReplaceView:self editType:view.tag];
    }
}

@end
