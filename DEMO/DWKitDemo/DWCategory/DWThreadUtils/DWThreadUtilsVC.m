//
//  DWThreadUtilsVC.m
//  DWKitDemo
//
//  Created by Wicky on 2020/3/30.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWThreadUtilsVC.h"
#import <DWKit/NSThread+DWThreadUtils.h>

@interface DWThreadUtilsVC ()

@end

@implementation DWThreadUtilsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    norBtn(@"主线程主队列", self, @selector(mainQueue), self.view, -150);
    norBtn(@"主线程子队列", self, @selector(otherQueue), self.view, -50);
    norBtn(@"回到主队列", self, @selector(doOnMainQueue), self.view, 50);
    norBtn(@"回到子队列", self, @selector(doOnGlobalQueue), self.view, 150);
}

-(void)mainQueue {
    [self log:dispatch_get_global_queue(0, 0) index:0];
}

-(void)otherQueue {
    dispatch_queue_t otherQueue = dispatch_queue_create("com.custom.queue", NULL);
    dispatch_sync(otherQueue, ^{
        [self log:otherQueue index:0];
    });
}

-(void)doOnMainQueue {
    [self log:dispatch_get_main_queue() index:0];
    dispatch_queue_t q = dispatch_get_global_queue(0, 0);
    dispatch_sync(q, ^{
        [self log:q index:1];
        [NSThread performActionOnMainQueue:^{
            [self log:q index:2];
        }];
        [self log:q index:3];
    });
    [self log:q index:4];
    [NSThread performActionOnMainQueue:^{
        [self log:dispatch_get_main_queue() index:5];
    }];
}

-(void)doOnGlobalQueue {
    [self log:dispatch_get_main_queue() index:0];
    dispatch_queue_t q = dispatch_get_global_queue(0, 0);
    [NSThread performActionOnQueue:q action:^{
        [self log:q index:1];
        [NSThread performActionOnQueue:q action:^{
            [self log:q index:2];
        }];
        [self log:q index:3];
    }];
    [self log:q index:4];
}

-(void)log:(dispatch_queue_t)targetQueue index:(NSInteger)index{
    NSLog(@"%ld - MainThread:%d - MainQueue:%d - TargetQueue:(%@ : %d)",index,[NSThread isMainThread],[NSThread currentThread].isMainQueue,targetQueue,[NSThread isInQueue:targetQueue]);
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
