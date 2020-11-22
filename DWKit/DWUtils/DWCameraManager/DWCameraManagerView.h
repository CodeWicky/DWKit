//
//  DWCameraManagerView.h
//  DWCameraManager
//
//  Created by Wicky on 2020/6/19.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DWCameraManagerView : UIView

@property (nonatomic ,strong) AVCaptureSession * session;

@property (nonatomic ,strong ,readonly) AVCaptureVideoPreviewLayer * previewLayer;

@end

NS_ASSUME_NONNULL_END
