//
//  DemoBaseViewController.m
//  DWKitDemo
//
//  Created by Wicky on 2019/9/7.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DemoBaseViewController.h"

@interface DemoBaseViewController ()

@end

@implementation DemoBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    NSString * clazzStr = NSStringFromClass([self class]);
    self.title = [clazzStr substringToIndex:clazzStr.length - 2];
}

UIButton * norBtn(NSString * title,id target,SEL selector,UIView * superView,CGFloat offsetY) {
    UIButton * btn = [UIButton buttonWithType:(UIButtonTypeCustom)];
    [btn setFrame:CGRectMake(0, 0, 350, 50)];
    btn.backgroundColor = [UIColor lightGrayColor];
    btn.layer.cornerRadius = 25;
    [btn setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
    [btn setTitle:title forState:(UIControlStateNormal)];
    [btn addTarget:target action:selector forControlEvents:(UIControlEventTouchUpInside)];
    [superView addSubview:btn];
    btn.center = CGPointMake(superView.center.x, superView.center.y + offsetY);
    return btn;
}

@end
