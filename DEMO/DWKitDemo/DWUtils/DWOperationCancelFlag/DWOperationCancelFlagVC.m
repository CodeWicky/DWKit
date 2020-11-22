//
//  DWOperationCancelFlagVC.m
//  DWKitDemo
//
//  Created by Wicky on 2019/9/7.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWOperationCancelFlagVC.h"
#import <DWKit/DWOperationCancelFlag.h>
@interface DWOperationCancelFlagVC ()

@property (nonatomic ,strong) DWOperationCancelFlag * flag;

@property (nonatomic ,copy) CancelFlag cancelFlag;

@end

@implementation DWOperationCancelFlagVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    norBtn(@"start", self,@selector(startAction:),self.view,-250);
    norBtn(@"cancel", self, @selector(cancelAction:), self.view,-150);
    norBtn(@"settle(获取一个任务标志位)", self,@selector(settleAction:), self.view, -50);
    norBtn(@"restart(同时可获取一个任务标志位)", self, @selector(restartAction:), self.view,50);
    norBtn(@"检测当前任务状态", self, @selector(testAction:), self.view,150);
    norBtn(@"检测之前获取任务标志位的任务状态", self, @selector(test2Action:), self.view,250);
    
}

#pragma mark --- btn action ---
-(void)startAction:(UIButton *)sender {
    NSLog(@"开始执行一个任务");
    [self.flag start];
}

-(void)cancelAction:(UIButton *)sender {
    NSLog(@"取消当前任务");
    [self.flag cancel];
}

-(void)settleAction:(UIButton *)sender {
    NSLog(@"获取当前任务的标志位");
    self.cancelFlag = [self.flag settleAnCancelFlag];
}

-(void)restartAction:(UIButton *)sender {
    NSLog(@"取消之前的任务并重新开始一个新的任务，同时获取标志位");
    self.cancelFlag = [self.flag restartAnCancelFlag];
}

-(void)testAction:(UIButton *)sender {
    if (self.flag.cancelFlag) {
        if (!CancelFlag(self.flag)) {
            NSLog(@"当前任务正在进行");
        } else {
            NSLog(@"当前任务已经被取消");
        }
    } else {
        NSLog(@"当前无任务在执行，至少执行以此start");
    }
}

-(void)test2Action:(UIButton *)sender {
    if (self.cancelFlag) {
        if (!self.cancelFlag()) {
            NSLog(@"之前获取任务标志位仍在执行");
        } else {
            NSLog(@"之前获取任务标志位已经被取消");
        }
    } else {
        NSLog(@"当前未获取任务标志位，通过settle或者restart可获得任务标志位");
    }
}

#pragma mark --- setter/getter ---
-(DWOperationCancelFlag *)flag {
    if (!_flag) {
        _flag = [DWOperationCancelFlag new];
    }
    return _flag;
}

@end
