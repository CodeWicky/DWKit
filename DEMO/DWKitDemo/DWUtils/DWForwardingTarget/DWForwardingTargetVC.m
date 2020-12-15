//
//  DWForwardingTargetVC.m
//  DWKitDemo
//
//  Created by Wicky on 2020/12/15.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWForwardingTargetVC.h"
#import <DWKit/DWForwardingTarget.h>
@interface DWForwardingTargetVC ()

@end

@implementation DWForwardingTargetVC

- (void)viewDidLoad {
    [super viewDidLoad];
    [DWForwardingTarget setDebugAssertEnable:NO];
    norBtn(@"点击制造一个崩溃", self, NSSelectorFromString(@"gotoAnCrash"), self.view, 0);
}

-(id)forwardingTargetForSelector:(SEL)aSelector {
    if (aSelector == NSSelectorFromString(@"gotoAnCrash")) {
        return [DWForwardingTarget forwardingTargetForSelector:aSelector];
    }
    return [super forwardingTargetForSelector:aSelector];
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
