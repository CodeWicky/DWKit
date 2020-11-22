//
//  DWAlbumGridViewController.m
//  DWCheckBox
//
//  Created by Wicky on 2019/8/4.
//

#import "DWAlbumGridController.h"
#import "DWAlbumGridCell.h"
#import "DWAlbumMediaHelper.h"
#import <DWKit/DWFixAdjustCollectionView.h>

@interface DWGridFlowLayout : UICollectionViewFlowLayout

@end

@implementation DWGridFlowLayout

-(void)prepareLayout {
    [super prepareLayout];
    CGFloat viewWidth = self.collectionView.bounds.size.width;
    CGFloat sizeWidth = self.itemSize.width;
    NSInteger column = (NSInteger)(viewWidth / sizeWidth);
    if (column == 1) {
        self.minimumLineSpacing = self.minimumInteritemSpacing = 1 / MIN(2, [UIScreen mainScreen].scale);
    } else {
        self.minimumLineSpacing = self.minimumInteritemSpacing = (viewWidth - sizeWidth * column) / (column - 1) - __FLT_EPSILON__;
    }
}

@end

@interface DWAlbumGridController ()<UICollectionViewDelegateFlowLayout,UICollectionViewDataSource,UICollectionViewDataSourcePrefetching>
{
    NSInteger _innerNotifyChangeIndex;
    BOOL _firstAppear;
    BOOL _needScrollToEdge;
    BOOL _isShowing;
    BOOL _screenRotateNeedsResetPreviewIndex;
    CGSize _oriSize;
}

@property (nonatomic ,strong) DWFixAdjustCollectionView * collectionView;

@property (nonatomic ,strong) DWGridFlowLayout * collectionViewLayout;

@property (nonatomic ,strong) NSArray <PHAsset *>* results;

@property (nonatomic ,assign) CGSize photoSize;

@property (nonatomic ,assign) CGSize thumnailSize;

@property (nonatomic ,assign) CGFloat velocity;

@property (nonatomic ,assign) CGFloat lastOffsetY;

@property (nonatomic ,strong) NSMutableDictionary * clsCtn;

@end

@implementation DWAlbumGridController

#pragma mark --- interface method ---
-(instancetype)initWithItemWidth:(CGFloat)width {
    if (self = [super init]) {
        _itemWidth = width;
    }
    return self;
}

-(void)configWithGridModel:(DWAlbumGridModel *)gridModel {
    if (![_gridModel isEqual:gridModel]) {
        _gridModel = gridModel;
        _results = gridModel.results;
        self.title = gridModel.name;
        _needScrollToEdge = YES;
        [_collectionView reloadData];
    }
}

-(void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier {
    if (!identifier.length) {
        return;
    }
    if (_collectionView) {
        [self.collectionView registerClass:cellClass forCellWithReuseIdentifier:identifier];
    } else {
        [self.clsCtn setObject:cellClass forKey:identifier];
    }
}

-(DWAlbumGridCell *)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndex:(NSInteger)index {
    return [_collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
}

-(void)notifyPreviewIndexChangeTo:(NSInteger)index {
    if (index >= 0 && index < self.results.count) {
        _innerNotifyChangeIndex = index;
    }
}

#pragma mark --- life cycle ---
-(void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.collectionView];
    if (self.bottomToolBar) {
        [self.view addSubview:self.bottomToolBar];
        UIEdgeInsets insets = self.collectionView.contentInset;
        insets.bottom += self.bottomToolBar.toolBarHeight;
        self.collectionView.contentInset = insets;
    }
    
    if (self.topToolBar) {
        [self.view addSubview:self.topToolBar];
        UIEdgeInsets insets = self.collectionView.contentInset;
        insets.top += self.topToolBar.toolBarHeight;
        self.collectionView.contentInset = insets;
    }
    
    _firstAppear = YES;
    _innerNotifyChangeIndex = -1;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self showGrid];
    _firstAppear = NO;
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self leaveGrid];
}
    

#pragma mark --- tool method ---
-(void)showGrid {
    _isShowing = YES;
    [self configItemSizeIfNeeded];
    [self handleScreenRotateBackgroundIfNeeded];
    [self handleAutoScrollIfNeeded];
}

-(void)leaveGrid {
    _oriSize = self.collectionView.frame.size;
    _isShowing = NO;
}

-(void)configItemSizeIfNeeded {
    if (_firstAppear) {
        CGSize itemSize = ((UICollectionViewFlowLayout *)self.collectionViewLayout).itemSize;
        CGFloat scale = 2;
        CGFloat thumnailScale = 0.5;
        self.photoSize = CGSizeMake(floor(itemSize.width * scale), floor(itemSize.height * scale));
        self.thumnailSize = CGSizeMake(floor(itemSize.width * thumnailScale), floor(itemSize.height * thumnailScale));
    }
}

-(void)handleScreenRotateBackgroundIfNeeded {
    ///这里如果背后旋屏了，要在safeArea更改之前配置dw_autoFixAdjustedContentInset，以方便collectionView过后调整中间展示区域不变
    if (!CGSizeEqualToSize(_oriSize, self.view.bounds.size)) {
        _screenRotateNeedsResetPreviewIndex = YES;
        [self autoFixAdjustedContentInset];
    }
}

-(void)autoFixAdjustedContentInset {
    self.collectionView.dw_autoFixContentOffset = YES;
    self.collectionView.dw_useAutoFixAdjustedContentInset = YES;
    if (@available(iOS 11.0,*)) {
        self.collectionView.dw_autoFixAdjustedContentInset = self.collectionView.adjustedContentInset;
    }
}

-(void)handleAutoScrollIfNeeded {
    if (self.results.count) {
        if (_needScrollToEdge) {
            [self handleAutoScrollToEdge];
        } else {
            [self handleAutoScrollToCurrentPreviewIndex];
            [self handleCellSelectionRefreshIfNeeded];
        }
    }
    _needScrollToEdge = NO;
}

-(void)handleAutoScrollToEdge {
    CGSize contentSize = [self.collectionView.collectionViewLayout collectionViewContentSize];
    if (contentSize.height > self.collectionView.bounds.size.height) {
        //            [self.collectionView setContentOffset:CGPointMake(0, contentSize.height - self.collectionView.bounds.size.height)];
        if (_firstAppear) {
            ///防止第一次进入时，无法滚动至底部（差20px）
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.results.count - 1 inSection:0] atScrollPosition:(UICollectionViewScrollPositionBottom) animated:NO];
            });
        } else {
            [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:self.results.count - 1 inSection:0] atScrollPosition:(UICollectionViewScrollPositionBottom) animated:NO];
        }
    } else {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0] atScrollPosition:(UICollectionViewScrollPositionTop) animated:NO];
    }
    _innerNotifyChangeIndex = -1;
}

-(void)handleAutoScrollToCurrentPreviewIndex {
    ///这里如果没有旋屏，才考虑直接滚动，如果旋屏了，应该在safeArea改变之后再滚动
    if (!_screenRotateNeedsResetPreviewIndex) {
        if (_innerNotifyChangeIndex >= 0) {
            if (_innerNotifyChangeIndex < self.results.count) {
                ///此处应该不在可见范围内才滚动，在可见范围内不动
                [self scrollIndexToCenterIfNeeded:_innerNotifyChangeIndex];
            }
            _innerNotifyChangeIndex = -1;
        }
    }
}

-(void)handleAutoScrollToCurrentPreviewIndexAfterRotate {
    if (_screenRotateNeedsResetPreviewIndex) {
        _screenRotateNeedsResetPreviewIndex = NO;
        if (_innerNotifyChangeIndex >= 0) {
            if (_innerNotifyChangeIndex < self.results.count) {
                ///这里无论在不在可见范围内都滚动至中间。因为屏幕发生了转动，即使转动之前在屏幕中不需要滚动，可能旋屏后就不在屏幕中了。所以强制改到屏幕中。
                [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:_innerNotifyChangeIndex inSection:0] atScrollPosition:(UICollectionViewScrollPositionCenteredVertically) animated:NO];
            }
            _innerNotifyChangeIndex = -1;
        } else {
            ///如果角标没有变，则找到之前屏幕中间位置的角标
            NSArray <UICollectionViewLayoutAttributes *>* attr = [self visibleAttributes];
            if (attr.count) {
                NSInteger centerIdx = (attr.count - 1) / 2;
                [self.collectionView scrollToItemAtIndexPath:attr[centerIdx].indexPath atScrollPosition:(UICollectionViewScrollPositionCenteredVertically) animated:NO];
            }
        }
    }
}

-(void)scrollIndexToCenterIfNeeded:(NSInteger)index {
    ///此处应该不在可见范围内才滚动，在可见范围内不动
    NSArray <UICollectionViewLayoutAttributes *>* attr = [self visibleAttributes];
    if (attr.count == 0 || index < attr.firstObject.indexPath.item || index > attr.lastObject.indexPath.item) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0] atScrollPosition:(UICollectionViewScrollPositionCenteredVertically) animated:NO];
    }
}

-(NSArray <UICollectionViewLayoutAttributes *>*)visibleAttributes {
    CGRect visibleFrame = (CGRect){self.collectionView.contentOffset,self.collectionView.bounds.size};
    if (@available(iOS 11.0,*)) {
        visibleFrame = UIEdgeInsetsInsetRect(visibleFrame, self.collectionView.adjustedContentInset);
    }
    
    return [self.collectionView.collectionViewLayout layoutAttributesForElementsInRect:visibleFrame];
}

-(void)handleCellSelectionRefreshIfNeeded {
    if (self.selectionManager.needsRefreshSelection) {
        [self selectVisibleCells];
        [self.selectionManager finishRefreshSelection];
    }
}

-(void)refreshGrid:(DWAlbumGridModel *)model {
    _gridModel = model;
    _results = model.results;
}

-(void)configCellSelect:(DWAlbumGridCell *)cell asset:(PHAsset *)asset {
    if (self.selectionManager) {
        cell.showSelectButton = YES;
        [self selectCell:cell withAsset:asset];
        __weak typeof(self) weakSelf = self;
        cell.onSelect = ^(DWAlbumGridCell *aCell) {
            [weakSelf handleSelectWithAsset:asset cell:aCell];
        };
    } else {
        cell.showSelectButton = NO;
        [cell setSelectAtIndex:0];
    }
}

-(void)selectCell:(DWAlbumGridCell *)cell withAsset:(PHAsset *)asset {
    NSInteger idx = [self.selectionManager indexOfSelection:asset];
    if (idx == NSNotFound) {
        if (self.selectionManager.reachMaxSelectCount) {
            idx = -1;
        } else {
            DWAlbumMediaOption mediaOpt = [DWAlbumMediaHelper mediaOptionForAsset:asset];
            if (![self.selectionManager validateMediaOption:mediaOpt]) {
                idx = -1;
            } else if (!self.selectionManager.multiTypeSelectionEnable && self.selectionManager.selectionOption != DWAlbumMediaOptionUndefine) {
                ///当不可混选，且已经有所选择时，要判断可选性
                ///已选的是图片类型
                if (self.selectionManager.selectionOption & DWAlbumMediaOptionImageMask) {
                    ///本资源不是图片类型，应该是不可选
                    if (!(mediaOpt & DWAlbumMediaOptionImageMask)) {
                        idx = -1;
                    } else {
                        idx = 0;
                    }
                } else {
                    ///本资源不是视频资源类型，应该是不可选
                    if (!(mediaOpt & DWAlbumMediaOptionVideoMask)) {
                        idx = -1;
                    } else {
                        idx = 0;
                    }
                }
            } else {
                idx = 0;
            }
        }
    } else {
        [self.selectionManager addUserInfo:cell atIndex:idx];
        ++idx;
    }
    [cell setSelectAtIndex:idx];
}

-(void)handleSelectWithAsset:(PHAsset *)asset cell:(DWAlbumGridCell *)cell {
    NSInteger idx = [self.selectionManager indexOfSelection:asset];
    BOOL needRefresh = NO;
    if (idx == NSNotFound) {
        if ([self.selectionManager addSelection:asset mediaIndex:cell.index mediaOption:[DWAlbumMediaHelper mediaOptionForAsset:asset]]) {
            if (self.selectionManager.reachMaxSelectCount) {
                [self selectVisibleCells];
            } else if (!self.selectionManager.multiTypeSelectionEnable && self.selectionManager.selections.count == 1) {
                ///如果不允许混合选择，在首次确定资源类型后，要刷新可见cell的可选性
                [self selectVisibleCells];
            } else {
                NSInteger index = self.selectionManager.selections.count;
                [self.selectionManager addUserInfo:cell atIndex:index - 1];
                [cell setSelectAtIndex:index];
            }
            needRefresh = YES;
        }
    } else {
        if (idx < self.selectionManager.selections.count) {
           
            if (self.selectionManager.reachMaxSelectCount) {
                [self.selectionManager removeSelectionAtIndex:idx];
                [self selectVisibleCells];
            } else {
                ///这种情况如果移除后，会影响可选性，所以刷新当前可见cell
                if (!self.selectionManager.multiTypeSelectionEnable && self.selectionManager.selections.count == 1) {
                    [self.selectionManager removeSelectionAtIndex:idx];
                    [self selectVisibleCells];
                } else {
                    ///两种情况，如果移除对位的话，只影响队尾，否则删除后需要更改对应idx后的序号
                    [self resetSelectionCellAtIndex:idx toIndex:0];
                    [self.selectionManager removeSelectionAtIndex:idx];
                    
                    for (NSInteger i = idx; i < self.selectionManager.selections.count; i++) {
                        [self resetSelectionCellAtIndex:i toIndex:i + 1];
                    }
                }
                
            }
            needRefresh = YES;
        }
    }
    
    if (needRefresh) {
        [self.topToolBar refreshSelection];
        [self.bottomToolBar refreshSelection];
    }
}

-(void)selectVisibleCells {
    NSArray <DWAlbumGridCell *>* visibleCells = self.collectionView.visibleCells;
    [visibleCells enumerateObjectsUsingBlock:^(DWAlbumGridCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self selectCell:obj withAsset:obj.model.asset];
    }];
}

-(void)resetSelectionCellAtIndex:(NSInteger)index toIndex:(NSInteger)toIndex {
    DWAlbumSelectionModel * model  = [self.selectionManager selectionModelAtIndex:index];
    NSInteger mediaIndex = [self.results indexOfObject:model.asset];
    DWAlbumGridCell * cellToRemove = (DWAlbumGridCell *)model.userInfo;
    if (cellToRemove && cellToRemove.index == mediaIndex && [self.collectionView.visibleCells containsObject:cellToRemove]) {
        [cellToRemove setSelectAtIndex:toIndex];
    }
}

-(void)loadRealPhoto {
    
    NSArray <DWAlbumGridCell *>* visibleCells = self.collectionView.visibleCells;
    [visibleCells enumerateObjectsUsingBlock:^(DWAlbumGridCell * _Nonnull cell, NSUInteger idx, BOOL * _Nonnull stop) {
        if (CGSizeEqualToSize(self.photoSize, cell.model.targetSize)) {
            return ;
        }
        PHAsset * asset = cell.model.asset;
        NSInteger index = [self.results indexOfObject:asset];
        cell.index = index;
        [self loadImageForAsset:asset targetSize:self.photoSize thumnail:NO completion:^(DWAlbumGridCellModel *model) {
            if (cell.index == index) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.model = model;
                });
            }
        }];
    }];
    
}

-(void)loadImageForAsset:(PHAsset *)asset targetSize:(CGSize)targetSize thumnail:(BOOL)thumnail completion:(DWGridViewControllerFetchCompletion)completion {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(gridController:fetchMediaForAsset:targetSize:thumnail:completion:)]) {
        [self.dataSource gridController:self fetchMediaForAsset:asset targetSize:targetSize thumnail:thumnail completion:completion];
    }
}

-(DWAlbumGridCell *)cellForAsset:(PHAsset *)asset atIndexPath:(NSIndexPath *)indexPath {
    DWAlbumGridCell * cell = nil;
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(gridViewController:cellForAsset:mediaOption:atIndex:)]) {
        cell = [self.dataSource gridViewController:self cellForAsset:asset mediaOption:[DWAlbumMediaHelper mediaOptionForAsset:asset] atIndex:indexPath.item];
    }
    if (!cell) {
        cell = [self.collectionView dequeueReusableCellWithReuseIdentifier:@"DefaultGridCellReuseIdentifier" forIndexPath:indexPath];
    }
    return cell;
}

#pragma mark --- collectionView delegate ---
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.results.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ///iOS 10.0以后新增了prefetch功能，这是个双刃剑。他可以预先在屏幕中不包含指定indexPath的时候去加载一部分数据等待被展示，从而提升滑动体验。但是这就造成开启此功能后，有一部分cell既不在visibleCells中，当他滚动进来的时候也不会走cellForItem（因为预先走过了）。这会导致一些动态刷新的状态不正确。
    ///例如本例中选择图片后想刷新当前屏幕中所以视频为不可选。使用visibleCells做当前屏幕刷新，更改状态，而不再屏幕中又预先走了cellForItem的cell即被遗漏，即使滚动出屏幕也无法通过cellForItem设置可选状态。
    
    ///为了解决这个问题，可以将状态的设置放置在willDisplayCell中，这样即可保证在cell出现前一定会被设置一次状态
    
    ///当然你也可以关于预加载功能，可以设置collectionView.prefetchingEnabled = NO;
    PHAsset * asset = [self.results objectAtIndex:indexPath.row];
    DWAlbumGridCell *cell = [self cellForAsset:asset atIndexPath:indexPath];;
    NSInteger originIndex = indexPath.item;
    cell.index = originIndex;
    
    ///再去去掉设置选择状态，已经移动至willDisplayCell代理中，具体原因上面写了
//    [self configCellSelect:cell asset:asset];

    ///通过速度、滚动、偏移量联合控制是否展示缩略图
    ///显示缩略图的情景应为快速拖动，故前两个条件为判断快速及拖动
    ///1.速度
    ///2.拖动
    ///还要排除即将滚动到边缘时，这时强制加载原图，因为边缘的减速很快，非正常减速，
    ///所以会在高速情况下停止滚动，此时我们希望尽可能的看到的不是缩略图，所以对边缘做判断
    ///3.滚动边缘
    BOOL thumnail = NO;
    if (self.velocity > 30 && (collectionView.isDecelerating || collectionView.isDragging) && ((collectionView.contentSize.height - collectionView.contentOffset.y > collectionView.bounds.size.height * 3) && (collectionView.contentOffset.y > collectionView.bounds.size.height * 2))) {
        thumnail = YES;
    }
    
    DWAlbumGridCellModel * media = [DWAlbumMediaHelper posterCacheForAsset:asset];
    if (media) {
        cell.model = media;
    } else {
        CGSize targetSize = thumnail ? self.thumnailSize : self.photoSize;
        [self loadImageForAsset:asset targetSize:targetSize thumnail:YES completion:^(DWAlbumGridCellModel *model) {
            if (!thumnail && model.media && model.asset) {
                [DWAlbumMediaHelper cachePoster:model withAsset:model.asset];
            }
            if (cell.index == originIndex) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    cell.model = model;
                });
            }
        }];
    }
    
    [cell setNeedsLayout];
    
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView willDisplayCell:(DWAlbumGridCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    ///这里设置一下可选状态，具体原因在cellForItem中有详细描述
    PHAsset * asset = [self.results objectAtIndex:indexPath.row];
    [self configCellSelect:cell asset:asset];
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(gridViewController:didSelectAsset:mediaOption:atIndex:)]) {
        PHAsset * asset = [self.results objectAtIndex:indexPath.item];
        DWAlbumMediaOption mediaOption = [DWAlbumMediaHelper mediaOptionForAsset:asset];
        [self.dataSource gridViewController:self didSelectAsset:asset mediaOption:mediaOption atIndex:indexPath.item];
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.velocity = fabs(scrollView.contentOffset.y - self.lastOffsetY);
    self.lastOffsetY = scrollView.contentOffset.y;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self loadRealPhoto];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self loadRealPhoto];
    }
}

-(void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(gridController:startCachingMediaForIndexes:targetSize:)]) {
        NSMutableIndexSet * indexes = [NSMutableIndexSet indexSet];
        [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [indexes addIndex:obj.row];
        }];
        [self.dataSource gridController:self startCachingMediaForIndexes:indexes targetSize:self.photoSize];
    }
    
}

-(void)collectionView:(UICollectionView *)collectionView cancelPrefetchingForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(gridController:stopCachingMediaForIndexes:targetSize:)]) {
        NSMutableIndexSet * indexes = [NSMutableIndexSet indexSet];
        [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [indexes addIndex:obj.row];
        }];
        [self.dataSource gridController:self stopCachingMediaForIndexes:indexes targetSize:self.photoSize];
    }
}

#pragma mark --- rotate delegate ---
-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.collectionView.dw_autoFixContentOffset = YES;
    ///这里要区分是不是在屏幕内进行旋屏
    if (_isShowing) {
        [self autoFixAdjustedContentInset];
    }
}

-(void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    ///这里如果是在屏幕外旋屏后进来才走的这里，要先恢复至指定角标的位置后，再设置frame。
    [self handleAutoScrollToCurrentPreviewIndexAfterRotate];
    self.collectionView.frame = self.view.bounds;
}

#pragma mark --- override ---
//-(void)loadView {
//    [super loadView];
//    self.view = self.collectionView;
//}

#pragma mark --- setter/getter ---

-(DWGridFlowLayout *)collectionViewLayout {
    if (!_collectionViewLayout) {
        _collectionViewLayout = [[DWGridFlowLayout alloc] init];
        _collectionViewLayout.itemSize = CGSizeMake(self.itemWidth, self.itemWidth);
    }
    return _collectionViewLayout;
}

-(DWFixAdjustCollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[DWFixAdjustCollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.collectionViewLayout];
        if (_clsCtn.count > 0) {
            [self.clsCtn enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                [_collectionView registerClass:obj forCellWithReuseIdentifier:key];
            }];
            [self.clsCtn removeAllObjects];
        }
        [_collectionView registerClass:[DWAlbumGridCell class] forCellWithReuseIdentifier:@"DefaultGridCellReuseIdentifier"];
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        if (@available(iOS 10.0,*)) {
            _collectionView.prefetchDataSource = self;
        }
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.clipsToBounds = NO;
        if (@available(iOS 11.0,*)) {
            _collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
        } else {
            self.automaticallyAdjustsScrollViewInsets = YES;
        }
    }
    return _collectionView;
}

-(UICollectionView *)gridView {
    return _collectionView;
}

-(NSMutableDictionary *)clsCtn {
    if (!_clsCtn) {
        _clsCtn = [NSMutableDictionary dictionary];
    }
    return _clsCtn;
}

@end

@implementation DWAlbumGridModel

@end
