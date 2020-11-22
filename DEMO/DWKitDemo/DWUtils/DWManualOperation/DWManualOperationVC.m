//
//  DWManualOperationVC.m
//  DWKitDemo
//
//  Created by Wicky on 2019/9/7.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWManualOperationVC.h"
#import <DWKit/DWManualOperation.h>

@interface DWManualOperationVC ()

@property (nonatomic ,strong) DWManualOperation * manual;

@property (nonatomic ,strong) NSOperationQueue * queue;

@end

@implementation DWManualOperationVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.manual = [[DWManualOperation alloc] init];
    self.manual.maxConcurentCount = 2;
    
    [self.manual addExecutionHandler:^(DWManualOperation *op) {
        NSLog(@"执行第一个耗时任务");
    }];
    
    [self.manual addExecutionHandler:^(DWManualOperation *op) {
        NSLog(@"执行第二个耗时任务");
    }];
    
    [self.manual addExecutionHandler:^(DWManualOperation *op) {
        NSLog(@"执行第三个耗时任务");
    }];
    
    NSBlockOperation * finishOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"手动任务执行完毕后自动指定了后续任务。");
    }];
    [finishOperation addDependency:self.manual];
    
    [self.queue addOperation:finishOperation];
    [self.queue addOperation:self.manual];
    
    [self setupUI];
}

-(void)setupUI {
    norBtn(@"手动完成任务", self, @selector(btnAction:), self.view, -50);
    norBtn(@"中途取消任务", self, @selector(cancelAction:), self.view, 50);
}

#pragma mark --- action ---
-(void)btnAction:(UIButton *)sender {
    NSLog(@"手动触发了ManualOperation");
    [self.manual finishOperation];
}

-(void)cancelAction:(UIButton *)sender {
    NSLog(@"手动触发了取消");
    [self.manual cancel];
}

#pragma mark --- setter/getter ---
-(NSOperationQueue *)queue {
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}

@end
