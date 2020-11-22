//
//  DWDeviceUtilsVC.m
//  DWKitDemo
//
//  Created by Wicky on 2019/9/19.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWDeviceUtilsVC.h"
#import <DWKit/UIDevice+DWDeviceUtils.h>

@interface DWDeviceUtilsVC ()

@end

@implementation DWDeviceUtilsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    norBtn(@"打印设备信息", self, @selector(logAction:), self.view, 0);
}

-(void)logAction:(UIButton *)sender {
    
    NSLog(@"当前工程Build号:%@",[UIDevice dw_projectBuildNo]);
    NSLog(@"当前工程BundleID:%@",[UIDevice dw_projectBundleId]);
    NSLog(@"当前工程工程名称:%@",[UIDevice dw_projectDisplayName]);
    NSLog(@"当前工程版本号:%@",[UIDevice dw_projectVersion]);
    NSLog(@"当前设备UUID:%@",[UIDevice dw_deviceUUID]);
    NSLog(@"当前设备别名:%@",[UIDevice dw_deviceUserName]);
    NSLog(@"当前设备名:%@",[UIDevice dw_deviceName]);
    NSLog(@"当前设备系统版本:%@",[UIDevice dw_deviceSystemVersion]);
    NSLog(@"当前设备型号:%@",[UIDevice dw_deviceModel]);
    NSLog(@"当前设备具体型号:%@",[UIDevice dw_deviceDetailModel]);
    NSLog(@"当前设备平台号:%@",[UIDevice dw_devicePlatform]);
    NSLog(@"当前设备CPU架构:%@",[UIDevice dw_deviceCPUCore]);
    NSLog(@"当前手机运营商:%@",[UIDevice dw_mobileOperator]);
    NSLog(@"当前开发SDK版本:%@",[UIDevice dw_developSDKVersion]);
    NSLog(@"当前手机电量:%f",[UIDevice dw_batteryVolumn]);
}

@end
