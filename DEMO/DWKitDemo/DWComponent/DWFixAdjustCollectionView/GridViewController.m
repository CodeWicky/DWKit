//
//  GridViewController.m
//  DWKitDemo
//
//  Created by Wicky on 2020/2/23.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "GridViewController.h"
#import <DWKit/DWFixAdjustCollectionView.h>

@interface GridFlowLayout : UICollectionViewFlowLayout

@end

@implementation GridFlowLayout

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

@interface GridCell : UICollectionViewCell

@property (nonatomic ,strong) UILabel * lb;

@end

@implementation GridCell

-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addSubview:self.lb];
    }
    return self;
}

-(UILabel *)lb {
    if (!_lb) {
        _lb = [[UILabel alloc] initWithFrame:self.bounds];
        _lb.textColor = [UIColor blackColor];
        _lb.textAlignment = NSTextAlignmentCenter;
        _lb.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _lb;
}

@end

@interface GridViewController ()<UICollectionViewDataSource>

@property (nonatomic ,strong) DWFixAdjustCollectionView * col;

@end

@implementation GridViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.col];
    self.title = @"展示一个网格视图";
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 300;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    GridCell * cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.lb.text = [NSString stringWithFormat:@"%ld",indexPath.item];
    cell.backgroundColor = randomColor();
    return cell;
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    self.col.dw_autoFixContentOffset = YES;
    self.col.dw_useAutoFixAdjustedContentInset = YES;
    if (@available(iOS 11.0,*)) {
        self.col.dw_autoFixAdjustedContentInset = self.col.adjustedContentInset;
    }
}

-(void)viewSafeAreaInsetsDidChange {
    [super viewSafeAreaInsetsDidChange];
    self.col.frame = self.view.bounds;
}

UIColor * randomColor() {
   CGFloat red = arc4random() % 255 / 255.0;
   CGFloat green = arc4random() % 255 / 255.0;
   CGFloat blue = arc4random() % 255 / 255.0;
   UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:1];
   return color;
}

-(DWFixAdjustCollectionView *)col {
    if (!_col) {
        GridFlowLayout * layout = [GridFlowLayout new];
        layout.itemSize = CGSizeMake(120, 120);
        _col = [[DWFixAdjustCollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
        _col.dataSource = self;
        [_col registerClass:[GridCell class] forCellWithReuseIdentifier:@"cell"];
        if (@available(iOS 11.0,*)) {
            _col.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAlways;
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            self.automaticallyAdjustsScrollViewInsets = NO;
#pragma clang diagnostic pop
        }
    }
    return _col;
}

@end
