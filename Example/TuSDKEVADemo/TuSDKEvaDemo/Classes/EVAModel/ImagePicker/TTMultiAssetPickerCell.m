//
//  TTMultiAssetPickerCell.m
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2022/7/22.
//  Copyright © 2022 TuSdk. All rights reserved.
//

#import "TTMultiAssetPickerCell.h"
#import "CustomTouchBoundsButton.h"

static const CGFloat kTimeLabelHeight = 16;

@interface TTMultiAssetPickerCell()

@property (nonatomic, strong) UIImageView *imageView;

@property (nonatomic, strong) CustomTouchBoundsButton *selectButton;
/// 时间label
@property (nonatomic, strong) UILabel *timeLabel;
/// 已选择标签
@property (nonatomic, strong) UILabel *tagLabel;

/**
 底部背景视图
 */
@property (nonatomic, strong) UIView *bottomMaskView;

@end

@implementation TTMultiAssetPickerCell

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        [self commonInit];
    }
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_imageView];
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    _imageView.clipsToBounds = YES;
    
    _selectButton = [CustomTouchBoundsButton buttonWithType:UIButtonTypeCustom];
    [self.contentView addSubview:_selectButton];
    [_selectButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
//    [_selectButton setBackgroundImage:[UIImage imageNamed:@"edit_checkbox_sel"] forState:UIControlStateSelected];
//    [_selectButton setBackgroundImage:[UIImage imageNamed:@"edit_checkbox_unsel"] forState:UIControlStateNormal];
    [_selectButton setBackgroundImage:[UIImage imageNamed:@"style_add"] forState:UIControlStateNormal];
    _selectButton.backgroundColor = [UIColor colorWithRed:213.f / 255 green:213.f / 255 blue:213.f / 255 alpha:1];
    _selectButton.layer.cornerRadius = 10;
    _selectButton.titleLabel.font = [UIFont systemFontOfSize:11];
    [_selectButton addTarget:self action:@selector(selectButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    _bottomMaskView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_bottomMaskView];
//    _bottomMaskView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    
    _timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_timeLabel];
    _timeLabel.textColor = [UIColor whiteColor];
    _timeLabel.font = [UIFont systemFontOfSize:11];
    _timeLabel.textAlignment = NSTextAlignmentRight;
    
    _tagLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.contentView addSubview:_tagLabel];
    _tagLabel.backgroundColor = [UIColor colorWithWhite:1 alpha:0.7];
    _tagLabel.text = @"已选择";
    _tagLabel.layer.cornerRadius = 3;
    _tagLabel.layer.masksToBounds = YES;
    _tagLabel.textColor = [UIColor blackColor];
    _tagLabel.font = [UIFont systemFontOfSize:10];
    _tagLabel.textAlignment = NSTextAlignmentCenter;
    _tagLabel.hidden = YES;
}

- (void)layoutSubviews {
    
    CGFloat width = CGRectGetWidth(self.contentView.bounds);
    CGFloat height = CGRectGetHeight(self.contentView.bounds);
    
    _imageView.frame = self.contentView.frame;
    _selectButton.frame = CGRectMake(width - 26, 6, 20, 20);
    
    _bottomMaskView.frame = CGRectMake(0, height - kTimeLabelHeight, width, kTimeLabelHeight);
    _timeLabel.frame = CGRectMake(kTimeLabelHeight / 2, height - kTimeLabelHeight, width - kTimeLabelHeight, kTimeLabelHeight);
    _tagLabel.frame = CGRectMake(4, 6, 40, 20);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imageView.image = nil;
    self.selectButton.selected = NO;
}

-(void)setAsset:(PHAsset *)asset;{
    _asset = asset;
    __weak typeof(self) weak_cell = self;
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    CGSize targetSize = CGSizeMake(CGRectGetWidth(weak_cell.contentView.bounds), CGRectGetHeight(weak_cell.contentView.bounds));
    
    switch (asset.mediaType) {
        case PHAssetMediaTypeVideo:
        case PHAssetMediaTypeAudio:
            weak_cell.duration = asset.duration;
            break;
        default:
            weak_cell.duration = -1;
            break;
    }
    
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        weak_cell.imageView.image = result;
    }];
}

/**
 根据给定的时间创建时间字符串
 
 @param timeInterval 秒
 @return 时间字符串
 */
+ (NSString *)textWithTimeInterval:(NSTimeInterval)timeInterval {
    if (isnan(timeInterval) || timeInterval < 0) return @"图片";
    NSInteger time = (NSInteger)(timeInterval + .5);
    NSInteger hours = time / 60 / 60;
    NSInteger minutes = (time / 60) % 60;
    NSInteger seconds = time % 60;
    NSString *text = @"";
    if (hours > 0) {
        text = [text stringByAppendingFormat:@"%02zd", hours];
    }
    text = [text stringByAppendingFormat:@"%02zd:%02zd", minutes, seconds];
    return text;
}

#pragma mark - property

- (void)setDuration:(NSTimeInterval)duration {
    _duration = duration;
    _timeLabel.text = [self.class textWithTimeInterval:duration];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    _selectedIndex = selectedIndex;
    [_selectButton setTitle:@(_selectedIndex+1).description forState:UIControlStateSelected];
}

#pragma mark - action

/**
 选中按钮事件

 @param sender 点击的按钮
 */
- (void)selectButtonAction:(UIButton *)sender {
    if (self.selectButtonActionHandler) self.selectButtonActionHandler(self, sender);
    //_tagLabel.hidden = NO;
}

@end
