//
//  DWTaskQueueVC.m
//  DWKitDemo
//
//  Created by Wicky on 2020/6/1.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWTaskQueueVC.h"
#import <DWKit/DWTaskQueue.h>
@interface DWTaskQueueVC ()

@property (nonatomic ,strong) DWTaskQueue * taskQueue;

@end

@implementation DWTaskQueueVC

- (void)viewDidLoad {
    [super viewDidLoad];
    norBtn(@"添加任务至队列", self,@selector(addTask) , self.view, - 100);
    norBtn(@"完成队列头部的第一个任务", self, @selector(finishAnTask), self.view, 0);
    norBtn(@"清除队列中的所有任务", self, @selector(resetAllTask), self.view, 100);
}

-(void)addTask {
    static int i = 0;
    if (i % 5 == 0) {
        [self.taskQueue enqueue:nil];
    } else {
        [self.taskQueue enqueue:@(i)];
    }
    i++;
}

-(void)finishAnTask {
    [self.taskQueue dequeue];
}

-(void)resetAllTask {
    [self.taskQueue reset];
}

-(void)doTask:(id)userInfo {
    NSLog(@"Do task:%@",userInfo);
}

#pragma mark --- setter/getter ---
-(DWTaskQueue *)taskQueue {
    if (!_taskQueue) {
        __weak typeof(self) weakSelf = self;
        _taskQueue = [DWTaskQueue taskQueueWithConcurrentCount:3 handler:^(id userInfo) {
            [weakSelf doTask:userInfo];
        }];
        [_taskQueue configTaskQueueEmptyHandler:^(BOOL finish) {
            NSLog(@"Task queue empty by finish:%d",finish);
        }];
    }
    return _taskQueue;
}

@end
