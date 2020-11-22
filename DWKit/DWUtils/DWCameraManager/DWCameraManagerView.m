//
//  DWCameraManagerView.m
//  DWCameraManager
//
//  Created by Wicky on 2020/6/19.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWCameraManagerView.h"

@implementation DWCameraManagerView

#pragma mark --- tool method ---
-(void)setup {
    self.contentMode = UIViewContentModeScaleAspectFit;
}

#pragma mark --- override ---
-(instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self setup];
    }
    return self;
}

+(Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

-(AVCaptureSession *)session {
    return self.previewLayer.session;
}

-(void)setSession:(AVCaptureSession *)session {
    self.previewLayer.session = session;
}

-(void)setContentMode:(UIViewContentMode)contentMode {
    switch (contentMode) {
        case UIViewContentModeScaleToFill:
        {
            self.previewLayer.videoGravity = AVLayerVideoGravityResize;
        }
            break;
        case UIViewContentModeScaleAspectFill:
        {
            self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        }
            break;
        default:
        {
            self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        }
            break;
    }
    
}

-(UIViewContentMode)contentMode {
    if ([self.previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        return UIViewContentModeScaleAspectFill;
    } else if ([self.previewLayer.videoGravity isEqualToString:AVLayerVideoGravityResize]) {
        return UIViewContentModeScaleToFill;
    } else {
        return UIViewContentModeScaleAspectFit;
    }
}

-(AVCaptureVideoPreviewLayer *)previewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

@end
