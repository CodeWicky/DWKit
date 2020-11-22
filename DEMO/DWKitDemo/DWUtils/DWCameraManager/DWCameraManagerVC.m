//
//  DWCameraManagerVC.m
//  DWKitDemo
//
//  Created by Wicky on 2020/6/28.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWCameraManagerVC.h"
#import <Masonry.h>

@interface DWCameraManagerVC ()

@property (nonatomic ,strong) UIButton * captureBtn;

@property (nonatomic ,strong) UIButton * toggleCameraBtn;

@property (nonatomic ,strong) UIButton * toggleCaptureModeBtn;

@property (nonatomic ,strong) UIButton * toggleLiveBtn;

@property (nonatomic ,strong) UIButton * toggleLightBtn;

@property (nonatomic ,strong) UIButton * toggleTorchBtn;

@property (nonatomic ,strong) UIImageView * focusImgV;

@end

@implementation DWCameraManagerVC

#pragma mark --- life cycle ---
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    NSString * clazzStr = NSStringFromClass([self class]);
    self.title = [clazzStr substringToIndex:clazzStr.length - 2];
    self.cameraManager.previewView.contentMode = UIViewContentModeScaleAspectFill;
    [self.cameraManager toggleAutoSaveToLibrary:YES];
    [self setupUI];
    [self setupConstraints];
}

#pragma mark --- cameraVC hook ---
-(void)cameraManagerReadyForUsage {
    if (self.cameraManager.isLivePhotoSupported) {
        [self.toggleLiveBtn setTitle:@"Live On" forState:(UIControlStateNormal)];
    } else {
        [self.toggleLiveBtn setTitle:@"Live Off" forState:(UIControlStateNormal)];
    }
}

#pragma mark --- tool method ---
-(void)setupUI {
    [self.view addSubview:self.captureBtn];
    [self.view addSubview:self.toggleCameraBtn];
    [self.view addSubview:self.toggleCaptureModeBtn];
    [self.view addSubview:self.toggleLiveBtn];
    [self.view addSubview:self.toggleLightBtn];
    [self.view addSubview:self.toggleTorchBtn];
    [self.view addSubview:self.focusImgV];
}

-(void)setupConstraints {
    [self.captureBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(64, 64));
        make.centerX.mas_equalTo(self.view.mas_centerX);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).with.offset(-20);
    }];
    
    [self.toggleCameraBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(32, 28));
        make.centerY.mas_equalTo(self.captureBtn.mas_centerY);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight).with.offset(-30);
    }];
    
    [self.toggleCaptureModeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(38, 38));
        make.centerY.mas_equalTo(self.captureBtn.mas_centerY);
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).with.offset(30);
    }];
    
    [self.toggleLiveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).with.offset(30);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight).with.offset(-20);
    }];
    
    [self.toggleLightBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.mas_equalTo(CGSizeMake(38, 38));
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).with.offset(30);
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft).with.offset(30);
    }];
    
    [self.toggleTorchBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(38, 38));
        make.centerX.mas_equalTo(self.view.mas_centerX);
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).with.offset(30);
    }];
}

#pragma mark --- camera delegate ---
-(void)cameraManager:(DWCameraManager *)cameraManager willBeginCapturingWithPhotoSettings:(AVCapturePhotoSettings *)photoSettings {
    AudioServicesDisposeSystemSoundID(1108);
}

-(void)cameraManager:(DWCameraManager *)cameraManager focusDidChangedWithMode:(AVCaptureFocusMode)focusMode atPoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
    self.focusImgV.alpha = 0;
    point = [self.cameraManager translateCameraPointToVideoLayerPoint:point];;
    self.focusImgV.center = point;
    self.focusImgV.transform = CGAffineTransformMakeScale(1.5, 1.5);
    self.focusImgV.alpha = 1;
    [UIView animateWithDuration:0.25 animations:^{
        self.focusImgV.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.25 animations:^{
                self.focusImgV.alpha = 0;
            }];
        });
    }];
}

#pragma mark --- btn action ---
-(void)captureAction {
    switch (self.cameraManager.captureMode) {
        case DWCameraManagerCaptuerModeVideo:
        {
            if (self.cameraManager.isRecording) {
                [self.cameraManager stopRecording];
                [self.captureBtn setImage:[UIImage imageNamed:@"capturePhoto"] forState:(UIControlStateNormal)];
            } else {
                [self.cameraManager recordMovie];
                [self.captureBtn setImage:[UIImage imageNamed:@"stopRecord"] forState:(UIControlStateNormal)];
            }
        }
            break;
        default:
        {
            [self.cameraManager capturePhoto];
        }
            break;
    }
}

-(void)toggleCameraAction {
    switch (self.cameraManager.cameraPosition) {
        case DWCameraManagerCameraPositionFront:
        {
            [self.cameraManager toggleCameraPosition:(DWCameraManagerCameraPositionBack)];
        }
            break;
        default:
        {
            [self.cameraManager toggleCameraPosition:(DWCameraManagerCameraPositionFront)];
        }
            break;
    }
}

-(void)toggleCaptureModeAction {
    
    if (self.cameraManager.isRecording) {
        return;
    }
    
    switch (self.cameraManager.captureMode) {
        case DWCameraManagerCaptuerModePhoto:
        {
            [self.cameraManager toggleCaptureMode:DWCameraManagerCaptuerModeVideo];
            [self.toggleCaptureModeBtn setImage:[UIImage imageNamed:@"toggleRecord"] forState:(UIControlStateNormal)];
            self.toggleLiveBtn.hidden = YES;
        }
            break;
            
        default:
        {
            [self.cameraManager toggleCaptureMode:DWCameraManagerCaptuerModePhoto];
            [self.toggleCaptureModeBtn setImage:[UIImage imageNamed:@"toggleCapture"] forState:(UIControlStateNormal)];
            self.toggleLiveBtn.hidden = NO;
        }
            break;
    }
}

-(void)toggleLiveModeAction {
    if (!self.cameraManager.isLivePhotoSupported) {
        return;
    }
    
    if (self.cameraManager.livePhotoEnabled) {
        [self.cameraManager toggleLivePhotoEnabled:NO];
        [self.toggleLiveBtn setTitle:@"Live Off" forState:(UIControlStateNormal)];
    } else {
        [self.cameraManager toggleLivePhotoEnabled:YES];
        [self.toggleLiveBtn setTitle:@"Live On" forState:(UIControlStateNormal)];
    }
}

-(void)toggleLightModeAction {
    if (!self.cameraManager.isFlashSupported) {
        return;
    }
    switch (self.cameraManager.flashMode) {
        case AVCaptureFlashModeOff:
        {
            [self.cameraManager toggleFlashMode:(AVCaptureFlashModeOn)];
            [self.toggleLightBtn setImage:[UIImage imageNamed:@"lightOn"] forState:(UIControlStateNormal)];
        }
            break;
        case AVCaptureFlashModeOn:
        {
            [self.cameraManager toggleFlashMode:(AVCaptureFlashModeAuto)];
            [self.toggleLightBtn setImage:[UIImage imageNamed:@"lightAuto"] forState:(UIControlStateNormal)];
        }
            break;
        default:
        {
            [self.cameraManager toggleFlashMode:(AVCaptureFlashModeOff)];
            [self.toggleLightBtn setImage:[UIImage imageNamed:@"lightOff"] forState:(UIControlStateNormal)];
        }
            break;
    }
}

-(void)toggleTorchAction {
    if (self.cameraManager.isTorchOn) {
        [self.cameraManager toggleTorchOn:NO];
        [self.toggleTorchBtn setImage:[UIImage imageNamed:@"torchOff"] forState:(UIControlStateNormal)];
    } else {
        [self.cameraManager toggleTorchOn:YES];
        [self.toggleTorchBtn setImage:[UIImage imageNamed:@"torchOn"] forState:(UIControlStateNormal)];
    }
}

#pragma mark --- setter/getter ---
-(UIButton *)captureBtn {
    if (!_captureBtn) {
        _captureBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [_captureBtn setImage:[UIImage imageNamed:@"capturePhoto"] forState:(UIControlStateNormal)];
        [_captureBtn addTarget:self action:@selector(captureAction) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _captureBtn;
}

-(UIButton *)toggleCameraBtn {
    if (!_toggleCameraBtn) {
        _toggleCameraBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [_toggleCameraBtn setImage:[UIImage imageNamed:@"toggleCamera"] forState:(UIControlStateNormal)];
        [_toggleCameraBtn addTarget:self action:@selector(toggleCameraAction) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _toggleCameraBtn;
}

-(UIButton *)toggleCaptureModeBtn {
    if (!_toggleCaptureModeBtn) {
        _toggleCaptureModeBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [_toggleCaptureModeBtn setImage:[UIImage imageNamed:@"toggleCapture"] forState:(UIControlStateNormal)];
        [_toggleCaptureModeBtn addTarget:self action:@selector(toggleCaptureModeAction) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _toggleCaptureModeBtn;
}

-(UIButton *)toggleLiveBtn {
    if (!_toggleLiveBtn) {
        _toggleLiveBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [_toggleLiveBtn setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
        [_toggleLiveBtn setTitle:@"Live Off" forState:(UIControlStateNormal)];
        [_toggleLiveBtn addTarget:self action:@selector(toggleLiveModeAction) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _toggleLiveBtn;
}

-(UIButton *)toggleLightBtn {
    if (!_toggleLightBtn) {
        _toggleLightBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [_toggleLightBtn setImage:[UIImage imageNamed:@"lightOff"] forState:(UIControlStateNormal)];
        [_toggleLightBtn addTarget:self action:@selector(toggleLightModeAction) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _toggleLightBtn;
}

-(UIButton *)toggleTorchBtn {
    if (!_toggleTorchBtn) {
        _toggleTorchBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [_toggleTorchBtn setImage:[UIImage imageNamed:@"torchOff"] forState:(UIControlStateNormal)];
        [_toggleTorchBtn addTarget:self action:@selector(toggleTorchAction) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _toggleTorchBtn;
}

-(UIImageView *)focusImgV {
    if (!_focusImgV) {
        _focusImgV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 48, 48)];
        _focusImgV.image = [UIImage imageNamed:@"focus"];
        _focusImgV.alpha = 0;
    }
    return _focusImgV;
}

@end
