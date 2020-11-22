//
//  DWFixAdjustCollectionViewVC.m
//  DWKitDemo
//
//  Created by Wicky on 2020/2/23.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWFixAdjustCollectionViewVC.h"
#import <DWKit/DWFixAdjustCollectionView.h>
#import "DemoCollectionViewController.h"
#import "GridViewController.h"
@interface DWFixAdjustCollectionViewVC ()

@end

@implementation DWFixAdjustCollectionViewVC

- (void)viewDidLoad {
    [super viewDidLoad];
    norBtn(@"点我查看使用背景", self, @selector(noteAction:), self.view, -150);
    norBtn(@"使用UICollectionView", self, @selector(UICollectionViewAction:), self.view, -50);
    norBtn(@"使用DWFixAdjustCollectionView", self, @selector(DWFixAdjustCollectionViewAction:), self.view, 50);
    norBtn(@"使用DWFixAdjustCollectionView - 复杂", self, @selector(complexAction:), self.view, 150);
}

-(void)noteAction:(UIButton *)sender {
    NSLog(@"在旋转屏幕的时候，由于contentSize改变了，系统会默认调用此内部方法，然而当当前展示的cell时collectionView的最后一个cell时，若此时旋屏，在默认调整一次contentOffset后系统又自动触发此方法，连续两次有动画的调整位置且时间上具有重叠，导致位置错误。DWFixAdjustCollectionView的用途就是在不同情况下，最大程度保证你的collectionView在旋转屏幕时，你所看到的cell是相同的或大部分是相同的。");
}

-(void)UICollectionViewAction:(UIButton *)sender {
    DemoCollectionViewController * vc = [[DemoCollectionViewController alloc] initWithCollectionViewClass:[UICollectionView class]];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)DWFixAdjustCollectionViewAction:(UIButton *)sender {
    DemoCollectionViewController * vc = [[DemoCollectionViewController alloc] initWithCollectionViewClass:[DWFixAdjustCollectionView class]];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

-(void)complexAction:(UIButton *)sender {
    GridViewController * vc = [GridViewController new];
    [self.navigationController pushViewController:vc animated:YES];
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
