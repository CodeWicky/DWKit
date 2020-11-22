//
//  DWDateUtilsVC.m
//  DWKitDemo
//
//  Created by Wicky on 2020/5/15.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWDateUtilsVC.h"
#import <DWKit/NSDate+DWDateUtils.h>
@interface DWDateUtilsVC ()

@end

@implementation DWDateUtilsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

-(void)configActions {
    self.actions = @[
        actionWithTitle(@selector(logDate), @"打印当前日期的相关信息"),
    ];
}

-(void)logDate {
    NSDate * currentDate = [NSDate date];
    NSLog(@"今天是%zd年%zd月%zd日，现在是%zd时%zd分%zd秒，今天周%zd，今天是今年的第%zd天，这个月一共有%zd天，这周是这个月的第%zd周，是今年的第%zd周，今年%@闰年哟~",currentDate.year,currentDate.month,currentDate.day,currentDate.hour,currentDate.minute,currentDate.second,(currentDate.weekDay > 1) ? (currentDate.weekDay - 1) : 7,currentDate.dayOfCurrentYear,currentDate.dayCountOfCurrentMonth,currentDate.weekOfCurrentMonth,currentDate.weekOfCurrentYear,currentDate.isLeapYear?@"是":@"不是");
}

@end
