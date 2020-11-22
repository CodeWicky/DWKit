//
//  DWCameraManagerDelegate.h
//  DWCameraManager
//
//  Created by Wicky on 2020/6/18.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN
#pragma clang diagnostic ignored "-Wunguarded-availability"
@class DWCameraManagerDelegate;

typedef void(^DWCameraManagerDelegatePhotoProcessing)(BOOL finish,id object,NSError * _Nullable error);
typedef void(^DWCameraManagerDelegateLivePhotoCaptureHandler)(BOOL finish,AVCaptureResolvedPhotoSettings * _Nullable resolvedSettings,NSURL * _Nullable outputURL);
typedef void(^DWCameraManagerDelegatePhotoDataGenerateCompletion)(NSData * photoData,AVCaptureResolvedPhotoSettings * _Nullable resolvedSettings,NSURL * _Nullable livePhotoFileURL,NSArray * semanticSegmentationMatteDataArray);
typedef void(^DWCameraManagerDelegateCompletion)(DWCameraManagerDelegate * delegate,AVCaptureResolvedPhotoSettings * _Nullable resolvedSettings,NSData * _Nullable photoData);
typedef void(^DWCameraManagerDelegateRecordHandler)(NSURL * outputURL,UIBackgroundTaskIdentifier backgroundTaskIdentifier,NSArray <AVCaptureConnection *>* _Nullable connections);
typedef void(^DWCameraManagerDelegateRecordCompletion)(BOOL success,NSURL * outputURL,UIBackgroundTaskIdentifier backgroundTaskIdentifier,NSArray <AVCaptureConnection *>* _Nullable connections,NSError * _Nullable error);
@interface DWCameraManagerDelegate : NSObject<AVCapturePhotoCaptureDelegate,AVCaptureFileOutputRecordingDelegate>

@property (nonatomic ,strong ,readonly) AVCapturePhotoSettings * photoSettings;

@property (nonatomic ,assign ,readonly) BOOL autoSaveToLibrary;

@property (nonatomic ,copy) DWCameraManagerDelegateLivePhotoCaptureHandler livePhotoCaptureHandler;

@property (nonatomic ,copy) DWCameraManagerDelegatePhotoDataGenerateCompletion photoDataGenerateCompletion;

+(instancetype)capturePhotoDelegateWithPhotoSettings:(AVCapturePhotoSettings *)photoSettings autoSaveToLibrary:(BOOL)autoSaveToLibrary willStartCapturing:(nullable dispatch_block_t)willStartCapturing photoProcessing:(nullable DWCameraManagerDelegatePhotoProcessing)photoProcessing completion:(nullable DWCameraManagerDelegateCompletion)completion;

+(instancetype)recordMovieDelegateWithFileURL:(NSURL *)fileURL autoSaveToLibrary:(BOOL)autoSaveToLibrary didStartRecording:(DWCameraManagerDelegateRecordHandler)startRecording finishRecording:(DWCameraManagerDelegateRecordCompletion)finishRecording;

@end
#pragma clang diagnostic pop
NS_ASSUME_NONNULL_END
