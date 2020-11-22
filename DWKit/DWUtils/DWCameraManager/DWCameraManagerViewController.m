//
//  DWCameraManagerViewController.m
//  DWCameraManager
//
//  Created by Wicky on 2020/6/22.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWCameraManagerViewController.h"

@interface DWCameraManagerViewController ()<DWCameraManagerDelegate>

@property (nonatomic ,assign) BOOL finishFirstWillAppear;

@end

@implementation DWCameraManagerViewController

#pragma mark --- hook method ---
-(DWCameraManager *)generateCameraManager {
    DWCameraManager * mgr = [DWCameraManager generateCameraManager];
    mgr.delegate = self;
    [mgr addObserver:self forKeyPath:@"readyForUsage" options:(NSKeyValueObservingOptionNew) context:nil];
    return mgr;
}

-(void)cameraManagerReadyForUsage {
    
}

#pragma mark --- life cycle ---
-(void)loadView {
    [super loadView];
    self.cameraManager.previewView.frame = self.view.frame;
    self.view = self.cameraManager.previewView;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _finishFirstWillAppear = YES;
    if (self.cameraManager.readyForUsage) {
        [self.cameraManager startRunning];
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    [self.cameraManager stopRunning];
    [super viewDidDisappear:animated];
}

#pragma mark --- kvo ---
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([object isEqual:self.cameraManager] && [keyPath isEqualToString:@"readyForUsage"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self cameraManagerReadyForUsage];
        });
        
        if (self.finishFirstWillAppear && !self.cameraManager.isRunning) {
            [self.cameraManager startRunning];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark --- rotation ---
-(BOOL)shouldAutorotate {
    return !self.cameraManager.isRecording;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsValidInterfaceOrientation(deviceOrientation)) {
        [self.cameraManager togglePreviewOrientation:(UIInterfaceOrientation)deviceOrientation];
    }
}

#pragma mark --- override ---
-(instancetype)init {
    if (self = [super init]) {
        _cameraManager = [self generateCameraManager];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        _cameraManager = [self generateCameraManager];
    }
    return self;
}

-(void)dealloc {
    @try {
        [self.cameraManager removeObserver:self forKeyPath:@"readyForUsage"];
    } @catch (NSException *exception) {
        
    }
}

@end
