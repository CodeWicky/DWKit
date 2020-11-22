//
//  DWCameraManagerLibraryHelper.h
//  DWCameraManager
//
//  Created by Wicky on 2020/6/22.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
typedef void(^DWCameraManagerLibraryHelperCompletion)(BOOL success,NSError * _Nullable error);
@interface DWCameraManagerLibraryHelper : NSObject

+(void)savePhoto:(NSData *)photoData photoSetting:(nullable __kindof AVCapturePhotoSettings *)photoSettings livePhotoURL:(nullable NSURL *)livePhotoURL portraitEffectsMatteData:(nullable NSData *)portraitEffectsMatteData semanticSegmentationMatteDataArray:(nullable NSArray *)semanticSegmentationMatteDataArray completion:(nullable DWCameraManagerLibraryHelperCompletion)completion;

+(void)saveVideo:(NSURL *)fileURL completion:(nullable DWCameraManagerLibraryHelperCompletion)completion;

@end
#pragma clang diagnostic pop
NS_ASSUME_NONNULL_END
