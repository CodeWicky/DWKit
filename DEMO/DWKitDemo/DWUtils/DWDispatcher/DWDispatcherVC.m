//
//  DWDispatcherVC.m
//  DWKitDemo
//
//  Created by Wicky on 2019/9/28.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWDispatcherVC.h"
#import <DWKit/DWDispatcher.h>

@interface DWDispatcherVC ()

@property (nonatomic ,strong) DWDispatcher * dispatcher;

@end

@implementation DWDispatcherVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    norBtn(@"派发一次事件", self, @selector(dispatchAction:), self.view, 0);
}

-(void)dispatchAction:(UIButton *)sender {
    static int i = 0;
    [self.dispatcher dispatchObject:@(i)];
    i++;
}

-(DWDispatcher *)dispatcher {
    if (!_dispatcher) {
        _dispatcher = [DWDispatcher dispatcherWithTimeInterval:0.5 idleTimesToHangUp:10 handler:^(NSArray * _Nonnull items) {
            NSLog(@"%@",items);
        }];
    }
    return _dispatcher;
}

@end
