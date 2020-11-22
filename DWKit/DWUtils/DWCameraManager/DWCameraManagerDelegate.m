//
//  DWCameraManagerDelegate.m
//  DWCameraManager
//
//  Created by Wicky on 2020/6/18.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWCameraManagerDelegate.h"
#import <CoreImage/CoreImage.h>
#import "DWCameraManagerLibraryHelper.h"
#import "DWCameraManagerMacro.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wunguarded-availability"
@interface DWCameraManagerDelegate()

@property (nonatomic ,copy) dispatch_block_t willStartCapturing;

@property (nonatomic ,copy) DWCameraManagerDelegatePhotoProcessing photoProcessing;

@property (nonatomic ,copy) DWCameraManagerDelegateCompletion completion;

@property (nonatomic) CMTime maxPhotoProcessingTime;

@property (nonatomic) NSData* photoData;

@property (nonatomic) NSData* portraitEffectsMatteData;

@property (nonatomic) NSMutableArray* semanticSegmentationMatteDataArray;

@property (nonatomic ,strong) NSURL * livePhotoCompanionMovieURL;

@property (nonatomic ,assign) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@property (nonatomic ,strong) NSURL * fileURL;

@property (nonatomic ,copy) DWCameraManagerDelegateRecordHandler startRecording;

@property (nonatomic ,copy) DWCameraManagerDelegateRecordCompletion finishRecording;

@end

@implementation DWCameraManagerDelegate

#pragma mark --- interface method ---
+(instancetype)capturePhotoDelegateWithPhotoSettings:(AVCapturePhotoSettings *)photoSettings autoSaveToLibrary:(BOOL)autoSaveToLibrary willStartCapturing:(dispatch_block_t)willStartCapturing photoProcessing:(DWCameraManagerDelegatePhotoProcessing)photoProcessing completion:(DWCameraManagerDelegateCompletion)completion {
    return [[self alloc] initWithPhotoSettings:photoSettings autoSaveToLibrary:autoSaveToLibrary willStartCapturing:willStartCapturing photoProcessing:photoProcessing completion:completion];
}

+(instancetype)recordMovieDelegateWithFileURL:(NSURL *)fileURL autoSaveToLibrary:(BOOL)autoSaveToLibrary didStartRecording:(DWCameraManagerDelegateRecordHandler)startRecording finishRecording:(DWCameraManagerDelegateRecordCompletion)finishRecording {
    return [[self alloc] initWithFileURL:fileURL autoSaveToLibrary:autoSaveToLibrary didStartRecording:startRecording finishRecording:finishRecording];
}

#pragma mark --- capture delegate ---
///根据photoSetting以及设备当前状态调整好新的setting，将用于拍摄
-(void)captureOutput:(AVCapturePhotoOutput *)output willBeginCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    if ((resolvedSettings.livePhotoMovieDimensions.width > 0) && (resolvedSettings.livePhotoMovieDimensions.height > 0) && self.livePhotoCaptureHandler) {
        self.livePhotoCaptureHandler(NO,resolvedSettings,nil);
    }
    self.maxPhotoProcessingTime = CMTimeAdd(resolvedSettings.photoProcessingTimeRange.start, resolvedSettings.photoProcessingTimeRange.duration);
}

///将要根据调整好的setting开始拍照
-(void)captureOutput:(AVCapturePhotoOutput *)captureOutput willCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    if (self.willStartCapturing) {
        self.willStartCapturing();
    }

    CMTime onesec = CMTimeMake(1, 1);
    if (CMTimeCompare(self.maxPhotoProcessingTime, onesec) > 0 && self.photoProcessing) {
        self.photoProcessing(NO,resolvedSettings,nil);
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
#pragma clang diagnostic ignored"-Wdeprecated-implementations"
-(void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error {
    
    if (error != nil) {
        DWCameraManagerLogError(@"Error capturing photo: %@", error);
        return;
    }
    
    self.photoData = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
}
#pragma clang diagnostic pop

///拍摄完成，数据流处理完毕获取到photo对象
-(void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error {
    if (self.photoProcessing) {
        self.photoProcessing(YES,photo,error);
    }
    if (error != nil) {
        DWCameraManagerLogError(@"Error capturing photo: %@", error);
        return;
    }
    
    self.photoData = [photo fileDataRepresentation];
    
    if (photo.portraitEffectsMatte != nil) {
        CGImagePropertyOrientation orientation = [[photo.metadata objectForKey:(NSString*)kCGImagePropertyOrientation] intValue];
        AVPortraitEffectsMatte* portraitEffectsMatte = [photo.portraitEffectsMatte portraitEffectsMatteByApplyingExifOrientation:orientation];
        CVPixelBufferRef portraitEffectsMattePixelBuffer = [portraitEffectsMatte mattingImage];
        CIImage* portraitEffectsMatteImage = [CIImage imageWithCVPixelBuffer:portraitEffectsMattePixelBuffer options:@{ kCIImageAuxiliaryPortraitEffectsMatte : @(YES) }];
        CIContext* context = [CIContext context];
        CGColorSpaceRef linearColorSpace = CGColorSpaceCreateWithName( kCGColorSpaceLinearSRGB );
        self.portraitEffectsMatteData = [context HEIFRepresentationOfImage:portraitEffectsMatteImage format:kCIFormatRGBA8 colorSpace:linearColorSpace options:@{ (id)kCIImageRepresentationPortraitEffectsMatteImage : portraitEffectsMatteImage} ];
    } else {
        self.portraitEffectsMatteData = nil;
    }
    
    for (AVSemanticSegmentationMatteType type in captureOutput.enabledSemanticSegmentationMatteTypes) {
        [self handleSemanticSegmentationMatte:type photo:photo];
    }
}

///LivePhoto 已经拍摄完成并将视频对象导出到指定位置
-(void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishRecordingLivePhotoMovieForEventualFileAtURL:(NSURL *)outputFileURL resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings {
    if (self.livePhotoCaptureHandler) {
        self.livePhotoCaptureHandler(YES,resolvedSettings,outputFileURL);
    }
}

///导出livePhoto中的视频对象完成并处理完成
-(void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingLivePhotoToMovieFileAtURL:(NSURL *)outputFileURL duration:(CMTime)duration photoDisplayTime:(CMTime)photoDisplayTime resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error {
    if (error != nil) {
        DWCameraManagerLogError( @"Error processing Live Photo companion movie: %@", error );
        return;
    }
    self.livePhotoCompanionMovieURL = outputFileURL;
}

///拍照完成
-(void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error {
    if (error != nil) {
        DWCameraManagerLogError(@"Error capturing photo: %@.", error);
        [self finishCapturingWithResolvedSettings:nil photoData:nil];
        return;
    }
    
    if (self.photoData == nil) {
        DWCameraManagerLogError(@"No photo data resource.");
        [self finishCapturingWithResolvedSettings:nil photoData:nil];
        return;
    }
    
    if (self.photoDataGenerateCompletion) {
        self.photoDataGenerateCompletion(self.photoData,resolvedSettings, self.livePhotoCompanionMovieURL, self.semanticSegmentationMatteDataArray);
    }
    
    if (self.autoSaveToLibrary) {
        [DWCameraManagerLibraryHelper savePhoto:self.photoData photoSetting:self.photoSettings livePhotoURL:self.livePhotoCompanionMovieURL portraitEffectsMatteData:self.portraitEffectsMatteData semanticSegmentationMatteDataArray:self.semanticSegmentationMatteDataArray completion:^(BOOL success, NSError * _Nullable error) {
            [self finishCapturingWithResolvedSettings:resolvedSettings photoData:self.photoData];
        }];
    } else {
        [self finishCapturingWithResolvedSettings:resolvedSettings photoData:self.photoData];
    }
}

#pragma mark --- record delegate ---
-(void)captureOutput:(AVCaptureFileOutput *)output didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections {
    if (self.startRecording) {
        self.startRecording(fileURL, _backgroundTaskIdentifier, connections);
    }
}

-(void)captureOutput:(AVCaptureFileOutput *)output didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error {
    BOOL success = YES;
    if (error) {
        DWCameraManagerLogError(@"Movie file finishing error: %@", error);
        success = [error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue];
    }
    
    if (success && _autoSaveToLibrary) {
        [DWCameraManagerLibraryHelper saveVideo:outputFileURL completion:^(BOOL success, NSError * _Nullable error) {
            [self finishRecordingWithSuccess:success fileURL:outputFileURL backgroundTaskIdentifier:self->_backgroundTaskIdentifier fromConnections:connections error:error];
        }];
    } else {
        [self finishRecordingWithSuccess:NO fileURL:outputFileURL backgroundTaskIdentifier:_backgroundTaskIdentifier fromConnections:connections error:error];
    }
}

#pragma mark --- tool method ---
-(instancetype)initWithPhotoSettings:(AVCapturePhotoSettings *)photoSettings autoSaveToLibrary:(BOOL)autoSaveToLibrary willStartCapturing:(dispatch_block_t)willStartCapturing photoProcessing:(DWCameraManagerDelegatePhotoProcessing)photoProcessing completion:(DWCameraManagerDelegateCompletion)completion {
    if (self = [super init]) {
        _photoSettings = photoSettings;
        _autoSaveToLibrary = autoSaveToLibrary;
        _willStartCapturing = willStartCapturing;
        _photoProcessing = photoProcessing;
        _completion = completion;
    }
    return self;
}

-(instancetype)initWithFileURL:(NSURL *)fileURL autoSaveToLibrary:(BOOL)autoSaveToLibrary didStartRecording:(DWCameraManagerDelegateRecordHandler)startRecording finishRecording:(DWCameraManagerDelegateRecordCompletion)finishRecording {
    if (self = [super init]) {
        if (![UIDevice currentDevice].isMultitaskingSupported) {
            _backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
        }
        _fileURL = fileURL;
        _autoSaveToLibrary = autoSaveToLibrary;
        _startRecording = startRecording;
        _finishRecording = finishRecording;
    }
    return self;
}

-(void)handleSemanticSegmentationMatte:(AVSemanticSegmentationMatteType)semanticSegmentationMatteType photo:(AVCapturePhoto *)photo {
    CIImageOption imageOption = nil;
    if (semanticSegmentationMatteType == AVSemanticSegmentationMatteTypeHair) {
        imageOption = kCIImageAuxiliarySemanticSegmentationHairMatte;
    } else if (semanticSegmentationMatteType == AVSemanticSegmentationMatteTypeSkin) {
        imageOption = kCIImageAuxiliarySemanticSegmentationSkinMatte;
    } else if (semanticSegmentationMatteType == AVSemanticSegmentationMatteTypeTeeth) {
        imageOption = kCIImageAuxiliarySemanticSegmentationTeethMatte;
    } else {
        DWCameraManagerLogError(@"%@ Matte type is not supported!",semanticSegmentationMatteType.description);
        return;
    }

    CGImagePropertyOrientation orientation = [[photo.metadata objectForKey:(NSString*)kCGImagePropertyOrientation] intValue];
    AVSemanticSegmentationMatte* semanticSegmentationMatte = [[photo semanticSegmentationMatteForType:semanticSegmentationMatteType] semanticSegmentationMatteByApplyingExifOrientation:orientation];
    if (semanticSegmentationMatte == nil) {
        DWCameraManagerLogError(@"No %@ in AVCapturePhoto.", semanticSegmentationMatteType.description);
        return;
    }
    CVPixelBufferRef semanticSegmentationMattePixelBuffer = [semanticSegmentationMatte mattingImage];
    CIImage* semanticSegmetationMatteImage = [CIImage imageWithCVPixelBuffer:semanticSegmentationMattePixelBuffer options:@{imageOption : @(YES)}];
    CIContext* context = [CIContext context];
    CGColorSpaceRef linearColorSpace = CGColorSpaceCreateWithName( kCGColorSpaceLinearSRGB );
    NSData *semanticSegmentationData = [context HEIFRepresentationOfImage:semanticSegmetationMatteImage format:kCIFormatRGBA8 colorSpace:linearColorSpace options:@{ (id)kCIImageRepresentationPortraitEffectsMatteImage : semanticSegmetationMatteImage} ];
    if (semanticSegmentationData) {
        [self.semanticSegmentationMatteDataArray addObject:semanticSegmentationData];
    }
}

-(void)finishCapturingWithResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings photoData:(NSData *)data {
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.livePhotoCompanionMovieURL.path]) {
        NSError* error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:self.livePhotoCompanionMovieURL.path error:&error];
        if (error) {
            DWCameraManagerLogError( @"Could not remove file at url: %@ error:%@", self.livePhotoCompanionMovieURL.path,error);
        }
    }
    
    if (self.completion) {
        self.completion(self,resolvedSettings,data);
    }
}

-(void)finishRecordingWithSuccess:(BOOL)success fileURL:(NSURL *)fileURL backgroundTaskIdentifier:(UIBackgroundTaskIdentifier)backgroundTaskIdentifier fromConnections:(NSArray<AVCaptureConnection *> *)connections error:(NSError *)error {
    if (self.finishRecording) {
        self.finishRecording(success,fileURL, backgroundTaskIdentifier, connections, error);
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileURL.path]) {
        [[NSFileManager defaultManager] removeItemAtPath:fileURL.path error:NULL];
    }
    
    if (backgroundTaskIdentifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTaskIdentifier];
    }
}

#pragma mark --- setter/getter ---
-(NSMutableArray *)semanticSegmentationMatteDataArray {
    if (!_semanticSegmentationMatteDataArray) {
        _semanticSegmentationMatteDataArray = [NSMutableArray arrayWithCapacity:0];
    }
    return _semanticSegmentationMatteDataArray;
}

@end
#pragma clang diagnostic pop
