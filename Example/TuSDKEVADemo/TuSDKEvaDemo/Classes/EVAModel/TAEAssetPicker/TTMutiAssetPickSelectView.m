//
//  TTMutiAssetPickSelectView.m
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2022/6/8.
//  Copyright © 2022 TuSdk. All rights reserved.
//

#import "TTMutiAssetPickSelectView.h"
#import "TTMutiAssetPickSelectCell.h"

#import "TuSDKFrameWork.h"

// CollectionView Cell 重用 ID
static NSString * const kCellReuseIdentifier = @"TTMutiAssetPickSelectCell";

@interface TTMutiAssetPickSelectView()<UICollectionViewDelegate, UICollectionViewDataSource>
/// 显示信息label
@property (nonatomic, strong) UILabel *msgLabel;
/// 下一步button
@property (nonatomic, strong) UIButton *nextButton;

@property (nonatomic, strong) UICollectionView *collectionView;
/// 数据组
@property (nonatomic, strong) NSMutableArray *items;
/// 选择的item
@property (nonatomic, strong) TAEModelVideoItem *selectItem;

@end

@implementation TTMutiAssetPickSelectView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setupView];
    }
    return self;
}

- (void)setupView
{
    self.backgroundColor = [UIColor blackColor];
    
    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.nextButton setTitle:@"下一步" forState:UIControlStateNormal];
    [self.nextButton setTitleColor:[UIColor lsqClorWithHex:@"#868C98"] forState:UIControlStateDisabled];
    [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.nextButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [self.nextButton addTouchUpInsideTarget:self action:@selector(nextButtonAction:)];
    //776AF7
    self.nextButton.backgroundColor = [UIColor lsqClorWithHex:@"#135FF9"];
//    self.nextButton.backgroundColor = self.nextButton.enabled ? [UIColor lsqClorWithHex:@"#5648FF"] : [UIColor lsqClorWithHex:@"#272731"];
    self.nextButton.layer.cornerRadius = 15;
    [self addSubview:self.nextButton];
    [self.nextButton mas_makeConstraints:^(MASConstraintMaker *make) {
       
        CGFloat safeBottom = 0;
        if ([UIDevice lsqIsDeviceiPhoneX])
        {
            safeBottom = 44;
        }
        
        make.right.offset(-24);
        make.bottom.offset(-safeBottom - 10);
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(82);
    }];
    
    
    self.msgLabel = [[UILabel alloc] init];
    self.msgLabel.font = [UIFont systemFontOfSize:13];
    self.msgLabel.textColor = [UIColor lsqClorWithHex:@"#CCCCCC"];
    [self addSubview:self.msgLabel];
    [self.msgLabel mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.left.offset(24);
        make.height.mas_equalTo(20);
        make.centerY.mas_equalTo(self.nextButton);
    }];

    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(80, 80);
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.showsHorizontalScrollIndicator = NO;
    [self addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
       
        make.bottom.mas_equalTo(self.nextButton.mas_top).offset(-30);
        make.left.right.offset(0);
        make.height.mas_equalTo(80);
        make.top.offset(10);
    }];
    [self.collectionView registerClass:[TTMutiAssetPickSelectCell class] forCellWithReuseIdentifier:kCellReuseIdentifier];
}

#pragma mark - setter

- (void)setMediator:(TAEModelMediator *)mediator
{
    _mediator = mediator;
    self.msgLabel.text = [NSString stringWithFormat:@"需要%ld个素材", [mediator imageVideoCount]];
    [self.items removeAllObjects];
    [self.items addObjectsFromArray:self.mediator.videoItems];
    [self.collectionView reloadData];
    //在相册选择页当前控制器需要默认选中第一个
    if (_isCurrent) {
        [self collectionView:self.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }
}

- (void)setIsCurrent:(BOOL)isCurrent
{
    _isCurrent = isCurrent;
}

#pragma mark - UICollectionViewDelegate, UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TTMutiAssetPickSelectCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseIdentifier forIndexPath:indexPath];
    cell.item = self.items[indexPath.item];
    cell.closeButton.tag = indexPath.item;
    [cell.closeButton addTouchUpInsideTarget:self action:@selector(closeButtonAction:)];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    for (TAEModelVideoItem *item in self.items) {
        item.isSelected = NO;
    }
    TAEModelVideoItem *selectItem = self.items[indexPath.item];
    selectItem.isSelected = YES;
    //替换mediator中相对应的素材资源
    [self.mediator replaceVideoItem:selectItem];
    self.selectItem = selectItem;
    [collectionView reloadData];
    
    //点选了item
    if (self.delegate && [self.delegate respondsToSelector:@selector(mutiAssetPickerSelectView:selectItem:)]) {
        [self.delegate mutiAssetPickerSelectView:self selectItem:selectItem];
    }
}

#pragma mark - method
/// 下一步
- (void)nextButtonAction:(UIButton *)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(mutiAssetPickerSelectView:selectAction:)]) {
        [self.delegate mutiAssetPickerSelectView:self selectAction:TTMutiAssetPickSelectNext];
    }
}

/// 关闭按钮点击事件
- (void)closeButtonAction:(UIButton *)sender
{
    _selectItem.isSelected = NO;
    
    //删除后选中资源重置
    TAEModelVideoItem *selectItem = self.items[sender.tag];
    //资源重置
    selectItem.isReplace = NO;
    selectItem.replaceResPath = nil;
    selectItem.thumbnail = nil;
    selectItem.originalImage = nil;
    selectItem.isSelected = YES;
    _selectItem = selectItem;
    [self.mediator replaceVideoItem:selectItem];

    
    [self.collectionView reloadData];
    
    
    if ([self.items containsObject:self.selectItem]) {
        NSInteger selectIndex = [self.items indexOfObject:self.selectItem];
        if (selectIndex > 0) {
            selectIndex --;
        }
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:selectIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
        //点选了item
        if (self.delegate && [self.delegate respondsToSelector:@selector(mutiAssetPickerSelectView:deleteItem:)]) {
            [self.delegate mutiAssetPickerSelectView:self deleteItem:selectItem];
        }
    }
}


- (void)reloadData
{
    //判断当前选择item的位置
    if ([self.items containsObject:self.selectItem]) {
        
        //选中item 置为 nil
        _selectItem = nil;
        //循环遍历数组，判断前后是否有未替换坑位
        for (int index = 0; index < self.items.count; index++) {
            TAEModelVideoItem *item = self.items[index];
            item.isSelected = NO;
            
            //存在未替换坑位
            if (!item.isReplace) {
                item.isSelected = YES;
                _selectItem = item;
                break;
            }
        }
        if (self.selectItem) {
            NSInteger selectIndex = [self.items indexOfObject:self.selectItem];
            NSLog(@"TT:下一个选中的item index ==%ld", selectIndex);
            [self collectionView:self.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:selectIndex inSection:0]];
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:selectIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionLeft animated:YES];
        } else {
            [self.collectionView reloadData];
        }
    }
}

#pragma mark - setter getter
- (NSMutableArray *)items
{
    if (!_items) {
        _items = [NSMutableArray array];
    }
    return _items;
}

/// 获取已选择总数
- (NSInteger)selectCount;
{
    NSInteger count = 0;
    for (TAEModelVideoItem *item in self.items) {
        if (item.isReplace) {
            count++;
        }
    }
    return count;
}

@end
