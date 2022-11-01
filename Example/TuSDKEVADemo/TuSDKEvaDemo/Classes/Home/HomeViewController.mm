//
//  HomeViewController.m
//  TuSDKEvaDemo
//
//  Created by tutu on 2019/6/26.
//  Copyright © 2019 TuSdk. All rights reserved.
//

#import "HomeViewController.h"
#import "CollectionViewLayout.h"
#import "HomeCollectionViewCell.h"
#import "EVAPreviewViewController.h"
#import "DownLoadManager.h"
#import "DownLoadFileModel.h"
#import "TuSDKFramework.h"
#import "DownLoadListManager.h"
#import "TuSDKPulse/TUPEngine.h"
#import "iCloudManager.h"
#import "TuPopupProgress.h"
#import "EditDynamicViewController.h"
#import <MJRefresh/MJRefresh.h>
#import "EVAMutiAssetPickerController.h"
#define kColumMargin 12.0
#define kRowMargin   12.0
#define kItemWidth   (([UIScreen mainScreen].bounds.size.width - kColumMargin*3) * 0.5)

NSString *const kICloudCacheDir = @"eva_cache_dir_iCloud";
NSString *const kDynamicCacheDir = @"eva_cache_dir_dynamic";

NSString *const kCollectFooterViewID = @"CollectFooterView";

@interface HomeViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, CollectionViewLayoutDelegate, UIDocumentPickerDelegate, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet CollectionViewLayout *collectionViewLayout;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

/**
 models
 */
@property (nonatomic, strong) NSMutableArray *models;
@property(nonatomic, strong) UIActivityIndicatorView *indicatorView;
@end

@implementation HomeViewController

- (void)updateUI;
{
    if (self.models.count == 0) {
        
        // 下载中或者等待下载
        //[[TuSDK shared].messageHub showError:@"网络异常，请检查网络并重试！"];
        
        [self.collectionView.mj_header endRefreshing];
        
    }else{
        //[[TuSDK shared].messageHub dismiss];
        [self.collectionView reloadData];
        [self.collectionView.mj_header endRefreshing];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:19.0/255.0 green:19.0/255.0 blue:19.0/255.0 alpha:1.0];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.minimumLineSpacing = 5;
    flowLayout.minimumInteritemSpacing = 5;
    flowLayout.footerReferenceSize = CGSizeMake(CGRectGetWidth(self.view.frame), 50);
    
    self.collectionView.collectionViewLayout = flowLayout;
    [self.collectionView registerNib:[UINib nibWithNibName:@"HomeCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"HomeCollectionViewCell"];
    [self.collectionView registerClass:[UICollectionReusableView class] forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:kCollectFooterViewID];
    //self.collectionViewLayout.delegate = self;
    self.collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    [[DownLoadListManager manager] downLoadFileCompletionHandler:^(NSMutableArray * modelArr) {
        // 将 modelArr 转成 DownLoadFileModel 数组
        self.models = [NSMutableArray arrayWithCapacity:modelArr.count];
        for (NSDictionary *dict in modelArr) {
            [self.models addObject:[[DownLoadFileModel alloc] initWithDictionary:dict]];
        }
        [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
    }];
    
    //初始化
    [TUPEngine Init:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(iCloudOtherAppAction:) name:@"FileNotification" object:nil];
    
    self.collectionView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        
        [[DownLoadListManager manager] downLoadFileCompletionHandler:^(NSMutableArray * modelArr) {
            // 将 modelArr 转成 DownLoadFileModel 数组
            if (self.models.count == 0) {
                [self.models removeAllObjects];
                self.models = [NSMutableArray arrayWithCapacity:modelArr.count];
                for (NSDictionary *dict in modelArr) {
                    [self.models addObject:[[DownLoadFileModel alloc] initWithDictionary:dict]];
                }
            }
            [self performSelectorOnMainThread:@selector(updateUI) withObject:nil waitUntilDone:NO];
        }];
        
    }];
}


#pragma mark - UICollectionViewDataSource, UICollectionViewDelegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _models.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
{
    DownLoadFileModel *model = _models[indexPath.item];
    CGFloat width = model.width;
    CGFloat height = model.height;
    //NSLog(@"width,height--%f,%f",width,height);
    
    CGFloat cellW = CGRectGetWidth(self.view.frame) / 2 - 5;
    CGFloat cellH = height * cellW / width;
    
    return CGSizeMake(cellW, cellH); // 0.0 是文字高度 暂时隐藏
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HomeCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HomeCollectionViewCell" forIndexPath:indexPath];
    DownLoadFileModel *model = _models[indexPath.row];
    
    cell.model = model;
    if (model.status == DownloadStateResumed) {
        [cell updateDownladProgress];
    }
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    DownLoadFileModel *model = _models[indexPath.row];
    if (model.status == DownloadStateCompleted) {
        // 已经下载的
        EVAPreviewViewController *vc = [[EVAPreviewViewController alloc] initWithNibName:nil bundle:nil];
        vc.ID = model.ID;
        vc.evaPath = model.filePath;
        vc.modelTitle = model.name;
        vc.fileName = model.fileName;
        [self showViewController:vc sender:nil];
        __weak typeof(model) weakModel = model;
        __weak typeof(self) weakSelf = self;
        [vc setLoadTempleError:^{
            [weakModel reset];
            [weakSelf.collectionView reloadData];
        }];
        return;
    }
    
    if (model.status == DownloadStateResumed || model.status == DownloadStateWait) {
        // 下载中或者等待下载
        //[[TuSDK shared].messageHub showToast:@"等待下载完成后再点击进行预览、使用"];
    } else {
        // 需要继续下载
        //        [[TuSDK shared].messageHub showToast:@"请点击下载，完成后方可预览、使用"];
        HomeCollectionViewCell *cell = (HomeCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        [cell clickButton];
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [(HomeCollectionViewCell*)cell willDisplay];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    
    if (kind == UICollectionElementKindSectionFooter) {
        reusableview = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:kCollectFooterViewID forIndexPath:indexPath];
        
        //获取版本信息
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *bundleShortVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
        NSString *bundleVersion = [infoDictionary objectForKey:@"CFBundleVersion"];
        //获取时间信息
        NSDate *date = [NSDate date];
        NSDateFormatter *formate = [[NSDateFormatter alloc] init];
        [formate setDateFormat:@"yyyy"];
        NSString *dateStr = [formate stringFromDate:date];
        
        UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 50)];
        infoLabel.textColor = [UIColor whiteColor];
        infoLabel.textAlignment = NSTextAlignmentCenter;
        infoLabel.numberOfLines = 0;
        infoLabel.font = [UIFont systemFontOfSize:13];
        infoLabel.text = [NSString stringWithFormat:@"TuSDK EVA SDK %@ - %@ \n @%@ TUTUCLOUD.COM", bundleShortVersion, bundleVersion, dateStr];
        [reusableview addSubview:infoLabel];
    }
    
    return reusableview;
}


#pragma mark - CollectionViewLayoutDelegate

- (CGFloat)waterFallLayout:(CollectionViewLayout *)waterFallLayout heightForItemAtIndexPath:(NSUInteger)indexPath itemWidth:(CGFloat)itemWidth {
    DownLoadFileModel *model = _models[indexPath];
    CGFloat width = model.width;
    CGFloat height = model.height;
    //NSLog(@"width,height--%f,%f",width,height);
    return kItemWidth * (height/width) + 0.0; // 0.0 是文字高度 暂时隐藏
}

- (NSUInteger)columnCountInWaterFallLayout:(CollectionViewLayout *)waterFallLayout {
    return 2;
}

- (CGFloat)rowMarginInWaterFallLayout:(CollectionViewLayout *)waterFallLayout {
    return kRowMargin;
}

- (CGFloat)columnMarginInWaterFallLayout:(CollectionViewLayout *)waterFallLayout {
    return kColumMargin;
}

- (UIEdgeInsets)edgeInsetdInWaterFallLayout:(CollectionViewLayout *)waterFallLayout {
    return UIEdgeInsetsMake(0, kColumMargin, kRowMargin, kColumMargin);
}

- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _indicatorView.frame = CGRectMake(0, 0, 75, 75);
        _indicatorView.backgroundColor = UIColor.blackColor;
        _indicatorView.layer.cornerRadius = 6;
        _indicatorView.clipsToBounds = YES;
        _indicatorView.center = self.collectionView.center;
        [self.view addSubview:_indicatorView];
    }
    return _indicatorView;
}


- (NSString *)generateDirectory:(NSString *)directory {
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSString *cacheDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:directory];
    BOOL isDic = false;
    BOOL isDirExist = [manager fileExistsAtPath:cacheDirectory isDirectory:&isDic];
    if (!isDic && !isDirExist) {
        //创建文件夹存放下载的文件
        [manager createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return cacheDirectory;
}

@end
