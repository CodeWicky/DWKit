//
//  DWInsetLabelVC.m
//  DWKitDemo
//
//  Created by Wicky on 2020/1/2.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWLabelVC.h"
#import <DWKit/DWLabel.h>

@interface DWLabelVC ()

@end

@implementation DWLabelVC

- (void)viewDidLoad {
    [super viewDidLoad];
    DWLabel * lb = [DWLabel new];
    lb.backgroundColor = [UIColor yellowColor];
    lb.text = @"程序员里我最帅";
    lb.marginInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    lb.touchPaddingInsets = UIEdgeInsetsMake(100, 100, 100, 100);
    lb.textColor = [UIColor blackColor];
    lb.userInteractionEnabled = YES;
    lb.numberOfLines = 0;
    lb.maxSize = CGSizeMake(40,0);
    [self.view addSubview:lb];
    
    [lb addAction:^(DWLabel * _Nonnull label) {
        NSLog(@"hello,hello");
    }];
    
    [lb sizeToFit];
    lb.center = self.view.center;
}

-(void)tapAction {
    NSLog(@"hello");
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
