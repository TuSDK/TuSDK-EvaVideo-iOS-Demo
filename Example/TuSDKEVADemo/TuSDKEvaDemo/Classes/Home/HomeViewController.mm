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

@interface HomeViewController ()<UICollectionViewDelegate, UICollectionViewDataSource, CollectionViewLayoutDelegate, UIDocumentPickerDelegate>

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
    
    [self.collectionView registerNib:[UINib nibWithNibName:@"HomeCollectionViewCell" bundle:nil] forCellWithReuseIdentifier:@"HomeCollectionViewCell"];
    self.collectionViewLayout.delegate = self;
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
            [self.models removeAllObjects];
            self.models = [NSMutableArray arrayWithCapacity:modelArr.count];
            for (NSDictionary *dict in modelArr) {
                [self.models addObject:[[DownLoadFileModel alloc] initWithDictionary:dict]];
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

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HomeCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"HomeCollectionViewCell" forIndexPath:indexPath];
    DownLoadFileModel *model = _models[indexPath.row];
    cell.model = model;
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
- (void)iCloudShowAction {
    if (![iCloudManager iCloudEnable]) {
        [TuPopupProgress showErrorWithStatus:@"iCloud云盘不可用"];
        return;
    }
    [self.indicatorView startAnimating];
    NSArray *documentTypes = @[@"public.content", @"public.text", @"public.data", @"public.executable",@"public.item"];
    UIDocumentPickerViewController *documentPickerViewController = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:documentTypes inMode:UIDocumentPickerModeOpen];
    documentPickerViewController.delegate = self;
    [self presentViewController:documentPickerViewController animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    NSArray *array = [[url absoluteString] componentsSeparatedByString:@"/"];
    NSString *fileName = [array lastObject];
    fileName = [fileName stringByRemovingPercentEncoding];
    if (![fileName containsString:@"eva"]) {
        [self iCloudDismissIndicator];
        return;
    }
    
    [iCloudManager downloadWithDocumentURL:url callBack:^(id obj) {
        NSData *data = obj;
        //写入沙盒Documents
        NSString *cacheDirectory = [self generateDirectory:kICloudCacheDir];
        NSString *path = [NSString stringWithFormat:@"%@/%@",cacheDirectory,fileName];
        BOOL ret = [data writeToFile:path atomically:YES];
        [self iCloudDismissIndicator];
        if (ret) {
            [self iCloudPushDetail:path fileName:fileName];
        }
    }];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    [self iCloudDismissIndicator];
}

- (void)iCloudDismissIndicator {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.indicatorView stopAnimating];
    });
}

- (void)iCloudOtherAppAction:(NSNotification *)notification {
    NSDictionary *dict = notification.userInfo;
    NSString *fileName = dict[@"fileName"];
    NSString *filePath = dict[@"filePath"];
    if (![fileName containsString:@"eva"]) {
        return;
    }
    for (UIViewController *vc in self.navigationController.viewControllers) {
        if ([vc isKindOfClass:[EVAMutiAssetPickerController classForCoder]]) {
            [self.navigationController popViewControllerAnimated:NO];
            break;
        }
    }
    [self iCloudPushDetail:filePath fileName:fileName];
}

- (void)iCloudPushDetail:(NSString *)path fileName:(NSString *)fileName {
    // 已经下载的
//    EVAPreviewViewController *vc = [[EVAPreviewViewController alloc] initWithNibName:nil bundle:nil];
//    vc.evaPath = path;
//    vc.modelTitle = fileName;
//    vc.fileName = fileName;
//    [self showViewController:vc sender:nil];
    
    EVAMutiAssetPickerController *vc = [[EVAMutiAssetPickerController alloc] init];
    vc.filePath = path;
    [self showViewController:vc sender:nil];
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

- (void)clearCache {
    NSString *cacheDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:kICloudCacheDir];
    [[NSFileManager defaultManager] removeItemAtPath:cacheDirectory error:nil];
    
    NSString *dynamicDirectory = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:kDynamicCacheDir];
    [[NSFileManager defaultManager] removeItemAtPath:dynamicDirectory error:nil];
    
    [TUPEvaModel clearAllCaches];
}
@end
