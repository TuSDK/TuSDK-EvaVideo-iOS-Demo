//
//  EditCollectionViewCell.m
//  TuSDKEvaDemo
//
//  Created by tutu on 2019/6/26.
//  Copyright © 2019 TuSdk. All rights reserved.
//

#import "EditCollectionViewCell.h"
#import "TuSDKFrameWork.h"

@interface EditCollectionViewCell()
@property (nonatomic, strong) UIView *editView;

@end

@implementation EditCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = YES;
    
    self.layer.borderWidth = 0;
    self.layer.borderColor = [UIColor redColor].CGColor;
    
    self.editView = [[UIView alloc] init];
    self.editView.hidden = YES;
    self.editView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    [self.backgroundImage addSubview:self.editView];
    [self.editView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.edges.equalTo(self.backgroundImage);
    }];
    
    UIImageView *editImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"style_edit"]];
    [self.editView addSubview:editImageView];
    [editImageView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.bottom.mas_equalTo(self.contentView.mas_centerY);
        make.centerX.mas_equalTo(self.contentView);
        make.width.height.mas_equalTo(20);
    }];
    
    UILabel *editLabel = [[UILabel alloc] init];
    editLabel.text = @"点击编辑";
    editLabel.textColor = [UIColor whiteColor];
    editLabel.textAlignment = NSTextAlignmentCenter;
    editLabel.font = [UIFont systemFontOfSize:10];
    [self.editView addSubview:editLabel];
    [editLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.right.offset(0);
        make.top.mas_equalTo(editImageView.mas_bottom).offset(5);
    }];
}

- (void)setItem:(id)item
{
    _item = item;
    
    if ([item isKindOfClass:[TAEModelTextItem class]])
    {
        //文本
        self.backgroundImage.hidden = self.editView.hidden = YES;
        self.typeText.hidden = YES;
        self.text.hidden = NO;
        TAEModelTextItem *textItem = (TAEModelTextItem *)item;
        if (textItem.isReplace) {
            // 替换的
            self.text.textColor = [UIColor whiteColor];
        } else {
            // 没有替换的
            self.text.textColor = [UIColor colorWithRed:102.0/255.0 green:102.0/255.0 blue:102.0/255.0 alpha:1];
        }
        self.text.text = textItem.text;
        self.layer.borderWidth = textItem.isSelected ? 0.5 : 0;

    }
    if ([item isKindOfClass:[TAEModelVideoItem class]]) {
        self.backgroundImage.hidden = NO;
        self.typeText.hidden = NO;
        self.text.hidden = YES;
        TAEModelVideoItem *videoItem = (TAEModelVideoItem *)item;
        if (videoItem.type == TAEModelAssetType_ImageOrVideo) {
            self.typeText.text = @"图片/视频 ";
        } else if (videoItem.type == TAEModelAssetType_Image) {
            self.typeText.text = @" 图片 ";
        } else if (videoItem.type == TAEModelAssetType_Video) {
            self.typeText.text = @" 视频 ";
        } else if (videoItem.type == TAEModelAssetType_Mask) {
            self.typeText.text = @"蒙版视频 ";
        }
        if (videoItem.thumbnail) {
            self.backgroundImage.image = videoItem.thumbnail;
            [self drawRectImage:videoItem.thumbnail];
        } else {
            
            [TAEModelMediator requestImageWith:videoItem.resPath resultHandle:^(UIImage * _Nonnull reslut) {
                self.backgroundImage.image = reslut;
                videoItem.thumbnail = reslut;
                [self drawRectImage:reslut];
            }];
        }
        self.editView.hidden = !videoItem.isSelected;
        self.layer.borderWidth = videoItem.isSelected ? 0.5 : 0;
        
    }
}

- (void)drawRectImage:(UIImage *)image
{
    CGSize size = image.size;
    CGRect imageBounds = self.backgroundImage.bounds;
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
    
    
    self.backgroundImage.image = image;
}


@end
