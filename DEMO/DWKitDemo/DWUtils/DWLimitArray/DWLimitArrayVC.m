//
//  DWLimitArrayVC.m
//  DWKitDemo
//
//  Created by Wicky on 2020/6/1.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWLimitArrayVC.h"
#import <DWKit/DWLimitArray.h>

@interface DWLimitArrayVC ()

@property (nonatomic ,strong) DWLimitArray * array;

@end

@implementation DWLimitArrayVC

- (void)viewDidLoad {
    [super viewDidLoad];
    norBtn(@"添加元素", self, @selector(addObject), self.view, -50);
    norBtn(@"打印数组", self, @selector(log), self.view, 50);
}

-(void)addObject {
    static int i = 0;
    [self.array addObject:@(i)];
    i++;
}

-(void)log {
    NSLog(@"%@",self.array);
}

#pragma mark --- setter/getter ---
-(DWLimitArray *)array {
    if (!_array) {
        _array = [DWLimitArray arrayWithCapacity:10];
    }
    return _array;
}

@end
