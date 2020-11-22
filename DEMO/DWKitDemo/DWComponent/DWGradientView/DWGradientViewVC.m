//
//  DWGradientViewVC.m
//  DWKitDemo
//
//  Created by Wicky on 2020/5/15.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWGradientViewVC.h"
#import <DWKit/DWGradientView.h>

@interface DWGradientViewVC ()

@property (nonatomic ,strong) DWGradientView * gradientView;

@end

@implementation DWGradientViewVC

-(void)loadView {
    [super loadView];
    self.view = self.gradientView;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    self.mainTab.hidden = YES;
}

#pragma mark --- setter/getter ---
-(DWGradientView *)gradientView {
    if (!_gradientView) {
        _gradientView = [[DWGradientView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _gradientView.colors = @[(id)[UIColor orangeColor].CGColor,(id)[UIColor purpleColor].CGColor];
        _gradientView.locations = @[@0,@1];
        _gradientView.startPoint = CGPointZero;
        _gradientView.endPoint = CGPointMake(1, 1);
    }
    return _gradientView;
}

@end
