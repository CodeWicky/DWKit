//
//  DWCameraManagerLibraryHelper.m
//  DWCameraManager
//
//  Created by Wicky on 2020/6/22.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWCameraManagerLibraryHelper.h"
#import <Photos/Photos.h>
#import "DWCameraManagerMacro.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wunguarded-availability"
@implementation DWCameraManagerLibraryHelper

+(void)savePhoto:(NSData *)photoData photoSetting:(AVCapturePhotoSettings *)photoSettings livePhotoURL:(NSURL *)livePhotoURL portraitEffectsMatteData:(NSData *)portraitEffectsMatteData semanticSegmentationMatteDataArray:(NSArray *)semanticSegmentationMatteDataArray completion:(DWCameraManagerLibraryHelperCompletion)completion {
    [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
        if (status == PHAuthorizationStatusAuthorized) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetResourceCreationOptions* options = [[PHAssetResourceCreationOptions alloc] init];
                if (photoSettings) {
                    options.uniformTypeIdentifier = photoSettings.processedFileType;
                }
                PHAssetCreationRequest* creationRequest = [PHAssetCreationRequest creationRequestForAsset];
                [creationRequest addResourceWithType:PHAssetResourceTypePhoto data:photoData options:options];
                
                if (livePhotoURL) {
                    PHAssetResourceCreationOptions* livePhotoCompanionMovieResourceOptions = [[PHAssetResourceCreationOptions alloc] init];
                    livePhotoCompanionMovieResourceOptions.shouldMoveFile = YES;
                    [creationRequest addResourceWithType:PHAssetResourceTypePairedVideo fileURL:livePhotoURL options:livePhotoCompanionMovieResourceOptions];
                }
                
                if (portraitEffectsMatteData) {
                    PHAssetCreationRequest* creationRequest = [PHAssetCreationRequest creationRequestForAsset];
                    [creationRequest addResourceWithType:PHAssetResourceTypePhoto data:portraitEffectsMatteData options:nil];
                }
                
                for (NSData* data in semanticSegmentationMatteDataArray) {
                    PHAssetCreationRequest* creationRequest = [PHAssetCreationRequest creationRequestForAsset];
                    [creationRequest addResourceWithType:PHAssetResourceTypePhoto data:data options:nil];
                }
            } completionHandler:^(BOOL success, NSError* _Nullable error) {
                if (!success) {
                    DWCameraManagerLogError(@"Error occurred while saving photo to photo library: %@.",error);
                }
                if (completion) {
                    completion(success,error);
                }
            }];
        } else {
            DWCameraManagerLogError(@"Not authorized to save photo.");
            if (completion) {
                completion(NO,notAuthorizedError());
            }
        }
    }];
}

+(void)saveVideo:(NSURL *)fileURL completion:(DWCameraManagerLibraryHelperCompletion)completion {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                PHAssetResourceCreationOptions* options = [[PHAssetResourceCreationOptions alloc] init];
                options.shouldMoveFile = YES;
                PHAssetCreationRequest* creationRequest = [PHAssetCreationRequest creationRequestForAsset];
                [creationRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:fileURL options:options];
            } completionHandler:^(BOOL success, NSError* error) {
                if (!success) {
                    DWCameraManagerLogError(@"AVCam couldn't save the movie to your photo library: %@", error);
                }
                if (completion) {
                    completion(success,error);
                }
            }];
        } else {
            DWCameraManagerLogError(@"Not authorized to save video.");
            if (completion) {
                completion(NO,notAuthorizedError());
            }
        }
    }];
}

NS_INLINE NSError * notAuthorizedError() {
    return [NSError errorWithDomain:@"com.DWCameraManager.error" code:10000 userInfo:@{@"em":@"Could not save to library for not authorized library usage."}];
}

@end
#pragma clang diagnostic pop
