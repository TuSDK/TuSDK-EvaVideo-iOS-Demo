//
//  TTMultiAssetPicker.m
//  TuSDKEvaDemo
//
//  Created by 刘鹏程 on 2022/7/22.
//  Copyright © 2022 TuSdk. All rights reserved.
//

#import "TTMultiAssetPicker.h"
#import "TuSDKFramework.h"
#import <Photos/Photos.h>
#import "TTMultiAssetPickerCell.h"

@implementation TTPHAssetItem

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.selectCount = 1;
    }
    return self;
}

@end


// CollectionView Cell 重用 ID
static NSString * const kCellReuseIdentifier = @"Cell";
// 单元格间距
static const CGFloat kCellMargin = 3;

@interface TTMultiAssetPicker ()

/**
 呈现的相册结果
 */
@property (nonatomic, strong) NSArray<PHAsset *> *assets;
/**
 呈现的相册结果（视频）
 */
@property (nonatomic, strong) NSArray<PHAsset *> *videoAssets;
/**
 呈现的相册结果（图片）
 */
@property (nonatomic, strong) NSArray<PHAsset *> *imageAssets;

/**
 选中时加入 PHAsset，请求到 AVAsset 时再进行替换
 */
@property (nonatomic, strong) NSMutableArray *requestedAvAssets;

/**
 选中的 PHAsset
 */
@property (nonatomic, strong) NSMutableArray<TTPHAssetItem *> *selectedPhAssets;

/**
 请求中的视频 ID
 */
@property (nonatomic, strong) NSMutableDictionary<PHAsset *, NSNumber *> *requstingAssetIds;

@end

@implementation TTMultiAssetPicker

#pragma mark - property

- (NSMutableArray *)requestedAvAssets {
    if (!_requestedAvAssets) {
        _requestedAvAssets = [NSMutableArray array];
    }
    return _requestedAvAssets;
}

- (NSMutableArray *)selectedPhAssets {
    if (!_selectedPhAssets) {
        _selectedPhAssets = [NSMutableArray array];
    }
    return _selectedPhAssets;
}

- (NSMutableDictionary *)requstingAssetIds {
    if (!_requstingAssetIds) {
        _requstingAssetIds = [NSMutableDictionary dictionary];
    }
    return _requstingAssetIds;
}

- (BOOL)requesting {
    return _requstingAssetIds.count > 0;
}


- (void)setAssetMediaType:(TTAssetMediaType)assetMediaType
{
    _assetMediaType = assetMediaType;
    [self.collectionView reloadData];
}

#pragma mark - view controller

-(instancetype)init;{
    if (self = [super init]){
        // 默认提取视频
        _fetchMediaTypes = @[@(PHAssetMediaTypeVideo)];
        _assetMediaType = TTAssetMediaTypeAll;
    }
    return self;
}

+ (instancetype)picker {
    return [[self alloc] initWithCollectionViewLayout:[[UICollectionViewFlowLayout alloc] init]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
    
    [self.collectionView registerClass:[TTMultiAssetPickerCell class] forCellWithReuseIdentifier:kCellReuseIdentifier];
    
    // 测试相册访问权限，并载入相册数据
    [TuTSAssetsManager testLibraryAuthor:^(NSError *error) {
        if (error) {
            [TuTSAssetsManager showAlertWithController:self loadFailure:error];
        } else {
            [self loadData];
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterFrontFromBack) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)enterFrontFromBack {
    [self loadData];
}

- (void)setupUI {
    CGFloat width = self.view.frame.size.width;
    CGFloat cellWidth = (width + kCellMargin) / 3 - kCellMargin;
    UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
    flowLayout.itemSize = CGSizeMake(cellWidth, cellWidth);
    flowLayout.minimumInteritemSpacing = kCellMargin;
    flowLayout.minimumLineSpacing = kCellMargin;

    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.allowsMultipleSelection = NO;
    self.collectionView.backgroundColor = [UIColor blackColor];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    for (PHAsset *requestingPhAsset in _requstingAssetIds.allKeys) {
        [self cancelRequestWithVideo:requestingPhAsset];
    }
}

/**
 加载数据
 */
- (void)loadData {

    NSMutableArray<PHAsset *> *allAssets = [NSMutableArray arrayWithCapacity:50];
    NSMutableArray<PHAsset *> *videoAllAssets = [NSMutableArray arrayWithCapacity:50];
    NSMutableArray<PHAsset *> *imageAllAssets = [NSMutableArray arrayWithCapacity:50];
    
    [_fetchMediaTypes enumerateObjectsUsingBlock:^(NSNumber * _Nonnull assetMediaTypeNumber, NSUInteger idx, BOOL * _Nonnull stop) {
        
        PHFetchResult<PHAsset *> *fetchResult = [PHAsset fetchAssetsWithMediaType:assetMediaTypeNumber.integerValue == 1 ? PHAssetMediaTypeImage : PHAssetMediaTypeVideo options:[[PHFetchOptions alloc] init]];
        if (fetchResult && fetchResult.count > 0) {
           NSArray<PHAsset *> *assets = [fetchResult objectsAtIndexes:[[NSIndexSet alloc] initWithIndexesInRange:NSMakeRange(0, fetchResult.count)]];
            [allAssets addObjectsFromArray:assets];
        }
    }];
    
    // PhotoKit 相册排序方式
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO];
    [allAssets sortUsingDescriptors:@[sortDescriptor]];
    
    _assets = allAssets;
    
    for (int i = 0; i < _assets.count; i++) {
        PHAsset *asset = _assets[i];
        if (asset.mediaType == PHAssetMediaTypeVideo) {
            [videoAllAssets addObject:asset];
        } else {
            [imageAllAssets addObject:asset];
        }
    }
    
    _videoAssets = videoAllAssets;
    _imageAssets = imageAllAssets;
    
    [self.collectionView reloadData];
}

#pragma mark - public

- (PHAsset *)phAssetAtIndexPathItem:(NSInteger)indexPathItem {
    if (_assetMediaType == TTAssetMediaTypeAll) {
        if (_assets.count == 0) return nil;
        return _assets[indexPathItem];
    } else if (_assetMediaType == TTAssetMediaTypeVideo) {
        if (_videoAssets.count == 0) return nil;
        return _videoAssets[indexPathItem];
    } else {
        if (_imageAssets.count == 0) return nil;
        return _imageAssets[indexPathItem];
    }
}

/**
 * 移除指定的PHAsset
 * @param asset 视频对象
 * @return 是否移除成功
 */
- (BOOL)removePHAsset:(PHAsset *)asset;
{
    BOOL state = NO;
    if (_selectedPhAssets.count == 0) return state;
    
    
//    for (PHAsset *seletAsset in _selectedPhAssets) {
//        if (seletAsset == asset) {
//            [_selectedPhAssets removeObject:asset];
//            state = YES;
//            break;
//        }
//    }
    
    for (int i = 0; i < _selectedPhAssets.count; i++) {
        TTPHAssetItem *item = _selectedPhAssets[i];
        if ([item.assetID isEqualToString: asset.localIdentifier]) {
            --item.selectCount;
            if (item.selectCount == 0) {
                [_selectedPhAssets removeObject:item];
            }
            state = YES;
            [self.collectionView reloadData];
            break;
        }
    }
    
    
//    //选中数组中包含视频对象
//    if ([_selectedPhAssets containsObject:asset.localIdentifier]) {
//        [_selectedPhAssets removeObject:asset.localIdentifier];
//        [self.collectionView reloadData];
//        return YES;
//    }
    
    return state;
}

#pragma mark - private

/**
 请求 PHAsset 为 AVAsset，维护 _requstingAssetIds

 @param phAsset 视频文件对象
 @param completion 完成后的操作
 @return 视频对象的请求 ID
 */
- (PHImageRequestID)requestAVAssetForVideo:(PHAsset *)phAsset completion:(void (^)(PHAsset *inputPhAsset, AVAsset *avAsset))completion {
    // 若已经在请求，则直接返回 -1
    if ([_requstingAssetIds.allKeys containsObject:phAsset]) return -1;
    __weak typeof(self) weakSelf = self;
    
    // 配置请求
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.networkAccessAllowed = YES;
    options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        //NSLog(@"iCloud 下载 progress: %f", progress);
        // 若 phAsset 已移除请求，则直接返回
        if (![weakSelf.requstingAssetIds.allKeys containsObject:phAsset]) return;
        
        if (progress == 1.0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //[[TuSDK shared].messageHub dismiss];
            });
        } else {
            //[[TuSDK shared].messageHub showProgress:progress status:@"iCloud 同步中"];
        }
    };
    
    __block BOOL finish = NO;
    PHImageRequestID requestId = [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        //NSLog(@"请求结果：%@， info: %@", asset, info);
        finish = YES;
        if (!asset) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) completion(phAsset, asset);
            [weakSelf.requstingAssetIds removeObjectForKey:phAsset];
        });
    }];
    
    if (!finish) self.requstingAssetIds[phAsset] = @(requestId);
    return requestId;
   
}

/**
 取消请求 PHAsset，维护 _requstingAssetIds

 @param phAsset 视频文件对象
 @return 是否取消请求
 */
- (BOOL)cancelRequestWithVideo:(PHAsset *)phAsset {
    NSNumber *requestIdNumber = _requstingAssetIds[phAsset];
    
    if (!requestIdNumber) return NO;
    PHImageRequestID requestId = (PHImageRequestID)requestIdNumber.integerValue;
    [[PHImageManager defaultManager] cancelImageRequest:requestId];
    [_requstingAssetIds removeObjectForKey:phAsset];
    
    //[[TuSDK shared].messageHub dismiss];
    return YES;
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (_assetMediaType == TTAssetMediaTypeAll) {
        return _assets.count;
    } else if (_assetMediaType == TTAssetMediaTypeVideo) {
        return _videoAssets.count;
    } else {
        return _imageAssets.count;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PHAsset *asset = [self phAssetAtIndexPathItem:indexPath.item];
    TTMultiAssetPickerCell *cell = (TTMultiAssetPickerCell *)[collectionView dequeueReusableCellWithReuseIdentifier:kCellReuseIdentifier forIndexPath:indexPath];
    
    cell.tagLabel.hidden = YES;
    for (int i = 0; i < _selectedPhAssets.count; i++) {
        TTPHAssetItem *item = _selectedPhAssets[i];
        if ([item.assetID isEqualToString:asset.localIdentifier]) {
            cell.tagLabel.hidden = NO;
            break;
        }
    }

    cell.selectButton.hidden = _disableMultipleSelection;
    

    cell.asset = asset;
    
    __weak typeof(self) weakSelf = self;
    cell.selectButtonActionHandler = ^(TTMultiAssetPickerCell *cell, UIButton *sender) {
        BOOL selected = !sender.selected;
        // 若 iCloud 请求中则不让其选中
        if (selected && weakSelf.requesting) {
            return;
        }
        // 应用选中
        PHAsset *phAsset = [weakSelf phAssetAtIndexPathItem:indexPath.item];
        if ([weakSelf.delegate respondsToSelector:@selector(picker:didSelectButtonItemWithIndexPath:phAsset:)]) {
            BOOL status = [weakSelf.delegate picker:weakSelf didSelectButtonItemWithIndexPath:indexPath phAsset:phAsset];
            if (status) {
                cell.tagLabel.hidden = NO;
                if (weakSelf.selectedPhAssets.count == 0) {
                    TTPHAssetItem *item = [[TTPHAssetItem alloc] init];
                    item.assetID = phAsset.localIdentifier;
                    item.asset = phAsset;
                    [weakSelf.selectedPhAssets addObject:item];
                    
                    return;
                }
                //创建空的资源Item
                TTPHAssetItem *selectItem = [[TTPHAssetItem alloc] init];
                //如果选中资源数组中存在，则选中数量+1，，如果不存在
                for (TTPHAssetItem *item in weakSelf.selectedPhAssets) {
                    if ([item.assetID isEqualToString:phAsset.localIdentifier]) {
                        ++item.selectCount;
                        selectItem = item;
                    }
                }
                if (!selectItem.assetID) {
                    selectItem.assetID = phAsset.localIdentifier;
                    selectItem.asset = phAsset;
                    [weakSelf.selectedPhAssets addObject:selectItem];
                }
            }
        }
    };
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return !self.requesting;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    PHAsset *phAsset = [self phAssetAtIndexPathItem:indexPath.item];
    if ([self.delegate respondsToSelector:@selector(picker:didTapItemWithIndexPath:phAsset:)]) {
        [self.delegate picker:self didTapItemWithIndexPath:indexPath phAsset:phAsset];
    }
}


@end
