//
//  DWCameraManager.h
//  DWCameraManager
//
//  Created by Wicky on 2020/6/15.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "DWCameraManagerView.h"
NS_ASSUME_NONNULL_BEGIN
#pragma clang diagnostic ignored "-Wunguarded-availability"
///拍摄模式
typedef NS_ENUM(NSUInteger, DWCameraManagerCaptuerMode) {
    DWCameraManagerCaptuerModePhoto,
    DWCameraManagerCaptuerModeVideo,
};

///摄像头位置
typedef NS_ENUM(NSInteger, DWCameraManagerCameraPosition) {
    DWCameraManagerCameraPositionUndefine = -2,
    DWCameraManagerCameraPositionUnspecified = -1,
    DWCameraManagerCameraPositionBack = 0,
    DWCameraManagerCameraPositionFront,
};

///拍摄分辨率
typedef NS_ENUM(NSUInteger, DWCameraManagerResolutionLevel) {
    DWCameraManagerResolutionLevelHigh,///默认，预置高分辨率
    DWCameraManagerResolutionLevelMedium,///预置中分辨率
    DWCameraManagerResolutionLevelLow,///预置低分辨率
    DWCameraManagerResolutionLevel1280x720,///1280 * 720
    DWCameraManagerResolutionLevel1920x1080,///1920 * 1080
    DWCameraManagerResolutionLevel3840x2160,///3840 * 2160
    DWCameraManagerResolutionLevelPhoto,///全分辨率（最高）
};

@class DWCameraManager;
@protocol DWCameraManagerDelegate <NSObject>

@optional
-(void)cameraManagerWillBeginConfiguringSession:(DWCameraManager *)cameraManager;

-(void)cameraManagerDidFinishConfiguringSession:(DWCameraManager *)cameraManager;

-(BOOL)cameraManager:(DWCameraManager *)cameraManager shouldAddDeviceInput:(AVCaptureDeviceInput *)deviceInput mediaType:(AVMediaType)mediaType;

-(void)cameraManager:(DWCameraManager *)cameraManager didFinishAddingDeviceInput:(AVCaptureDeviceInput *)deviceInput mediaType:(AVMediaType)mediaType;

-(BOOL)cameraManager:(DWCameraManager *)cameraManager shouldAddOutput:(AVCaptureOutput *)output;

-(void)cameraManager:(DWCameraManager *)cameraManager didFinishAddingOutput:(AVCaptureOutput *)output;

-(void)cameraManagerDidFinishStartRunning:(DWCameraManager *)cameraManager success:(BOOL)success;

-(void)cameraManager:(DWCameraManager *)cameraManager didFinishResumingSessionWithUserInfo:(nullable id)userInfo success:(BOOL)success;

-(void)cameraManager:(DWCameraManager *)cameraManager captureModeDidChangedFrom:(DWCameraManagerCaptuerMode)oldMode to:(DWCameraManagerCaptuerMode)newMode;

-(void)cameraManager:(DWCameraManager *)cameraManager captureModeChangeFailedWithTargetMode:(DWCameraManagerCaptuerMode)targetMode currentMode:(DWCameraManagerCaptuerMode)currentMode;

-(void)cameraManager:(DWCameraManager *)cameraManager cameraPositionDidChangedFrom:(DWCameraManagerCameraPosition)oldPosition to:(DWCameraManagerCameraPosition)newPosition;

-(void)cameraManager:(DWCameraManager *)cameraManager cameraPositionChangeFailedWithTargetPosition:(DWCameraManagerCameraPosition)targetPosition currentPosition:(DWCameraManagerCameraPosition)currentPosition;

-(void)cameraManager:(DWCameraManager *)cameraManager sessionWasInterruptedForReason:(AVCaptureSessionInterruptionReason)reason;

-(void)cameraManagerDidFinishStopRunning:(DWCameraManager *)cameraManager;

-(void)cameraManagerSessionInterruptedEnd:(DWCameraManager *)cameraManager;

-(void)cameraManager:(DWCameraManager *)cameraManager focusDidChangedWithMode:(AVCaptureFocusMode)focusMode atPoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange;

-(void)cameraManager:(DWCameraManager *)cameraManager exposeDidChangedWithMode:(AVCaptureExposureMode)exposeMode atPoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange;

-(void)cameraManager:(DWCameraManager *)cameraManager willBeginCapturingWithPhotoSettings:(nullable AVCapturePhotoSettings *)photoSettings;

-(void)cameraManager:(DWCameraManager *)cameraManager didFinishCapturingWithResolvedSettings:(nullable AVCaptureResolvedPhotoSettings *)photoSettings photoData:(NSData *)data;

-(void)cameraManager:(DWCameraManager *)cameraManager willBeginProcessingPhotoWithResolvedSettings:(AVCaptureResolvedPhotoSettings *)photoSettings;

-(void)cameraManager:(DWCameraManager *)cameraManager didFinishProcessingPhoto:(nullable AVCapturePhoto *)photo error:(nullable NSError *)error;

-(void)cameraManager:(DWCameraManager *)cameraManager willBeginCapturingLivePhotoWithResolvedSettings:(AVCaptureResolvedPhotoSettings *)photoSettings;

-(void)cameraManager:(DWCameraManager *)cameraManager didFinishCapturingLivePhotoWithResolvedSettings:(AVCaptureResolvedPhotoSettings *)photoSettings outputURL:(NSURL *)outputURL;

-(void)cameraManager:(DWCameraManager *)cameraManager didFinishPhotoDataGenerationWithPhotoData:(NSData *)data resolvedSettings:(nullable AVCaptureResolvedPhotoSettings *)photoSettings livePhotoFileURL:(nullable NSURL *)livePhotoFileURL semanticSegmentationMatteDataArray:(nullable NSArray *)semanticSegmentationMatteDataArray;

-(void)cameraManager:(DWCameraManager *)cameraManager didStartRecordingWithOutputURL:(NSURL *)outputURL backgroundTaskIdentifier:(UIBackgroundTaskIdentifier)backgroundTaskIdentifier connections:(NSArray<AVCaptureConnection *> * _Nullable)connections;

-(void)cameraManager:(DWCameraManager *)cameraManager didFinishRecordingWithSuccess:(BOOL)success outputURL:(NSURL *)outputURL backgroundTaskIdentifier:(UIBackgroundTaskIdentifier)backgroundTaskIdentifier connections:(NSArray<AVCaptureConnection *> * _Nullable)connections error:(NSError * _Nullable)error;

@end

@interface DWCameraManager : NSObject

///配置完成，可以准备开始工作，支持KVO
@property (nonatomic ,assign ,readonly) BOOL readyForUsage;

///正在工作
@property (nonatomic ,assign ,readonly) BOOL isRunning;

///代理对象
@property (nonatomic ,weak) id<DWCameraManagerDelegate> delegate;

///摄像会话
@property (nonatomic ,strong ,readonly) AVCaptureSession * captuerSession;

///预览视图
@property (nonatomic ,strong ,readonly) DWCameraManagerView * previewView;

///当前是否支持实况照片
@property (nonatomic ,assign ,readonly) BOOL isLivePhotoSupported;

///当前实况照片的开启状态
@property (nonatomic ,assign ,readonly) BOOL livePhotoEnabled;

///当前是否支持深度数据捕捉
@property (nonatomic ,assign ,readonly) BOOL isDepthDataDeliverySupported;

///当前深度数据捕捉的开启状态
@property (nonatomic ,assign ,readonly) BOOL depthDataDeliveryEnabled;

///当前是否支持肖像效果
@property (nonatomic ,assign ,readonly) BOOL isPortraitEffectsMatteDeliverySupported;

///当前肖像效果的开启状态（仅开启深度数据捕捉后有效）
@property (nonatomic ,assign ,readonly) BOOL portraitEffectsMatteDeliveryEnabled;

///当前开启的照片语义分割类型
@property (nonatomic ,strong ,readonly) NSArray<AVSemanticSegmentationMatteType> * enabledSemanticSegmentationMatteTypes;

///当前是否支持照片质量调整
@property (nonatomic ,assign ,readonly) BOOL isPhotoQualityPrioritizationSupported;

///当前的照片质量
@property (nonatomic ,assign ,readonly) AVCapturePhotoQualityPrioritization photoQualityPrioritization;

///当前拍摄分辨率
@property (nonatomic ,assign ,readonly) DWCameraManagerResolutionLevel resolutionLevel;

///当前是否支持闪光灯
@property (nonatomic ,assign ,readonly) BOOL isFlashSupported;

///当前闪光灯类型
@property (nonatomic ,assign ,readonly) AVCaptureFlashMode flashMode;

///当前缩放系数
@property (nonatomic ,assign ,readonly) CGFloat zoomFactor;

///最大缩放系数
@property (nonatomic ,assign ,readonly) CGFloat maxZoomFactor;

///最大录制时间(0为无限制)
@property (nonatomic ,assign ,readonly) CGFloat maxRecordedDuration;

///最大录制文件大小(0为无限制)
@property (nonatomic ,assign ,readonly) int64_t maxRecordedFileSize;

///防抖模式
@property (nonatomic ,assign ,readonly) AVCaptureVideoStabilizationMode stabilizationMode;

///是否镜像
@property (nonatomic ,assign ,readonly) BOOL isMirrored;

///当前手电筒开启状态
@property (nonatomic ,assign ,readonly) BOOL isTorchOn;

///HDR模式
@property (nonatomic ,assign ,readonly) BOOL HDREnabled;

///当前是否自动存入相册
@property (nonatomic ,assign ,readonly) BOOL autoSaveToLibrary;

///当前拍摄模式
@property (nonatomic ,assign ,readonly) DWCameraManagerCaptuerMode captureMode;

///当前摄像头位置
@property (nonatomic ,assign ,readonly) DWCameraManagerCameraPosition cameraPosition;

///是否正在录制视频
@property (nonatomic ,assign ,readonly) BOOL isRecording;

///当前自动对焦手势是否开启
@property (nonatomic ,assign ,readonly) BOOL autoFocusAndExposeGestureEnabled;

#pragma mark --- interface method ---
///获取当前摄像权限的状态
+(AVAuthorizationStatus)authorizationStatusForCamera;

///请求摄像权限
+(void)requestAccessForCameraWithCompletion:(void(^)(BOOL granted))completion;

///初始化并配置一个拍摄实例。内部自动获取权限并配置实例，若不需自动生成，请调用 +alloc 方法生成实例。
+(instancetype)generateCameraManager;

///配置当前摄像机session
-(void)configureSession;

///开启拍摄会话
-(void)startRunning;

///恢复被中断的拍摄会话
-(void)resumeInterruptedSessionWithUserInfo:(id)userInfo;

///停止拍摄会话
-(void)stopRunning;

///在sessionQueue中执行一个同步任务
-(void)performActionInSessionQueue:(dispatch_block_t)action;

///在sessionQueue中执行一个异步任务
-(void)performActionInSessionQueueAynchronously:(dispatch_block_t)action;

///切换当前实况照片的开启状态
-(void)toggleLivePhotoEnabled:(BOOL)enabled API_AVAILABLE(ios(10.0));

///切换当前深度数据捕捉的开启状态
-(void)toggleDepthDataDeliveryEnabled:(BOOL)enabled API_AVAILABLE(ios(10.0));

///切换当前肖像效果的开启状态
-(void)togglePortraitEffectsMatteDeliveryEnabled:(BOOL)enabled API_AVAILABLE(ios(10.0));

///切换当前开启的拍照语义分割类型。可支持区分头发，牙齿，皮肤
-(void)toggleEnabledSemanticSegmentationMatteTypes:(NSArray<AVSemanticSegmentationMatteType> *)types API_AVAILABLE(ios(13.0));

///调整当前的照片质量
-(void)togglePhotoQualityPrioritization:(AVCapturePhotoQualityPrioritization)qualityPrioritization API_AVAILABLE(ios(13.0));

///调整当前分辨率
-(void)toggleResolutionLevel:(DWCameraManagerResolutionLevel)level;

///调整闪光灯类型
-(void)toggleFlashMode:(AVCaptureFlashMode)flashMode;

///调整缩放比例
-(void)toggleZoomFactor:(CGFloat)zoomFactor;

///调整最大录制时长
-(void)toggleMaxRecordedDuration:(CGFloat)maxDuration;

///调整最大录制文件大小
-(void)toggleMaxRecordedFileSize:(int64_t)maxFileSize;

///调整防抖模式
-(void)toggleStabilizationMode:(AVCaptureVideoStabilizationMode)stabilizationMode;

///调整镜像模式
-(void)toggleMirrored:(BOOL)mirrored;

///调整手电筒开启状态
-(void)toggleTorchOn:(BOOL)on;

///切换HDR模式
-(void)toggleHDREnabled:(BOOL)enabled;

///切换拍摄模式
-(void)toggleCaptureMode:(DWCameraManagerCaptuerMode)captureMode;

///切换摄像头
-(void)toggleCameraPosition:(DWCameraManagerCameraPosition)position;

///切换是否自动存入相册
-(void)toggleAutoSaveToLibrary:(BOOL)autoSaveToLibrary;

///调整预览方向
-(void)togglePreviewOrientation:(UIInterfaceOrientation)interfaceOrientation;

///切换自动对焦曝光手势的有效性
-(void)toggleAutoFocusAndExposeGestureEnabled:(BOOL)enable;

///将系统坐标点转换为设备坐标点（因为摄像头坐标与系统坐标不同）
-(CGPoint)translateVideoLayerPointToCameraPoint:(CGPoint)layerPoint;

///将设备坐标点转换为系统坐标点
-(CGPoint)translateCameraPointToVideoLayerPoint:(CGPoint)cameraPoint;

///自动按点设置拍摄焦点和曝光模式
-(void)focusAndExposeAtPoint:(CGPoint)point;

///设置拍摄焦点
-(void)focusWithMode:(AVCaptureFocusMode)focusMode atPoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange;

///设置曝光模式
-(void)exposeWithMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange;

///设置拍摄焦点及曝光模式
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange;

///设置为自动对焦及调整曝光
-(void)autoFocusAndExpose;

///拍照
-(void)capturePhoto;

///开始录制视频
-(void)recordMovie;

///停止录制视频
-(void)stopRecording;

#pragma mark --- hook method ---
/// -init 时首先调用的初始化方法，子类覆写时需要调用super
-(void)setupDefaultValue NS_REQUIRES_SUPER;

@end

#pragma clang diagnostic pop
NS_ASSUME_NONNULL_END
