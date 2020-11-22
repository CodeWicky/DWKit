//
//  DWTransactionVC.m
//  DWKitDemo
//
//  Created by Wicky on 2019/9/13.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWTransactionVC.h"
#import <DWKit/DWTransaction.h>

@interface DWTransactionVC ()

@property (nonatomic ,strong) DWTransaction * trans;

@end

@implementation DWTransactionVC

- (void)viewDidLoad {
    [super viewDidLoad];
    norBtn(@"RunLoop空闲任务", self, @selector(transactionAction:), self.view, -150);
    norBtn(@"延时任务", self, @selector(waitAction:), self.view, -75);
    norBtn(@"取消延时任务", self, @selector(cancelWaitAction:), self.view, 0);
    norBtn(@"增加计数任务", self, @selector(countAction:), self.view, 75);
    norBtn(@"完成一个计数任务", self, @selector(finishAction:), self.view, 150);
}

-(void)transactionAction:(UIButton *)sender {
    [[DWTransaction transactionWithCompletion:^{
        NSLog(@"我实在RunLoop空闲时触发的任务");
    }] commit];
}

-(void)waitAction:(UIButton *)sender {
    __weak typeof(self)weakSelf = self;
    self.trans = [DWTransaction waitUtil:5 completion:^{
        NSLog(@"我是延时任务，延时时间到了，我执行了。");
        weakSelf.trans = nil;
    }];
}

-(void)cancelWaitAction:(UIButton *)sender {
    if (self.trans) {
        __weak typeof(self)weakSelf = self;
        [self.trans cancelWithHandler:^{
            NSLog(@"我取消了延时任务！");
            weakSelf.trans = nil;
        }];
    }
}

-(void)countAction:(UIButton *)sender {
    if (!self.trans) {
        self.trans = [DWTransaction configWithMissionCompletionHandler:^{
            NSLog(@"所有任务都完成了哦~");
        }];
        __weak typeof(self)weakSelf = self;
        [self.trans addMissionCompletionHandler:^{
            NSLog(@"我是后续添加的所有任务完成后触发的回调~");
            weakSelf.trans = nil;
        }];
    }
    NSLog(@"开始了一个任务");
    [self.trans startAnMission];
}

-(void)finishAction:(UIButton *)sender {
    NSLog(@"完成了一个任务");
    [self.trans finishAnMission];
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
