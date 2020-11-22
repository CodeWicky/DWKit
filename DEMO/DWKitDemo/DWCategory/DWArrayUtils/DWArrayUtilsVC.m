//
//  DWArrayUtilsVC.m
//  DWKitDemo
//
//  Created by Wicky on 2019/9/18.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWArrayUtilsVC.h"
#import <DWKit/NSArray+DWArrayUtils.h>

@interface DWArrayUtilsVC ()

@property (nonatomic ,strong) NSArray * oriArr;

@end

@implementation DWArrayUtilsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    norBtn(@"过滤数组中的奇数", self, @selector(filterAction:), self.view, -150);
    norBtn(@"寻找原始数组中不被指定数组包含的元素", self, @selector(complementaryAction:), self.view, -75);
    norBtn(@"以堆排序对5-2-1-3-4排序", self, @selector(heapSortAction:), self.view, 0);
    norBtn(@"以属性直接获取数组的相关数值", self, @selector(keyPathAction:), self.view, 75);
    norBtn(@"以二分法在数组中查找指定元素", self, @selector(binarySearchAction:), self.view, 150);
}

-(void)filterAction:(UIButton *)sender {
    NSLog(@"%@",[self.oriArr dw_filteredArrayUsingFilter:^BOOL(id obj, NSUInteger idx, NSUInteger count, BOOL *stop) {
        return [obj integerValue] % 2 == 0;
    }]);
}

-(void)complementaryAction:(UIButton *)sender {
    NSLog(@"%@",[self.oriArr dw_complementaryArrayWithArr:@[@"3",@"4",@"5",@"6",@"7"] usingEqualBlock:^BOOL(id obj1, id obj2) {
        return [obj1 integerValue] == [obj2 integerValue];
    }]);
}

-(void)heapSortAction:(UIButton *)sender {
    NSLog(@"事实上堆排序更适合排列大部分数据为有序数据的数组。例如在有序数组末尾新增添一个元素后的重新排序。");
    NSLog(@"%@",[@[@5,@2,@1,@3,@4] dw_sortedArrayInHeapUsingComparator:DWComparatorNumberDescending]);
}

-(void)keyPathAction:(UIButton *)sender {
    NSLog(@"原始数组的平均数为%@",[self.oriArr dw_getObjectWithKeyPath:nil action:(DWArrayKeyPathActionTypeAverage)]);
}

-(void)binarySearchAction:(UIButton *)sender {
    NSLog(@"使用二分法查找，请广义上保证数组为有序数组");
    __block NSUInteger idx = NSNotFound;
    [self.oriArr dw_binarySearchWithCondition:^NSComparisonResult(id obj, NSUInteger currentIdx, BOOL *stop) {
        if ([obj isEqualToNumber:@2]) {
            idx = currentIdx;
            return NSOrderedSame;
        } else if ([obj integerValue] > 2) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }];
    if (idx == NSNotFound) {
        NSLog(@"未找到@2");
    } else {
        NSLog(@"元素@2的角标为%lu",idx);
    }
}

-(NSArray *)oriArr {
    if (!_oriArr) {
        _oriArr = @[@1,@2,@3,@4,@5];
    }
    return _oriArr;
}

@end
