//
//  DWAlbumManagerVC.m
//  DWKitDemo
//
//  Created by Wicky on 2020/2/24.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWAlbumManagerVC.h"
#import <DWAlbumGridController/DWAlbumGridControllerHeader.h>
#import <DWKit/DWAlbumManager.h>
@interface DWAlbumManagerVC ()<DWAlbumGridDataSource>

@property (nonatomic ,strong) DWAlbumManager * albumManager;

@property (nonatomic ,strong) DWAlbumGridController * gridVC;

@property (nonatomic ,strong) DWAlbumModel * currentGridAlbum;

@property (nonatomic ,strong) PHFetchResult * currentGridAlbumResult;

@property (nonatomic ,strong) DWAlbumSelectionManager * mgr;

@end

@implementation DWAlbumManagerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    norBtn(@"给我展示一个相册", self, @selector(cameraAction:), self.view, 0);
}

-(void)cameraAction:(UIButton *)sender {
    [DWAlbumManager requestAuthorizationForLevelIfNeeded:(DWAlbumManagerAccessLevelReadWrite) completion:^(PHAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (status == PHAuthorizationStatusAuthorized) {
                [self.albumManager fetchCameraRollWithOption:nil completion:^(DWAlbumManager * _Nullable mgr, DWAlbumModel * _Nullable obj) {
                    [self configAlbum:obj];
                    [self presentViewController:self.gridVC animated:YES completion:nil];
                }];
            } else {
                NSLog(@"咋还不给我权限呢！");
            }
        });
    }];
}

#pragma mark --- tool method ---
-(void)configAlbum:(DWAlbumModel *)album {
    if (![self.currentGridAlbum isEqual:album]) {
        self.currentGridAlbumResult = album.fetchResult;
        self.currentGridAlbum = album;
        DWAlbumGridModel * gridModel = [self gridModelFromAlbumModel:album];
        [self.gridVC configWithGridModel:gridModel];
    }
}

-(DWAlbumGridModel *)gridModelFromAlbumModel:(DWAlbumModel *)album {
    DWAlbumGridModel * gridModel = [DWAlbumGridModel new];
    NSMutableArray * tmp = [NSMutableArray arrayWithCapacity:album.count];
    [album.fetchResult enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [tmp addObject:obj];
    }];
    gridModel.results = [tmp copy];
    gridModel.name = album.name;
    return gridModel;
}

-(DWAlbumGridCellModel *)gridCellModelFromImageAssetModel:(DWImageAssetModel *)assetModel {
    DWAlbumGridCellModel * gridModel = [DWAlbumGridCellModel new];
    gridModel.asset = assetModel.asset;
    gridModel.media = assetModel.media;
    gridModel.mediaType = assetModel.mediaType;
    gridModel.targetSize = assetModel.targetSize;
    return gridModel;
}

#pragma mark --- grid dataSource ---

-(void)gridController:(DWAlbumGridController *)gridController fetchMediaForAsset:(PHAsset *)asset targetSize:(CGSize)targetSize thumnail:(BOOL)thumnail completion:(DWGridViewControllerFetchCompletion)completion {
    if (thumnail) {
        [self.albumManager fetchImageWithAsset:asset targetSize:targetSize networkAccessAllowed:self.currentGridAlbum.networkAccessAllowed progress:nil completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
            if (completion) {
                completion([self gridCellModelFromImageAssetModel:obj]);
            }
        }];
    } else {
        NSInteger index = [self.currentGridAlbumResult indexOfObject:asset];
        [self.albumManager fetchImageWithAlbum:self.currentGridAlbum index:index targetSize:targetSize shouldCache:YES progress:nil completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
            if (completion) {
                completion([self gridCellModelFromImageAssetModel:obj]);
            }
        }];
    }
}

-(void)gridController:(DWAlbumGridController *)gridController startCachingMediaForIndexes:(NSIndexSet *)indexes targetSize:(CGSize)targetSize {
    [self.albumManager startCachingImagesForAlbum:self.currentGridAlbum indexes:indexes targetSize:targetSize];
}

-(void)gridController:(DWAlbumGridController *)gridController stopCachingMediaForIndexes:(NSIndexSet *)indexes targetSize:(CGSize)targetSize {
    [self.albumManager stopCachingImagesForAlbum:self.currentGridAlbum indexes:indexes targetSize:targetSize];
}

#pragma mark --- setter/getter ---
-(DWAlbumGridController *)gridVC {
    if (!_gridVC) {
        CGFloat shortSide = MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        CGFloat width = (shortSide - (3 - 1) * 0.5) / 3;
        _gridVC = [[DWAlbumGridController alloc] initWithItemWidth:width];
        _gridVC.selectionManager = self.mgr;
        _gridVC.dataSource = self;
        _gridVC.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return _gridVC;
}

-(DWAlbumManager *)albumManager {
    if (!_albumManager) {
        _albumManager = [[DWAlbumManager alloc] init];
    }
    return _albumManager;
}

-(DWAlbumSelectionManager *)mgr {
    if (!_mgr) {
        _mgr = [[DWAlbumSelectionManager alloc] initWithMaxSelectCount:9 selectableOption:(DWAlbumMediaOptionAll) multiTypeSelectionEnable:YES];
    }
    return _mgr;
}

@end
