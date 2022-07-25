//
//  EditCollectionViewCell.h
//  TuSDKEvaDemo
//
//  Created by tutu on 2019/6/26.
//  Copyright © 2019 TuSdk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TAEModelMediator.h"
NS_ASSUME_NONNULL_BEGIN

@interface EditCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImage;
@property (weak, nonatomic) IBOutlet UIImageView *typeImage;
@property (weak, nonatomic) IBOutlet UILabel *text;
@property (weak, nonatomic) IBOutlet UILabel *typeText;

@property (nonatomic) id item;

@end

NS_ASSUME_NONNULL_END
