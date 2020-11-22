//
//  DWCameraManager.m
//  DWCameraManager
//
//  Created by Wicky on 2020/6/15.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWCameraManager.h"
#import "DWCameraManagerDelegate.h"
#import <UIKit/UIKit.h>
#import "DWCameraManagerLibraryHelper.h"
#import "DWCameraManagerMacro.h"

typedef NS_ENUM(NSUInteger, DWCameraManagerConfigureResult) {
    DWCameraManagerConfigureResultUndefine,
    DWCameraManagerConfigureResultSuccess,
    DWCameraManagerConfigureResultFail,
};

static void* DWCameraManagerSystemPressureContext = &DWCameraManagerSystemPressureContext;

static void * kDWCameraManagerQueueKey = "kDWCameraManagerQueueKey";

static void * kDWCameraManagerMainQueueKey = "kDWCameraManagerMainQueueKey";

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wunguarded-availability"
@interface DWCameraManager ()
{
    DWCameraManagerConfigureResult _configureResult;
    dispatch_queue_t _sessionQueue;
    AVCaptureSession * _prv_captureSession;
    DWCameraManagerView * _prv_previewView;
    BOOL _prv_sessionIsRunning;
    AVCaptureDeviceInput * _videoDeviceInput;
    AVCaptureOutput * _captureOutput;
    AVCaptureMovieFileOutput * _movieFileOutput;
    BOOL _prv_livePhotoEnabled;
    BOOL _prv_depthDataDeliveryEnabled;
    BOOL _prv_portraitEffectsMatteDeliveryEnabled;
    NSArray<AVSemanticSegmentationMatteType> * _prv_enabledSemanticSegmentationMatteTypes;
    AVCapturePhotoQualityPrioritization _prv_photoQualityPrioritization;
    DWCameraManagerResolutionLevel _prv_resolutionLevel;
    AVCaptureFlashMode _prv_flashMode;
    CGFloat _prv_zoomFactor;
    CGFloat _prv_maxRecordedDuration;
    int64_t _prv_maxRecordedFileSize;
    AVCaptureVideoStabilizationMode _prv_stabilizationMode;
    BOOL _prv_isMirrored;
    BOOL _prv_isTorchOn;
    BOOL _prv_HDREnabled;
    BOOL _prv_autoSaveToLibrary;
    DWCameraManagerCaptuerMode _prv_captureMode;
    DWCameraManagerCameraPosition _prv_cameraPosition;
    UITapGestureRecognizer * _autoFocusAndExposeGesture;
}

@property (nonatomic ,assign) BOOL readyForUsage;

@property (nonatomic ,strong) AVCaptureDeviceDiscoverySession * deviceDiscoverySession;

@property (nonatomic ,strong) AVCapturePhotoOutput * photoOutput;

@property (nonatomic ,strong) AVCaptureStillImageOutput * stillImageOutput;

@property (nonatomic ,strong) AVCaptureConnection * photoConn;

@property (nonatomic ,strong) AVCaptureConnection * movieConn;

@property (nonatomic ,strong) NSSet <AVSemanticSegmentationMatteType>* availableSemanticSegmentationMatteType;

@property (nonatomic ,strong) NSMutableDictionary * inProgressPhotoCaptureDelegates;

@property (nonatomic ,strong) DWCameraManagerDelegate * recordDelegate;

@end

@implementation DWCameraManager

#pragma mark --- interface method ---
+(AVAuthorizationStatus)authorizationStatusForCamera {
    return [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
}

+(void)requestAccessForCameraWithCompletion:(void (^)(BOOL))completion {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        if (completion) {
            completion(granted);
        }
    }];
}

+(instancetype)generateCameraManager {
    DWCameraManager * mgr = [self new];
    [mgr configureSessionQueueStatusWithAuthorizedStatus];
    [mgr performActionInSessionQueueAynchronously:^{
        [mgr configureSession];
    }];
    return mgr;
}

-(void)configureSession {
    if (_configureResult != DWCameraManagerConfigureResultUndefine) {
        return;
    }
    
    if ([[self class] authorizationStatusForCamera] != AVAuthorizationStatusAuthorized) {
        ///没有获取权限
        DWCameraManagerLogError(@"DWCameraManager can't finish configuring session for authorization has been denied.");
        return;
    }
    
    [self performActionInSessionQueueAynchronously:^{
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManagerWillBeginConfiguringSession:)]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.delegate cameraManagerWillBeginConfiguringSession:self];
            });
        }
        
        BOOL success = [self _doConfigureSession];
        
        if (success) {
            self.readyForUsage = YES;
            if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManagerDidFinishConfiguringSession:)]) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.delegate cameraManagerDidFinishConfiguringSession:self];
                });
            }
        }
    }];
}

-(void)startRunning {
    switch (_configureResult) {
        case DWCameraManagerConfigureResultSuccess:
        {
            if (_prv_sessionIsRunning) {
                return;
            }
            [self performActionInSessionQueueAynchronously:^{
                [self addObservers];
                [self->_prv_captureSession startRunning];
                [self afterStartRunningForResumeSession:NO userInfo:nil];
            }];
        }
            break;
        case DWCameraManagerConfigureResultUndefine:
        {
            DWCameraManagerLogError(@"Could not start running,you should configure Session first.");
            if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManagerDidFinishStartRunning:success:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate cameraManagerDidFinishStartRunning:self success:NO];
                });
            }
        }
            break;
        default:
        {
            DWCameraManagerLogError(@"Could not start running because configureSession failed.");
            if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManagerDidFinishStartRunning:success:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate cameraManagerDidFinishStartRunning:self success:NO];
                });
            }
        }
            break;
    }
}

-(void)resumeInterruptedSessionWithUserInfo:(id)userInfo {
    if (_configureResult == DWCameraManagerConfigureResultSuccess) {
        [self performActionInSessionQueueAynchronously:^{
            [self->_prv_captureSession startRunning];
            [self afterStartRunningForResumeSession:YES userInfo:userInfo];
        }];
    } else {
        DWCameraManagerLogError(@"Could not resume session for configure session failed.");
    }
    
}

-(void)stopRunning {
    if (_prv_sessionIsRunning) {
        [self performActionInSessionQueueAynchronously:^{
            [self->_prv_captureSession stopRunning];
            [self removeObservers];
            if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManagerDidFinishStopRunning:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate cameraManagerDidFinishStopRunning:self];
                });
            }
        }];
    }
}

-(void)performActionInMainQueue:(dispatch_block_t)action {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        dispatch_queue_set_specific(mainQueue, kDWCameraManagerMainQueueKey, &kDWCameraManagerMainQueueKey, NULL);
    });
    
    if (action) {
        if (dispatch_get_specific(kDWCameraManagerMainQueueKey)) {
            action();
        } else {
            dispatch_sync(dispatch_get_main_queue(), action);
        }
    }
}

-(void)performActionInSessionQueue:(dispatch_block_t)action {
    if (action) {
        if (dispatch_get_specific(kDWCameraManagerQueueKey) == dispatch_queue_get_specific(_sessionQueue, kDWCameraManagerQueueKey)) {
            action();
        } else {
            dispatch_sync(_sessionQueue, action);
        }
    }
}

-(void)performActionInSessionQueueAynchronously:(dispatch_block_t)action {
    if (action) {
        dispatch_async(_sessionQueue, action);
    }
}

-(void)toggleLivePhotoEnabled:(BOOL)enabled {
    if (self.isLivePhotoSupported && _prv_livePhotoEnabled != enabled) {
        [self performActionInSessionQueueAynchronously:^{
            self->_prv_livePhotoEnabled = enabled;
        }];
    }
}

-(void)toggleDepthDataDeliveryEnabled:(BOOL)enabled {
    if (self.isDepthDataDeliverySupported && _prv_depthDataDeliveryEnabled != enabled) {
        [self performActionInSessionQueueAynchronously:^{
            self->_prv_depthDataDeliveryEnabled = enabled;
        }];
    }
}

-(void)togglePortraitEffectsMatteDeliveryEnabled:(BOOL)enabled {
    if (self.isPortraitEffectsMatteDeliverySupported && _prv_portraitEffectsMatteDeliveryEnabled != enabled) {
        [self performActionInSessionQueueAynchronously:^{
            self->_prv_portraitEffectsMatteDeliveryEnabled = enabled;
        }];
    }
}

-(void)toggleEnabledSemanticSegmentationMatteTypes:(NSArray<AVSemanticSegmentationMatteType> *)types {
    if (@available(iOS 13.0,*)) {
        NSMutableSet * targetTypes = [NSMutableSet setWithArray:types];
        [targetTypes intersectSet:self.availableSemanticSegmentationMatteType];
        if (!targetTypes.count) {
            if (types.count) {
                DWCameraManagerLogError(@"No available semantic segmentation matte type could be enabled.");
            }
        }
        [self performActionInSessionQueueAynchronously:^{
            self->_prv_enabledSemanticSegmentationMatteTypes = targetTypes.allObjects;
        }];
    }
}

-(void)togglePhotoQualityPrioritization:(AVCapturePhotoQualityPrioritization)qualityPrioritization {
    if (self.isPhotoQualityPrioritizationSupported && qualityPrioritization != _prv_photoQualityPrioritization) {
        if (qualityPrioritization >= 0 && qualityPrioritization <= self.photoOutput.maxPhotoQualityPrioritization) {
            [self performActionInSessionQueueAynchronously:^{
                self->_prv_photoQualityPrioritization = qualityPrioritization;
            }];
        }
    }
}

-(void)toggleResolutionLevel:(DWCameraManagerResolutionLevel)level {
    if (_configureResult != DWCameraManagerConfigureResultSuccess) {
        DWCameraManagerLogError(@"Could not toggle resolution level for you should configure session first.");
        return;
    }
    if (level == _prv_resolutionLevel) {
        return;
    }
    NSString * stringLevel = levelString(level);
    [self performActionInSessionQueue:^{
        if ([self->_prv_captureSession canSetSessionPreset:stringLevel]) {
            self->_prv_captureSession.sessionPreset = stringLevel;
            self->_prv_resolutionLevel = level;
        } else {
            DWCameraManagerLogError(@"Could not toggle resolution level for %zd which is not supported.",level);
        }
    }];
}

-(void)toggleFlashMode:(AVCaptureFlashMode)flashMode {
    if (flashMode == _prv_flashMode) {
        return;
    }
    
    [self performActionInSessionQueueAynchronously:^{
        self->_prv_flashMode = flashMode;
        if (@available(iOS 10.0,*)) {
            ///10.0以上photoOutput闪光灯在setting中调节即可
        } else {
            AVCaptureDevice * device = self->_videoDeviceInput.device;
            if (device.isFlashAvailable) {
                [self lockDevice:device handler:^(AVCaptureDevice * aDevice) {
                    [aDevice setFlashMode:flashMode];
                }];
            }
        }
    }];
}

-(void)toggleZoomFactor:(CGFloat)zoomFactor {
    if (_configureResult != DWCameraManagerConfigureResultSuccess) {
        DWCameraManagerLogError(@"Could not toggle zoom factor for you should configure session first.");
        return;
    }
    CGFloat max = self.maxZoomFactor;
    CGFloat min = 1;
    zoomFactor = zoomFactor < min ? min : (zoomFactor > max ? max : zoomFactor);
    if (zoomFactor != _prv_zoomFactor) {
        return;
    }
    
    [self performActionInSessionQueueAynchronously:^{
        self->_prv_zoomFactor = zoomFactor;
        AVCaptureDevice * device = self->_videoDeviceInput.device;
        [self lockDevice:device handler:^(AVCaptureDevice * aDevice) {
            aDevice.videoZoomFactor = zoomFactor;
        }];
    }];
}

-(void)toggleMaxRecordedDuration:(CGFloat)maxDuration {
    if (_configureResult != DWCameraManagerConfigureResultSuccess) {
        DWCameraManagerLogError(@"Could not toggle max recorded duration for you should configure session first.");
        return;
    }
    [self performActionInSessionQueueAynchronously:^{
        if (self->_prv_captureMode != DWCameraManagerCaptuerModeVideo) {
            return;
        }
        
        if (maxDuration == self->_prv_maxRecordedDuration) {
            return;
        }
        self->_prv_maxRecordedDuration = maxDuration;
        if (maxDuration == 0) {
            self->_movieFileOutput.maxRecordedDuration = kCMTimeInvalid;
        } else {
            self->_movieFileOutput.maxRecordedDuration = CMTimeMakeWithSeconds(maxDuration, 30);///30为默认帧率
        }
    }];
}

-(void)toggleMaxRecordedFileSize:(int64_t)maxFileSize {
    if (_configureResult != DWCameraManagerConfigureResultSuccess) {
        DWCameraManagerLogError(@"Could not toggle max recorded file size for you should configure session first.");
        return;
    }
    [self performActionInSessionQueueAynchronously:^{
        if (self->_prv_captureMode != DWCameraManagerCaptuerModeVideo) {
            return;
        }
        
        if (maxFileSize == self->_prv_maxRecordedFileSize) {
            return;
        }
        self->_prv_maxRecordedFileSize = maxFileSize;
        self->_movieFileOutput.maxRecordedFileSize = maxFileSize;
    }];
}

-(void)toggleStabilizationMode:(AVCaptureVideoStabilizationMode)stabilizationMode {
    if (_configureResult != DWCameraManagerConfigureResultSuccess) {
        DWCameraManagerLogError(@"Could not toggle stabilization mode for you should configure session first.");
        return;
    }
    if (!self.photoConn.isVideoStabilizationSupported) {
        DWCameraManagerLogError(@"Could not toggle stabilization mode for it's not supported.");
        return;
    }
    [self performActionInSessionQueueAynchronously:^{
        if (self->_prv_stabilizationMode == stabilizationMode) {
            return ;
        }
        self->_prv_stabilizationMode = stabilizationMode;
        self.photoConn.preferredVideoStabilizationMode = stabilizationMode;
        self.movieConn.preferredVideoStabilizationMode = stabilizationMode;
    }];
}

-(void)toggleMirrored:(BOOL)mirrored {
    if (_configureResult != DWCameraManagerConfigureResultSuccess) {
        DWCameraManagerLogError(@"Could not toggle mirrored mode for you should configure session first.");
        return;
    }
    
    if (!self.photoConn.isVideoMirroringSupported) {
        DWCameraManagerLogError(@"Could not toggle mirrored mode for it's not supported.");
        return;
    }
    
    [self performActionInSessionQueueAynchronously:^{
        if (self->_prv_isMirrored == mirrored) {
            return ;
        }
        self->_prv_isMirrored = mirrored;
        self.photoConn.videoMirrored = mirrored;
        self.movieConn.videoMirrored = mirrored;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (mirrored) {
                self.previewView.previewLayer.transform = CATransform3DMakeScale(-1, 1, 1);
            } else {
                self.previewView.previewLayer.transform = CATransform3DIdentity;
            }
        });
    }];
}

-(void)toggleTorchOn:(BOOL)on {
    if (_configureResult != DWCameraManagerConfigureResultSuccess) {
        DWCameraManagerLogError(@"Could not toggle torch mode for you should configure session first.");
        return;
    }
    
    [self performActionInSessionQueueAynchronously:^{
        AVCaptureDevice * device = self->_videoDeviceInput.device;
        if (![device hasTorch] || !device.isTorchAvailable) {
            DWCameraManagerLogError(@"Could not toggle torch mode for it's not supported.");
            return ;
        }
        
        if (self->_prv_isTorchOn == on) {
            return;
        }
        
        [self lockDevice:device handler:^(AVCaptureDevice * aDevice) {
            if (!on && [device isTorchModeSupported:AVCaptureTorchModeOff]) {
                self->_prv_isTorchOn = on;
                if (device.torchActive) {
                    [device setTorchMode:AVCaptureTorchModeOff];
                }
            } else if (on && [device isTorchModeSupported:AVCaptureTorchModeOn]) {
                self->_prv_isTorchOn = on;
                if (!device.torchActive) {
                    [device setTorchMode:AVCaptureTorchModeOn];
                }
            }
        }];
    }];
}

-(void)toggleHDREnabled:(BOOL)enabled {
    if (_configureResult != DWCameraManagerConfigureResultSuccess) {
        DWCameraManagerLogError(@"Could not toggle HDR mode for you should configure session first.");
        return;
    }
    
    [self performActionInSessionQueueAynchronously:^{
        AVCaptureDevice * device = self->_videoDeviceInput.device;
        if (!device.activeFormat.isVideoHDRSupported) {
            DWCameraManagerLogError(@"Could not toggle HDR mode for it's not supported.");
            return ;
        }
        
        if (self->_prv_HDREnabled == enabled) {
            return;
        }
        self->_prv_HDREnabled = enabled;
        [self lockDevice:device handler:^(AVCaptureDevice * aDevice) {
            aDevice.videoHDREnabled = enabled;
        }];
    }];
}

-(void)toggleCaptureMode:(DWCameraManagerCaptuerMode)captureMode {
    if (_configureResult != DWCameraManagerConfigureResultSuccess) {
        DWCameraManagerLogError(@"Could not toggle capture mode for you should configure session first.");
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:captureModeChangeFailedWithTargetMode:currentMode:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate cameraManager:self captureModeChangeFailedWithTargetMode:captureMode currentMode:self->_prv_captureMode];
            });
        }
        return;
    }
    if (_prv_captureMode == captureMode) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:captureModeChangeFailedWithTargetMode:currentMode:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate cameraManager:self captureModeChangeFailedWithTargetMode:captureMode currentMode:self->_prv_captureMode];
            });
        }
        return;
    }
    DWCameraManagerCaptuerMode from = _prv_captureMode;
    switch (captureMode) {
        case DWCameraManagerCaptuerModePhoto:
        {
            [self performActionInSessionQueueAynchronously:^{
                self->_prv_captureMode = captureMode;
                [self configureCaptureSessionWithHanlder:^(AVCaptureSession *session) {
                    if (self->_movieFileOutput) {
                        [session removeOutput:self->_movieFileOutput];
                        self->_movieFileOutput = nil;
                    }
                    session.sessionPreset = AVCaptureSessionPresetPhoto;
                    [self configureCaptureOutputOnChange];
                }];
                if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:captureModeDidChangedFrom:to:)]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.delegate cameraManager:self captureModeDidChangedFrom:from to:captureMode];
                    });
                }
            }];
        }
            break;
        case DWCameraManagerCaptuerModeVideo:
        {
            [self performActionInSessionQueueAynchronously:^{
                AVCaptureMovieFileOutput * movieFileOutput = [AVCaptureMovieFileOutput new];
                if ([self->_prv_captureSession canAddOutput:movieFileOutput]) {
                    [self configureCaptureSessionWithHanlder:^(AVCaptureSession *session) {
                        [session addOutput:movieFileOutput];
                        session.sessionPreset = AVCaptureSessionPresetHigh;
                        
                        AVCaptureConnection* connection = [movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
                        if (connection.isVideoStabilizationSupported) {
                            connection.preferredVideoStabilizationMode = self->_prv_stabilizationMode;
                        }
                        
                        if (self->_prv_maxRecordedDuration == 0) {
                            movieFileOutput.maxRecordedDuration = kCMTimeInvalid;
                        } else {
                            movieFileOutput.maxRecordedDuration = CMTimeMakeWithSeconds(self->_prv_maxRecordedDuration, 30);///30为默认帧率
                        }
                        
                        movieFileOutput.maxRecordedFileSize = self->_prv_maxRecordedFileSize;
                    }];
                    
                    self->_movieFileOutput = movieFileOutput;
                    self->_prv_captureMode = captureMode;
                    if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:captureModeDidChangedFrom:to:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate cameraManager:self captureModeDidChangedFrom:from to:captureMode];
                        });
                    }
                } else {
                    DWCameraManagerLogError(@"Could not switch to video mode for can't add AVCaptureMovieFileOutput output.");
                    if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:captureModeChangeFailedWithTargetMode:currentMode:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate cameraManager:self captureModeChangeFailedWithTargetMode:captureMode currentMode:self->_prv_captureMode];
                        });
                    }
                }
            }];
        }
            break;
        default:
        {
            DWCameraManagerLogError(@"Could not switch to target mode for DWCameraManager don't support that mode:%zd.",captureMode);
            if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:captureModeChangeFailedWithTargetMode:currentMode:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate cameraManager:self captureModeChangeFailedWithTargetMode:captureMode currentMode:self->_prv_captureMode];
                });
            }
        }
            break;
    }
}

-(void)toggleCameraPosition:(DWCameraManagerCameraPosition)position {
    if (position == DWCameraManagerCameraPositionUndefine || _prv_cameraPosition == DWCameraManagerCameraPositionUndefine) {
        DWCameraManagerLogError(@"Could not switch camera position for DWCameraManager can't find available camera device.");
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:cameraPositionChangeFailedWithTargetPosition:currentPosition:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate cameraManager:self cameraPositionChangeFailedWithTargetPosition:position currentPosition:self->_prv_cameraPosition];
            });
        }
        return;
    }
    
    if (position == DWCameraManagerCameraPositionUnspecified) {
        if (_prv_cameraPosition == DWCameraManagerCameraPositionFront) {
            position = DWCameraManagerCameraPositionBack;
        } else {
            position = DWCameraManagerCameraPositionFront;
        }
    }
    
    if (position == _prv_cameraPosition) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:cameraPositionChangeFailedWithTargetPosition:currentPosition:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate cameraManager:self cameraPositionChangeFailedWithTargetPosition:position currentPosition:self->_prv_cameraPosition];
            });
        }
        return;
    }
    
    
    [self performActionInSessionQueueAynchronously:^{
        DWCameraManagerCameraPosition from = self->_prv_cameraPosition;
        
        AVCaptureDeviceType deviceType;
        AVCaptureDevicePosition targetPosition = AVCaptureDevicePositionFront;
        if (@available(iOS 10.0,*)) {
            switch (from) {
                case DWCameraManagerCameraPositionFront:
                {
                    deviceType = AVCaptureDeviceTypeBuiltInDualCamera;
                    targetPosition = AVCaptureDevicePositionBack;
                }
                    break;
                case DWCameraManagerCameraPositionBack:
                {
                    deviceType = AVCaptureDeviceTypeBuiltInTrueDepthCamera;
                    targetPosition = AVCaptureDevicePositionFront;
                }
                    break;
                default:
                    break;
            }
        }
        
        AVCaptureDevice * newDevice = [self fetchDeviceWithPosition:targetPosition deviceType:deviceType];
        
        if (!newDevice) {
            DWCameraManagerLogError(@"Could not switch camera position for DWCameraManager can't find available camera device at Position:%zd.",position);
            if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:cameraPositionChangeFailedWithTargetPosition:currentPosition:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate cameraManager:self cameraPositionChangeFailedWithTargetPosition:position currentPosition:self->_prv_cameraPosition];
                });
            }
            return ;
        }
        
        if (@available(iOS 10.0,*)) {
            ///photoOutput在setting中设置
        } else {
            if (newDevice.isFlashAvailable && newDevice.flashMode != self->_prv_flashMode) {
                [self lockDevice:newDevice handler:^(AVCaptureDevice * aDevice) {
                    aDevice.flashMode = self->_prv_flashMode;
                }];
            }
        }
        
        NSError * error;
        AVCaptureDeviceInput * newDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:newDevice error:&error];
        [self configureCaptureSessionWithHanlder:^(AVCaptureSession *session) {
            [session removeInput:self->_videoDeviceInput];
            if ([session canAddInput:newDeviceInput]) {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self->_videoDeviceInput.device];
                
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:newDevice];
                
                [session addInput:newDeviceInput];
                self->_videoDeviceInput = newDeviceInput;
            } else {
                [session addInput:self->_videoDeviceInput];
            }
            
            AVCaptureConnection* movieFileOutputConnection = [self->_movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            if (movieFileOutputConnection.isVideoStabilizationSupported) {
                movieFileOutputConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
            [self configureCaptureOutputOnChange];
        }];
        
        self->_prv_cameraPosition = position;
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:cameraPositionDidChangedFrom:to:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate cameraManager:self cameraPositionDidChangedFrom:from to:position];
            });
        }
    }];
}

-(void)toggleAutoSaveToLibrary:(BOOL)autoSaveToLibrary {
    if (_prv_autoSaveToLibrary != autoSaveToLibrary) {
        [self performActionInSessionQueueAynchronously:^{
            self->_prv_autoSaveToLibrary = autoSaveToLibrary;
        }];
    }
}

-(void)togglePreviewOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if (!self.previewView.previewLayer.connection.isVideoOrientationSupported || self.previewView.previewLayer.connection.videoOrientation == (AVCaptureVideoOrientation)interfaceOrientation) {
        return;
    }
    
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.previewView.previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)interfaceOrientation;
            });
        }
            break;
        default:
        {
            DWCameraManagerLogError(@"Could not toggle preview orientation to %zd which is not supported.",interfaceOrientation);
        }
            break;
    }
}

-(void)toggleAutoFocusAndExposeGestureEnabled:(BOOL)enable {
    if (enable == self.autoFocusAndExposeGestureEnabled) {
        return;
    }
    _autoFocusAndExposeGesture.enabled = enable;
}

-(CGPoint)translateVideoLayerPointToCameraPoint:(CGPoint)layerPoint {
    return [self.previewView.previewLayer captureDevicePointOfInterestForPoint:layerPoint];
}

-(CGPoint)translateCameraPointToVideoLayerPoint:(CGPoint)cameraPoint {
    return [self.previewView.previewLayer pointForCaptureDevicePointOfInterest:cameraPoint];
}

-(void)focusAndExposeAtPoint:(CGPoint)point {
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:point monitorSubjectAreaChange:YES];
}

-(void)focusWithMode:(AVCaptureFocusMode)focusMode atPoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
    [self performActionInSessionQueueAynchronously:^{
        AVCaptureDevice* device = self->_videoDeviceInput.device;
        [self lockDevice:device handler:^(AVCaptureDevice * aDevice) {
            if ([aDevice isFocusPointOfInterestSupported] && [aDevice isFocusModeSupported:focusMode]) {
                [aDevice setFocusMode:focusMode];
                [aDevice setFocusPointOfInterest:point];
            }
            aDevice.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
        }];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:focusDidChangedWithMode:atPoint:monitorSubjectAreaChange:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate cameraManager:self focusDidChangedWithMode:focusMode atPoint:point monitorSubjectAreaChange:monitorSubjectAreaChange];
            });
        }
    }];
}

-(void)exposeWithMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
    [self performActionInSessionQueueAynchronously:^{
        AVCaptureDevice* device = self->_videoDeviceInput.device;
        [self lockDevice:device handler:^(AVCaptureDevice * aDevice) {
            if (aDevice.isExposurePointOfInterestSupported && [aDevice isExposureModeSupported:exposureMode]) {
                aDevice.exposurePointOfInterest = point;
                aDevice.exposureMode = exposureMode;
            }
            aDevice.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
        }];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:exposeDidChangedWithMode:atPoint:monitorSubjectAreaChange:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate cameraManager:self exposeDidChangedWithMode:exposureMode atPoint:point monitorSubjectAreaChange:monitorSubjectAreaChange];
            });
        }
    }];
}

-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange {
    [self performActionInSessionQueueAynchronously:^{
        AVCaptureDevice* device = self->_videoDeviceInput.device;
        [self lockDevice:device handler:^(AVCaptureDevice * aDevice) {
            if (aDevice.isFocusPointOfInterestSupported && [aDevice isFocusModeSupported:focusMode]) {
                aDevice.focusPointOfInterest = point;
                aDevice.focusMode = focusMode;
            }
            
            if (aDevice.isExposurePointOfInterestSupported && [aDevice isExposureModeSupported:exposureMode]) {
                aDevice.exposurePointOfInterest = point;
                aDevice.exposureMode = exposureMode;
            }
            
            aDevice.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
        }];
        BOOL needFocus = NO;
        BOOL needExpose = NO;
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:focusDidChangedWithMode:atPoint:monitorSubjectAreaChange:)]) {
            needFocus = YES;
        }
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:exposeDidChangedWithMode:atPoint:monitorSubjectAreaChange:)]) {
            needExpose = YES;
        }
        
        if (needFocus || needExpose) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (needFocus) {
                    [self.delegate cameraManager:self focusDidChangedWithMode:focusMode atPoint:point monitorSubjectAreaChange:monitorSubjectAreaChange];
                }
                
                if (needExpose) {
                    [self.delegate cameraManager:self exposeDidChangedWithMode:exposureMode atPoint:point monitorSubjectAreaChange:monitorSubjectAreaChange];
                }
            });
        }
    }];
}

-(void)autoFocusAndExpose {
    CGPoint devicePoint = CGPointMake(0.5, 0.5);
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

-(void)capturePhoto {
    if (_configureResult != DWCameraManagerConfigureResultSuccess) {
        DWCameraManagerLogError(@"Could not capture photo because configureSession failed.");
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        AVCaptureVideoOrientation previewViewOrientation = self.previewView.previewLayer.connection.videoOrientation;
        [self performActionInSessionQueueAynchronously:^{
            if (@available(iOS 10.0, *)) {
                AVCaptureConnection* photoOutputConnection = [self.photoOutput connectionWithMediaType:AVMediaTypeVideo];
                photoOutputConnection.videoOrientation = previewViewOrientation;
                
                AVCapturePhotoSettings* photoSettings;
                if ([self.photoOutput.availablePhotoCodecTypes containsObject:AVVideoCodecTypeHEVC]) {
                    photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:@{ AVVideoCodecKey : AVVideoCodecTypeHEVC }];
                } else {
                    photoSettings = [AVCapturePhotoSettings photoSettings];
                }
                
                if (self->_videoDeviceInput.device.isFlashAvailable && [self.photoOutput.supportedFlashModes containsObject:@(self->_prv_flashMode)]) {
                    photoSettings.flashMode = self->_prv_flashMode;
                }
                photoSettings.highResolutionPhotoEnabled = YES;
                if (photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0) {
                    photoSettings.previewPhotoFormat = @{ (NSString*)kCVPixelBufferPixelFormatTypeKey : photoSettings.availablePreviewPhotoPixelFormatTypes.firstObject };
                }
                if (self.isLivePhotoSupported && self->_prv_livePhotoEnabled) {
                    NSString* livePhotoMovieFileName = [NSUUID UUID].UUIDString;
                    NSString* livePhotoMovieFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[livePhotoMovieFileName stringByAppendingPathExtension:@"mov"]];
                    photoSettings.livePhotoMovieFileURL = [NSURL fileURLWithPath:livePhotoMovieFilePath];
                }
                
                photoSettings.depthDataDeliveryEnabled = self.isDepthDataDeliverySupported && self->_prv_depthDataDeliveryEnabled;
                
                photoSettings.portraitEffectsMatteDeliveryEnabled = self.isPortraitEffectsMatteDeliverySupported && self->_prv_portraitEffectsMatteDeliveryEnabled;
                
                if (photoSettings.depthDataDeliveryEnabled && self->_availableSemanticSegmentationMatteType.count > 0 && self->_prv_enabledSemanticSegmentationMatteTypes.count > 0) {
                    photoSettings.enabledSemanticSegmentationMatteTypes = self->_prv_enabledSemanticSegmentationMatteTypes;
                }
                
                photoSettings.photoQualityPrioritization = self->_prv_photoQualityPrioritization;
                
                DWCameraManagerDelegate * delegate = [DWCameraManagerDelegate capturePhotoDelegateWithPhotoSettings:photoSettings autoSaveToLibrary:self->_prv_autoSaveToLibrary willStartCapturing:^{
                    if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:willBeginCapturingWithPhotoSettings:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate cameraManager:self willBeginCapturingWithPhotoSettings:photoSettings];
                        });
                    }
                } photoProcessing:^(BOOL finish, id  _Nonnull object, NSError * _Nullable error) {
                    if (!finish) {
                        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:willBeginProcessingPhotoWithResolvedSettings:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.delegate cameraManager:self willBeginProcessingPhotoWithResolvedSettings:object];
                            });
                        }
                    } else {
                        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:didFinishProcessingPhoto:error:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.delegate cameraManager:self didFinishProcessingPhoto:object error:error];
                            });
                        }
                    }
                } completion:^(DWCameraManagerDelegate * delegate, AVCaptureResolvedPhotoSettings * resolvedSettings, NSData * photoData) {
                    if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:didFinishCapturingWithResolvedSettings:photoData:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.delegate cameraManager:self didFinishCapturingWithResolvedSettings:resolvedSettings photoData:photoData];
                        });
                    }
                    [self performActionInSessionQueueAynchronously:^{
                        self.inProgressPhotoCaptureDelegates[@(delegate.photoSettings.uniqueID)] = nil;
                    }];
                }];
                
                if (self.isLivePhotoSupported && self->_prv_livePhotoEnabled) {
                    delegate.livePhotoCaptureHandler = ^(BOOL finish, AVCaptureResolvedPhotoSettings * _Nullable resolvedSettings, NSURL * _Nullable outputURL) {
                        if (!finish) {
                            if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:willBeginCapturingLivePhotoWithResolvedSettings:)]) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self.delegate cameraManager:self willBeginCapturingLivePhotoWithResolvedSettings:resolvedSettings];
                                });
                            }
                        } else {
                            if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:didFinishCapturingLivePhotoWithResolvedSettings:outputURL:)]) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self.delegate cameraManager:self didFinishCapturingLivePhotoWithResolvedSettings:resolvedSettings outputURL:outputURL];
                                });
                            }
                        }
                    };
                }
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:didFinishPhotoDataGenerationWithPhotoData:resolvedSettings:livePhotoFileURL:semanticSegmentationMatteDataArray:)]) {
                    delegate.photoDataGenerateCompletion = ^(NSData * _Nonnull photoData, AVCaptureResolvedPhotoSettings * _Nullable resolvedSettings, NSURL * _Nullable livePhotoFileURL, NSArray * _Nonnull semanticSegmentationMatteDataArray) {
                        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:didFinishPhotoDataGenerationWithPhotoData:resolvedSettings:livePhotoFileURL:semanticSegmentationMatteDataArray:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self.delegate cameraManager:self didFinishPhotoDataGenerationWithPhotoData:photoData resolvedSettings:resolvedSettings livePhotoFileURL:livePhotoFileURL semanticSegmentationMatteDataArray:semanticSegmentationMatteDataArray];
                            });
                        }
                    };
                }
                
                self.inProgressPhotoCaptureDelegates[@(photoSettings.uniqueID)] = delegate;
                
                [self.photoOutput capturePhotoWithSettings:photoSettings delegate:delegate];
                
            } else {
                if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:willBeginCapturingWithPhotoSettings:)]) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self.delegate cameraManager:self willBeginCapturingWithPhotoSettings:nil];
                    });
                }
                __weak typeof(self) weakSelf = self;
                [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:self.photoConn completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    if (imageDataSampleBuffer) {
                        NSData * photoData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                        
                        if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(cameraManager:didFinishPhotoDataGenerationWithPhotoData:resolvedSettings:livePhotoFileURL:semanticSegmentationMatteDataArray:)]) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [strongSelf.delegate cameraManager:strongSelf didFinishPhotoDataGenerationWithPhotoData:photoData resolvedSettings:nil livePhotoFileURL:nil semanticSegmentationMatteDataArray:nil];
                            });
                        }
                        
                        if (strongSelf->_prv_autoSaveToLibrary) {
                            [DWCameraManagerLibraryHelper savePhoto:photoData photoSetting:nil livePhotoURL:nil portraitEffectsMatteData:nil semanticSegmentationMatteDataArray:nil completion:^(BOOL success, NSError * _Nullable error) {
                                if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(cameraManager:didFinishCapturingWithResolvedSettings:photoData:)]) {
                                    [strongSelf performActionInMainQueue:^{
                                        [strongSelf.delegate cameraManager:strongSelf didFinishCapturingWithResolvedSettings:nil photoData:photoData];
                                    }];
                                }
                            }];
                        } else {
                            if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(cameraManager:didFinishCapturingWithResolvedSettings:photoData:)]) {
                                [strongSelf performActionInMainQueue:^{
                                    [strongSelf.delegate cameraManager:strongSelf didFinishCapturingWithResolvedSettings:nil photoData:photoData];
                                }];
                            }
                        }
                    }
                }];
            }
        }];
    });
}

-(void)recordMovie {
    if (_configureResult != DWCameraManagerConfigureResultSuccess) {
        DWCameraManagerLogError(@"Could not record movie because configureSession failed.");
        return;
    }
    
    if (_prv_captureMode != DWCameraManagerCaptuerModeVideo) {
        DWCameraManagerLogError(@"Could not start record movie for curremt mode is %zd",_prv_captureMode);
        return;
    }
    
    if (_movieFileOutput.isRecording) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        AVCaptureVideoOrientation previewViewOrientation = self.previewView.previewLayer.connection.videoOrientation;
        [self performActionInSessionQueueAynchronously:^{
            self.movieConn.videoOrientation = previewViewOrientation;
            
            if ([self->_movieFileOutput.availableVideoCodecTypes containsObject:AVVideoCodecTypeHEVC]) {
                [self->_movieFileOutput setOutputSettings:@{ AVVideoCodecKey : AVVideoCodecTypeHEVC } forConnection:self.movieConn];
            }
            
            NSString* outputFileName = [NSUUID UUID].UUIDString;
            NSString* outputFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
            NSURL* outputURL = [NSURL fileURLWithPath:outputFilePath];
            __weak typeof(self) weakSelf = self;
            DWCameraManagerDelegate * delegate = [DWCameraManagerDelegate recordMovieDelegateWithFileURL:outputURL autoSaveToLibrary:self->_prv_autoSaveToLibrary didStartRecording:^(NSURL * _Nonnull outputURL, UIBackgroundTaskIdentifier backgroundTaskIdentifier, NSArray<AVCaptureConnection *> * _Nullable connections) {
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(cameraManager:didStartRecordingWithOutputURL:backgroundTaskIdentifier:connections:)]) {
                    [weakSelf performActionInMainQueue:^{
                        [weakSelf.delegate cameraManager:weakSelf didStartRecordingWithOutputURL:outputURL backgroundTaskIdentifier:backgroundTaskIdentifier connections:connections];
                    }];
                }
            } finishRecording:^(BOOL success, NSURL * _Nonnull outputURL, UIBackgroundTaskIdentifier backgroundTaskIdentifier, NSArray<AVCaptureConnection *> * _Nullable connections, NSError * _Nullable error) {
                if (weakSelf.delegate && [weakSelf.delegate respondsToSelector:@selector(cameraManager:didFinishRecordingWithSuccess:outputURL:backgroundTaskIdentifier:connections:error:)]) {
                    [weakSelf performActionInMainQueue:^{
                        [weakSelf.delegate cameraManager:weakSelf didFinishRecordingWithSuccess:success outputURL:outputURL backgroundTaskIdentifier:backgroundTaskIdentifier connections:connections error:error];
                    }];
                }
                weakSelf.recordDelegate = nil;
            }];
            
            [self->_movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:delegate];
            self.recordDelegate = delegate;
        }];
    });
}

-(void)stopRecording {
    if (!self.isRecording) {
        return;
    }
    [_movieFileOutput stopRecording];
}

#pragma mark --- hook method ---
-(void)setupDefaultValue {
    _configureResult = DWCameraManagerConfigureResultUndefine;
    _prv_cameraPosition = DWCameraManagerCameraPositionUndefine;
    _prv_enabledSemanticSegmentationMatteTypes = @[];
    _prv_photoQualityPrioritization = AVCapturePhotoQualityPrioritizationBalanced;
    _prv_flashMode = AVCaptureFlashModeOff;
    _prv_zoomFactor = 1;
    _prv_captureMode = DWCameraManagerCaptuerModePhoto;
    _sessionQueue = dispatch_queue_create("com.wicky.DWCameraManager.sessionQueue", DISPATCH_QUEUE_SERIAL);
    CFStringRef posString = CFStringCreateWithCString(NULL, [[NSString stringWithFormat:@"%p",_sessionQueue] UTF8String], kCFStringEncodingUTF8);
    dispatch_queue_set_specific(_sessionQueue, kDWCameraManagerQueueKey, &posString, NULL);
    _prv_captureSession = [[AVCaptureSession alloc] init];
    _prv_previewView = [DWCameraManagerView new];
    _prv_previewView.session = _prv_captureSession;
    _autoFocusAndExposeGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureAction:)];
    [_prv_previewView addGestureRecognizer:_autoFocusAndExposeGesture];
}

#pragma mark --- tool method ---
-(void)configureSessionQueueStatusWithAuthorizedStatus {
    switch ([[self class] authorizationStatusForCamera]) {
        case AVAuthorizationStatusAuthorized:
        {
            
        }
            break;
        case AVAuthorizationStatusNotDetermined:
        {
            dispatch_suspend(_sessionQueue);
            [[self class] requestAccessForCameraWithCompletion:^(BOOL granted) {
                if (!granted) {
                    self->_configureResult = DWCameraManagerConfigureResultFail;
                }
                dispatch_resume(self->_sessionQueue);
            }];
        }
            break;
        default:
        {
            _configureResult = DWCameraManagerConfigureResultFail;
        }
            break;
    }
}

-(BOOL)_doConfigureSession {
    [_prv_captureSession beginConfiguration];
    _prv_captureSession.sessionPreset = AVCaptureSessionPresetPhoto;
    AVCaptureDevice * videoDevice = [self fetchVideoDevice];
    NSError* error = nil;
    AVCaptureDeviceInput* videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (!videoDeviceInput) {
        DWCameraManagerLogError(@"Could not create video device input: %@.", error);
        _configureResult = DWCameraManagerConfigureResultFail;
        [_prv_captureSession commitConfiguration];
        return NO;
    }
    
    if ([_prv_captureSession canAddInput:videoDeviceInput]) {
        __block BOOL shouldAdd = YES;
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:shouldAddDeviceInput:mediaType:)]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                shouldAdd = [self.delegate cameraManager:self shouldAddDeviceInput:videoDeviceInput mediaType:AVMediaTypeVideo];
            });
        }
        
        if (shouldAdd) {
            [_prv_captureSession addInput:videoDeviceInput];
            _videoDeviceInput = videoDeviceInput;
            dispatch_sync(dispatch_get_main_queue(), ^{
                AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
                UIInterfaceOrientation windowOrientation = [self windowOrientation];
                if (windowOrientation != UIInterfaceOrientationUnknown) {
                    initialVideoOrientation = (AVCaptureVideoOrientation)windowOrientation;
                }
                self.previewView.previewLayer.connection.videoOrientation = initialVideoOrientation;
            });
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:didFinishAddingDeviceInput:mediaType:)]) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.delegate cameraManager:self didFinishAddingDeviceInput:videoDeviceInput mediaType:AVMediaTypeVideo];
                });
            }
        } else {
            DWCameraManagerLogError(@"Could not add video device input to the session for dening by delegate.");
            _configureResult = DWCameraManagerConfigureResultFail;
            [_prv_captureSession commitConfiguration];
            return NO;
        }
    } else {
        DWCameraManagerLogError(@"Could not add video device input to the session.");
        _configureResult = DWCameraManagerConfigureResultFail;
        [_prv_captureSession commitConfiguration];
        return NO;
    }
    
    AVCaptureDevice* audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput* audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    
    if (!audioDeviceInput) {
        DWCameraManagerLogError(@"Could not create audio device input: %@", error);
    } else {
        if ([_prv_captureSession canAddInput:audioDeviceInput]) {
            __block BOOL shouldAdd = YES;
            if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:shouldAddDeviceInput:mediaType:)]) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    shouldAdd = [self.delegate cameraManager:self shouldAddDeviceInput:videoDeviceInput mediaType:AVMediaTypeAudio];
                });
            }
            
            if (shouldAdd) {
                [_prv_captureSession addInput:audioDeviceInput];
                if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:didFinishAddingDeviceInput:mediaType:)]) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [self.delegate cameraManager:self didFinishAddingDeviceInput:audioDeviceInput mediaType:AVMediaTypeAudio];
                    });
                }
            } else {
                DWCameraManagerLogError(@"Could not add audio device input to the session for dening by delegate.");
            }
        } else {
            DWCameraManagerLogError(@"Could not add audio device input to the session");
        }
    }
    
    AVCaptureOutput * captureOutput = [self fetchCaptureOutput];
    if ([_prv_captureSession canAddOutput:captureOutput]) {
        __block BOOL shouldAdd = YES;
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:shouldAddOutput:)]) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                shouldAdd = [self.delegate cameraManager:self shouldAddOutput:captureOutput];
            });
        }
        
        if (shouldAdd) {
            [_prv_captureSession addOutput:captureOutput];
            _captureOutput = captureOutput;
            [self configureCaptureOutput];
            if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:didFinishAddingOutput:)]) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self.delegate cameraManager:self didFinishAddingOutput:captureOutput];
                });
            }
        } else {
            DWCameraManagerLogError(@"Could not add photo output to the session for dening by delegate.");
            _configureResult = DWCameraManagerConfigureResultFail;
            [_prv_captureSession commitConfiguration];
            return NO;
        }
    } else {
        DWCameraManagerLogError(@"Could not add photo output to the session");
        _configureResult = DWCameraManagerConfigureResultFail;
        [_prv_captureSession commitConfiguration];
        return NO;
    }
    
    _configureResult = DWCameraManagerConfigureResultSuccess;
    [_prv_captureSession commitConfiguration];
    return YES;
}

-(UIInterfaceOrientation)windowOrientation {
    if (@available(iOS 13.0, *)) {
        id <UIApplicationDelegate> appDelegate = [UIApplication sharedApplication].delegate;
        return appDelegate.window.windowScene.interfaceOrientation;
    } else {
        return [UIApplication sharedApplication].statusBarOrientation;
    }
}

-(AVCaptureDevice *)fetchVideoDevice {
    if (@available(iOS 10.0, *)) {
        AVCaptureDevice* videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
        if (!videoDevice) {
            videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
            
            if (!videoDevice) {
                videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
            }
        }
        
        if (videoDevice) {
            if (videoDevice.position == AVCaptureDevicePositionFront) {
                _prv_cameraPosition = DWCameraManagerCameraPositionFront;
            } else {
                _prv_cameraPosition = DWCameraManagerCameraPositionBack;
            }
        }
        
        return videoDevice;
    } else {
        NSArray * devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        AVCaptureDevice * backDev = nil;
        AVCaptureDevice * frontDev = nil;
        for (AVCaptureDevice * dev in devices) {
            if (dev.position == AVCaptureDevicePositionBack) {
                backDev = dev;
                break;
            } else if (dev.position == AVCaptureDevicePositionFront && !frontDev) {
                frontDev = dev;
            }
        }
        if (backDev) {
            _prv_cameraPosition = DWCameraManagerCameraPositionBack;
        } else if (frontDev) {
            _prv_cameraPosition = DWCameraManagerCameraPositionFront;
        }
        AVCaptureDevice * device = backDev?:frontDev;
        if (device.isFlashAvailable && device.flashMode != self->_prv_flashMode) {
            [self lockDevice:device handler:^(AVCaptureDevice * aDevice) {
                aDevice.flashMode = self->_prv_flashMode;
            }];
        }
        return device;
    }
}

-(AVCaptureOutput *)fetchCaptureOutput {
    if (@available(iOS 10.0,*)) {
        return self.photoOutput;
    } else {
        return self.stillImageOutput;
    }
}

-(void)configureCaptureOutput {
    if (@available(iOS 10.0,*)) {
        self.photoOutput.highResolutionCaptureEnabled = YES;
        self.photoOutput.livePhotoCaptureEnabled = self.photoOutput.livePhotoCaptureSupported;
        _prv_livePhotoEnabled = self.photoOutput.livePhotoCaptureEnabled;
        self.photoOutput.depthDataDeliveryEnabled = self.photoOutput.depthDataDeliverySupported;
        _prv_depthDataDeliveryEnabled = self.photoOutput.depthDataDeliveryEnabled;
        self.photoOutput.portraitEffectsMatteDeliveryEnabled = self.photoOutput.portraitEffectsMatteDeliverySupported;
        _prv_portraitEffectsMatteDeliveryEnabled = self.photoOutput.portraitEffectsMatteDeliverySupported;
        if (@available(iOS 13.0,*)) {
            if (self.photoOutput.availableSemanticSegmentationMatteTypes) {
                self.photoOutput.enabledSemanticSegmentationMatteTypes = self.photoOutput.availableSemanticSegmentationMatteTypes;
            } else {
                self.photoOutput.enabledSemanticSegmentationMatteTypes = @[];
            }
            _prv_enabledSemanticSegmentationMatteTypes = self.photoOutput.enabledSemanticSegmentationMatteTypes;
        } else {
            _prv_enabledSemanticSegmentationMatteTypes = @[];
        }
        
       
        if (self.isPhotoQualityPrioritizationSupported) {
            self.photoOutput.maxPhotoQualityPrioritization = AVCapturePhotoQualityPrioritizationQuality;
            _prv_photoQualityPrioritization = AVCapturePhotoQualityPrioritizationBalanced;
        }
    } else {
        self.stillImageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
    }
}

-(void)configureCaptureOutputOnChange {
    if (@available(iOS 10.0,*)) {
        if (!self.isLivePhotoSupported) {
            _prv_livePhotoEnabled = NO;
        }
        self.photoOutput.livePhotoCaptureEnabled = _prv_livePhotoEnabled;
        
        if (!self.isDepthDataDeliverySupported) {
            _prv_depthDataDeliveryEnabled = NO;
        }
        self.photoOutput.depthDataDeliveryEnabled = _prv_depthDataDeliveryEnabled;
        
        if (!self.isPortraitEffectsMatteDeliverySupported) {
            _prv_portraitEffectsMatteDeliveryEnabled = NO;
        }
        self.photoOutput.portraitEffectsMatteDeliveryEnabled = self.portraitEffectsMatteDeliveryEnabled;
        
        if (@available(iOS 13.0,*)) {
            self.availableSemanticSegmentationMatteType = [NSSet setWithArray:self.photoOutput.availableSemanticSegmentationMatteTypes];
            if (self.availableSemanticSegmentationMatteType.count && _prv_enabledSemanticSegmentationMatteTypes.count) {
                NSMutableSet * targetTypes = [NSMutableSet setWithArray:_prv_enabledSemanticSegmentationMatteTypes];
                [targetTypes intersectSet:self.availableSemanticSegmentationMatteType];
                if (!targetTypes.count) {
                    DWCameraManagerLogError(@"No available semantic segmentation matte type could be enabled.");
                }
                _prv_enabledSemanticSegmentationMatteTypes = targetTypes.allObjects;
                self.photoOutput.enabledSemanticSegmentationMatteTypes = _prv_enabledSemanticSegmentationMatteTypes;
            } else {
                self.photoOutput.enabledSemanticSegmentationMatteTypes = @[];
            }
        }
    } else {
        ///stillImageOutput不用改变
    }
}

-(void)addObservers {
    ///设备相关
    AVCaptureDevice * device = _videoDeviceInput.device;
    if (device) {
        [device addObserver:self forKeyPath:@"systemPressureState" options:NSKeyValueObservingOptionNew context:DWCameraManagerSystemPressureContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:device];
    }
    
    ///会话相关
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:_prv_captureSession];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:_prv_captureSession];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:_prv_captureSession];
}

-(void)removeObservers {
    @try {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [_videoDeviceInput.device removeObserver:self forKeyPath:@"systemPressureState" context:DWCameraManagerSystemPressureContext];
    } @catch (NSException *exception) {
        
    }
}

-(void)afterStartRunningForResumeSession:(BOOL)resumeSession userInfo:(id)userInfo {
    _prv_sessionIsRunning = _prv_captureSession.isRunning;
    if (_prv_sessionIsRunning) {
        if (resumeSession) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:didFinishResumingSessionWithUserInfo:success:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate cameraManager:self didFinishResumingSessionWithUserInfo:userInfo success:self->_prv_sessionIsRunning];
                });
            }
        } else {
            if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManagerDidFinishStartRunning:success:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate cameraManagerDidFinishStartRunning:self success:self->_prv_sessionIsRunning];
                });
            }
        }
    }
}

- (void) setRecommendedFrameRateRangeForPressureState:(AVCaptureSystemPressureState*)systemPressureState {
    AVCaptureSystemPressureLevel pressureLevel = [systemPressureState level];
    if (pressureLevel == AVCaptureSystemPressureLevelSerious || pressureLevel == AVCaptureSystemPressureLevelCritical) {
        AVCaptureDevice * device = _videoDeviceInput.device;
        if (![_movieFileOutput isRecording] && [device lockForConfiguration:nil]) {
            DWCameraManagerLogWarning(@"Reached elevated system pressure level: %@. Throttling frame rate.", pressureLevel);
            device.activeVideoMinFrameDuration = CMTimeMake(1, 20);
            device.activeVideoMaxFrameDuration = CMTimeMake(1, 15);
            [device unlockForConfiguration];
        }
    } else if (pressureLevel == AVCaptureSystemPressureLevelShutdown) {
        DWCameraManagerLogError(@"Session stopped running due to shutdown system pressure level.");
    }
}

-(AVCaptureDevice *)fetchDeviceWithPosition:(AVCaptureDevicePosition)position deviceType:(AVCaptureDeviceType)deviceType {
    if (@available(iOS 10.0,*)) {
        NSArray <AVCaptureDevice *>* devices = self.deviceDiscoverySession.devices;
        AVCaptureDevice * deviceInType = nil;
        AVCaptureDevice * deviceInPosition = nil;
        for (AVCaptureDevice * device in devices) {
            if (device.position == position) {
                if (!deviceType || [device.deviceType isEqualToString:deviceType]) {
                    deviceInType = device;
                    break;
                }
                
                if (!deviceInPosition) {
                    deviceInPosition = device;
                }
            }
        }
        
        if (!deviceInType && deviceInPosition) {
            deviceInType = deviceInPosition;
        }
        
        return deviceInType;
    } else {
        NSArray * devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        AVCaptureDevice * deviceInType = nil;
        for (AVCaptureDevice * device in devices) {
            if (device.position == position) {
                deviceInType = device;
                break;
            }
        }
        return deviceInType;
    }
}

-(void)configureCaptureSessionWithHanlder:(void(^)(AVCaptureSession * session))handler {
    if (handler) {
        [_prv_captureSession beginConfiguration];
        handler(_prv_captureSession);
        [_prv_captureSession commitConfiguration];
    }
}

-(void)lockDevice:(AVCaptureDevice *)device handler:(void(^)(AVCaptureDevice * device))handler {
    if (!handler) {
        return;
    }
    NSError * error = nil;
    if ([device lockForConfiguration:&error]) {
        if (handler) {
            handler(device);
        }
        [device unlockForConfiguration];
    } else {
        DWCameraManagerLogError(@"Could not lock device for configuration: %@", error);
    }
}

#pragma mark --- tool func ---
NS_INLINE NSString * levelString(DWCameraManagerResolutionLevel level) {
    switch (level) {
        case DWCameraManagerResolutionLevelHigh:
            return AVCaptureSessionPresetHigh;
        case DWCameraManagerResolutionLevelMedium:
            return AVCaptureSessionPresetMedium;
        case DWCameraManagerResolutionLevelLow:
            return AVCaptureSessionPresetLow;
        case DWCameraManagerResolutionLevel1280x720:
            return AVCaptureSessionPreset1280x720;
        case DWCameraManagerResolutionLevel1920x1080:
            return AVCaptureSessionPreset1920x1080;
        case DWCameraManagerResolutionLevel3840x2160:
            return AVCaptureSessionPreset3840x2160;
        case DWCameraManagerResolutionLevelPhoto:
            return AVCaptureSessionPresetPhoto;
        default:
            return AVCaptureSessionPresetHigh;
    }
}

#pragma mark --- gesture action ---
-(void)tapGestureAction:(UITapGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:sender.view];
    point = [self translateVideoLayerPointToCameraPoint:point];
    [self focusAndExposeAtPoint:point];
}

#pragma mark --- observer ---
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == DWCameraManagerSystemPressureContext) {
        AVCaptureSystemPressureState * systemPressureState = change[NSKeyValueChangeNewKey];
        [self setRecommendedFrameRateRangeForPressureState:systemPressureState];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark --- notice ---
-(void)subjectAreaDidChange:(NSNotification *)notice {
    [self autoFocusAndExpose];
}

-(void)sessionRuntimeError:(NSNotification *)notification {
    NSError* error = notification.userInfo[AVCaptureSessionErrorKey];
    DWCameraManagerLogError(@"Capture session runtime error: %@", error);
    if (error.code == AVErrorMediaServicesWereReset) {
        [self performActionInSessionQueueAynchronously:^{
            if (self->_prv_sessionIsRunning) {
                [self->_prv_captureSession startRunning];
                [self afterStartRunningForResumeSession:YES userInfo:error];
            }
        }];
    }
}

-(void)sessionWasInterrupted:(NSNotification *)notification {
    AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
    DWCameraManagerLogWarning(@"Capture session was interrupted with reason %zd", reason);
    if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManager:sessionWasInterruptedForReason:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate cameraManager:self sessionWasInterruptedForReason:reason];
        });
    }
}

-(void)sessionInterruptionEnded:(NSNotification *)notification {
    DWCameraManagerLogWarning(@"Capture session interruption ended");
    if (self.delegate && [self.delegate respondsToSelector:@selector(cameraManagerSessionInterruptedEnd:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate cameraManagerSessionInterruptedEnd:self];
        });
    }
}

#pragma mark --- override ---
-(instancetype)init {
    if (self = [super init]) {
        [self setupDefaultValue];
    }
    return self;
}

-(void)dealloc {
    [self removeObservers];
}

#pragma mark --- setter/getter ---
-(void)setReadyForUsage:(BOOL)readyForUsage {
    if (_readyForUsage == readyForUsage) {
        return;
    }
    [super willChangeValueForKey:@"readyForUsage"];
    _readyForUsage = readyForUsage;
    [super didChangeValueForKey:@"readyForUsage"];
}

-(BOOL)isRunning {
    return _prv_sessionIsRunning;
}

-(AVCaptureSession *)captuerSession {
    return _prv_captureSession;
}

-(DWCameraManagerView *)previewView {
    return _prv_previewView;
}

-(AVCaptureDeviceDiscoverySession *)deviceDiscoverySession {
    if (!_deviceDiscoverySession) {
        NSArray<AVCaptureDeviceType>* deviceTypes = @[AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInDualCamera, AVCaptureDeviceTypeBuiltInTrueDepthCamera];
        _deviceDiscoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:deviceTypes mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified];
    }
    return _deviceDiscoverySession;
}

-(AVCapturePhotoOutput *)photoOutput {
    if (!_photoOutput) {
        _photoOutput = [AVCapturePhotoOutput new];
    }
    return _photoOutput;
}

-(AVCaptureStillImageOutput *)stillImageOutput {
    if (!_stillImageOutput) {
        _stillImageOutput = [AVCaptureStillImageOutput new];
    }
    return _stillImageOutput;
}

-(NSArray<AVSemanticSegmentationMatteType> *)enabledSemanticSegmentationMatteTypes {
    return _prv_enabledSemanticSegmentationMatteTypes;
}

-(BOOL)isLivePhotoSupported {
    if (@available(iOS 10.0,*)) {
        if (_prv_captureMode == DWCameraManagerCaptuerModePhoto && self.photoOutput.livePhotoCaptureSupported) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)livePhotoEnabled {
    return _prv_livePhotoEnabled;
}

-(BOOL)isDepthDataDeliverySupported {
    if (@available(iOS 10.0,*)) {
        if (self.photoOutput.depthDataDeliverySupported) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)depthDataDeliveryEnabled {
    return _prv_depthDataDeliveryEnabled;
}

-(BOOL)isPortraitEffectsMatteDeliverySupported {
    if (@available(iOS 10.0,*)) {
        if (self.photoOutput.portraitEffectsMatteDeliverySupported) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)portraitEffectsMatteDeliveryEnabled {
    return self.depthDataDeliveryEnabled && _prv_portraitEffectsMatteDeliveryEnabled;
}

-(NSSet<AVSemanticSegmentationMatteType> *)availableSemanticSegmentationMatteType {
    if (!_availableSemanticSegmentationMatteType) {
        _availableSemanticSegmentationMatteType = [NSSet setWithArray:self.photoOutput.availableSemanticSegmentationMatteTypes];
    }
    return _availableSemanticSegmentationMatteType;
}

-(BOOL)isPhotoQualityPrioritizationSupported {
    if (@available(iOS 13.0,*)) {
        return YES;
    }
    return NO;
}

-(AVCapturePhotoQualityPrioritization)photoQualityPrioritization {
    return _prv_photoQualityPrioritization;
}

-(DWCameraManagerResolutionLevel)resolutionLevel {
    return _prv_resolutionLevel;
}

-(BOOL)isFlashSupported {
    return _videoDeviceInput.device.flashAvailable;
}
         
-(AVCaptureFlashMode)flashMode {
    return _prv_flashMode;
}

-(CGFloat)maxZoomFactor {
    return _videoDeviceInput.device.activeFormat.videoMaxZoomFactor;
}

-(CGFloat)zoomFactor {
    return _prv_zoomFactor;
}

-(CGFloat)maxRecordedDuration {
    return _prv_maxRecordedDuration;
}

-(int64_t)maxRecordedFileSize {
    return _prv_maxRecordedFileSize;
}

-(AVCaptureVideoStabilizationMode)stabilizationMode {
    return _prv_stabilizationMode;
}

-(BOOL)isMirrored {
    return _prv_isMirrored;
}

-(BOOL)isTorchOn {
    return _prv_isTorchOn;
}

-(BOOL)HDREnabled {
    return _prv_HDREnabled;
}

-(BOOL)autoSaveToLibrary {
    return _prv_autoSaveToLibrary;
}

-(NSMutableDictionary *)inProgressPhotoCaptureDelegates {
    if (!_inProgressPhotoCaptureDelegates) {
        _inProgressPhotoCaptureDelegates = [NSMutableDictionary dictionaryWithCapacity:0];
    }
    return _inProgressPhotoCaptureDelegates;
}

-(DWCameraManagerCaptuerMode)captureMode {
    return _prv_captureMode;
}

-(DWCameraManagerCameraPosition)cameraPosition {
    return _prv_cameraPosition;
}

-(AVCaptureConnection *)photoConn {
    if (!_photoConn) {
        _photoConn = [self->_captureOutput connectionWithMediaType:AVMediaTypeVideo];
    }
    return _photoConn;
}

-(AVCaptureConnection *)movieConn {
    if (_prv_captureMode != DWCameraManagerCaptuerModeVideo) {
        return nil;
    }
    return [_movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
}

-(BOOL)isRecording {
    return (_prv_captureMode == DWCameraManagerCaptuerModeVideo) && _movieFileOutput.isRecording;
}

-(BOOL)autoFocusAndExposeGestureEnabled {
    return _autoFocusAndExposeGesture.enabled;
}

@end
#pragma clang diagnostic pop
