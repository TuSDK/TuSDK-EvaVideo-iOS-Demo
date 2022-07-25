//
//  TTMutiAssetPickSelectCell.m
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2022/6/8.
//  Copyright © 2022 TuSdk. All rights reserved.
//

#import "TTMutiAssetPickSelectCell.h"
#import "TuSDKFrameWork.h"

@interface TTMutiAssetPickSelectCell()
/// 展示图
@property (nonatomic, strong) UIImageView *thumbImageView;
/// 时间控件
@property (nonatomic, strong) UILabel *timeLabel;
/// 标签控件
@property (nonatomic, strong) UILabel *tagLabel;
/// 编辑标签
@property (nonatomic, strong) UILabel *editLabel;

@end

@implementation TTMutiAssetPickSelectCell

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initWithSubViews];
    }
    return self;
}

- (void)initWithSubViews
{
    self.thumbImageView = [[UIImageView alloc] init];
    self.thumbImageView.backgroundColor = [UIColor lsqClorWithHex:@"#272731"];
    self.thumbImageView.layer.masksToBounds = YES;
    self.thumbImageView.layer.cornerRadius = 5;
    self.thumbImageView.userInteractionEnabled = true;
    self.thumbImageView.layer.borderColor = UIColor.redColor.CGColor;
    self.thumbImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.thumbImageView];
    [self.thumbImageView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.top.offset(6);
        make.right.offset(0);
        make.bottom.offset(-6);
    }];
    

    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.closeButton setImage:[UIImage imageNamed:@"style_cancel"] forState:UIControlStateNormal];
    self.closeButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.65];
    self.closeButton.hidden = YES;
    [self.thumbImageView addSubview:self.closeButton];
    [self.closeButton mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.top.right.offset(0);
        make.width.height.mas_equalTo(24);
    }];
    
    self.editLabel = [[UILabel alloc] init];
    self.editLabel.text = @"点击剪辑";
    self.editLabel.textAlignment = NSTextAlignmentCenter;
    self.editLabel.textColor = [UIColor whiteColor];
    self.editLabel.font = [UIFont systemFontOfSize:10];
    [self.thumbImageView addSubview:self.editLabel];
    [self.editLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.right.bottom.mas_equalTo(0);
        make.height.mas_equalTo(20);
    }];
    
    //时间
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.font = [UIFont systemFontOfSize:10];
    self.timeLabel.textColor = [UIColor whiteColor];
    [self.thumbImageView addSubview:self.timeLabel];
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.right.bottom.offset(-3);
    }];
    // 标签
    self.tagLabel = [[UILabel alloc] init];
    self.tagLabel.textColor = [UIColor whiteColor];
    self.tagLabel.font = [UIFont systemFontOfSize:9];
    self.tagLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    [self.thumbImageView addSubview:self.tagLabel];
    [self.tagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.top.offset(3);
        make.right.offset(-3);
    }];
}

- (void)setItem:(TAEModelVideoItem *)item
{
    _item = item;
    self.timeLabel.text = [NSString stringWithFormat:@"%@s", [self formatTime:item.endTime - item.startTime]];
    if (item.type == TAEModelAssetType_ImageOrVideo) {
        self.tagLabel.text = @"图片/视频";
    } else if (item.type == TAEModelAssetType_Image) {
        self.tagLabel.text = @" 图片 ";
    } else if (item.type == TAEModelAssetType_Video) {
        self.tagLabel.text = @" 视频 ";
    } else if (item.type == TAEModelAssetType_Mask) {
        self.tagLabel.text = @"蒙版视频 ";
    }

    if (item.thumbnail) {
        _thumbImageView.image = item.thumbnail;
        [self drawRectImage:item.thumbnail];
    } else {
        
        __weak typeof(self)weakSelf = self;
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            if ([item.resPath hasSuffix:@"mp4"] || [item.resPath hasSuffix:@"MOV"]) {
                
                [TAEModelMediator requestVideoImageWith:item.resPath cropRect:CGRectZero resultHandle:^(UIImage * _Nonnull reslut) {
                    weakSelf.thumbImageView.image = reslut;
                    weakSelf.item.thumbnail = reslut;
                    //如果无法正常获取图片封面，则需要替换
                    if (reslut == nil) {
                        weakSelf.item.enableReplace = YES;
                    }
                    [weakSelf drawRectImage:reslut];
                }];
                
            } else {
                [TAEModelMediator requestImageWith:item.resPath resultHandle:^(UIImage * _Nonnull reslut) {
                    weakSelf.thumbImageView.image = reslut;
                    weakSelf.item.thumbnail = reslut;
                    //如果无法正常获取图片封面，则需要替换
                    if (reslut == nil) {
                        weakSelf.item.enableReplace = YES;
                    }
                    [weakSelf drawRectImage:reslut];
                }];
            }
            
        });
    }
    self.thumbImageView.layer.borderWidth = item.isSelected ? 1.0 : 0;
    
    self.closeButton.hidden = self.editLabel.hidden = !self.item.isReplace;
    self.tagLabel.hidden = self.timeLabel.hidden = !self.closeButton.hidden;
}

- (void)drawRectImage:(UIImage *)image
{
    CGSize size = image.size;
    CGRect imageBounds = self.thumbImageView.bounds;
//    NSLog(@"TUEVA:原始imageSize===%@", NSStringFromCGSize(size));
    if (size.width > size.height) {
        size = CGSizeMake(imageBounds.size.width, imageBounds.size.width * (size.height / size.width));
    } else {
        size = CGSizeMake(imageBounds.size.height * (size.width / size.height), imageBounds.size.height);
    }
//    NSLog(@"TUEVA:处理后imageSize===%@", NSStringFromCGSize(size));
    if (size.width == 0 || size.height == 0) return;

    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    self.thumbImageView.image = image;
}

- (NSString *)formatTime:(NSInteger)time
{
    double seconds = time / 1000;
    return [NSString stringWithFormat:@"%.1f", seconds];
}

@end
