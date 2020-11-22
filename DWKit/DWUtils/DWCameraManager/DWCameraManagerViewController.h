//
//  DWCameraManagerViewController.h
//  DWCameraManager
//
//  Created by Wicky on 2020/6/22.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DWCameraManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface DWCameraManagerViewController : UIViewController<DWCameraManagerDelegate>

@property (nonatomic ,strong ,readonly) DWCameraManager * cameraManager;

#pragma mark --- hook method ---
-(DWCameraManager *)generateCameraManager;

-(void)cameraManagerReadyForUsage;

@end

NS_ASSUME_NONNULL_END
