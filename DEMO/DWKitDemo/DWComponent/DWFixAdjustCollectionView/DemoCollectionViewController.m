//
//  DemoCollectionViewController.m
//  DWKitDemo
//
//  Created by Wicky on 2020/2/23.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DemoCollectionViewController.h"
#import <DWKit/DWFixAdjustCollectionView.h>

@interface DemoAutoFullScreenLayout : UICollectionViewFlowLayout

@end

@implementation DemoAutoFullScreenLayout

-(void)prepareLayout {
    [super prepareLayout];
    self.itemSize = self.collectionView.bounds.size;
}

@end

@interface DemoCollectionViewController ()<UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>

@property (nonatomic ,strong) Class colCls;

@property (nonatomic ,strong) UICollectionView * col;

@end

@implementation DemoCollectionViewController

-(instancetype)initWithCollectionViewClass:(Class)cls {
    if (cls == NULL) {
        return nil;
    }
    
    if (self = [super init]) {
        _colCls = cls;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = NSStringFromClass(self.colCls);
    [self.view addSubview:self.col];
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 5;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithWhite:indexPath.item % 2 alpha:1];
    return cell;
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    if ([self.col isKindOfClass:[DWFixAdjustCollectionView class]]) {
        ((DWFixAdjustCollectionView *)self.col).dw_autoFixContentOffset = YES;
    }
}

-(UICollectionView *)col {
    if (!_col) {
        DemoAutoFullScreenLayout * layout = [[DemoAutoFullScreenLayout alloc] init];
        layout.minimumLineSpacing = 0;
        layout.minimumInteritemSpacing = 0;
        layout.itemSize = self.view.bounds.size;
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        _col = [((UICollectionView *)[self.colCls alloc]) initWithFrame:self.view.bounds collectionViewLayout:layout];
        _col.dataSource = self;
        _col.delegate = self;
        _col.pagingEnabled = YES;
        [_col registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        _col.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        if (@available(iOS 11.0,*)) {
                _col.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            } else {
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
                self.automaticallyAdjustsScrollViewInsets = NO;
        #pragma clang diagnostic pop
            }
    }
    return _col;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
