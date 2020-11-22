//
//  DWAlbumManager.m
//  DWAlbumPickerController
//
//  Created by Wicky on 2019/3/11.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWAlbumManager.h"

NSString * const DWAlbumMediaSourceURL = @"DWAlbumMediaSourceURL";
NSString * const DWAlbumErrorDomain = @"com.DWAlbumManager.error";
const NSInteger DWAlbumNilObjectErrorCode = 10001;
const NSInteger DWAlbumInvalidTypeErrorCode = 10002;
const NSInteger DWAlbumSaveErrorCode = 10003;
const NSInteger DWAlbumExportErrorCode = 10004;

@interface DWAlbumModel ()

@property (nonatomic ,strong) NSCache * albumImageCache;

@property (nonatomic ,strong) NSCache * albumVideoCache;

@property (nonatomic ,strong) NSCache * albumDataCache;

@property (nonatomic ,strong) NSCache * albumLivePhotoCache;

@end

@implementation DWAlbumModel

-(instancetype)init {
    if (self = [super init]) {
        _mediaType = DWAlbumMediaTypeAll;
        _sortType = DWAlbumSortTypeCreationDateAscending;
        _albumType = DWAlbumFetchAlbumTypeAll;
        _networkAccessAllowed = YES;
    }
    return self;
}

-(void)configTypeWithFetchOption:(DWAlbumFetchOption *)opt name:(NSString *)name result:(PHFetchResult *)result isCameraRoll:(BOOL)isCameraRoll {
    if (opt) {
        _mediaType = opt.mediaType;
        _sortType = opt.sortType;
        _albumType = opt.albumType;
        _networkAccessAllowed = opt.networkAccessAllowed;
    }
    _name = name;
    _isCameraRoll = isCameraRoll;
    [self configWithResult:result];
}

-(void)configWithResult:(PHFetchResult *)result {
    if (![_fetchResult isEqual:result]) {
        _fetchResult = result;
        _count = result.count;
        [self clearCache];
    }
}

-(void)clearCache {
    [_albumImageCache removeAllObjects];
    [_albumDataCache removeAllObjects];
    [_albumLivePhotoCache removeAllObjects];
    [_albumVideoCache removeAllObjects];
}

#pragma mark --- setter/getter ---
-(NSCache *)albumImageCache {
    if (!_albumImageCache) {
        _albumImageCache = [[NSCache alloc] init];
    }
    return _albumImageCache;
}

-(NSCache *)albumVideoCache {
    if (!_albumVideoCache) {
        _albumVideoCache = [[NSCache alloc] init];
    }
    return _albumVideoCache;
}

-(NSCache *)albumDataCache {
    if (!_albumDataCache) {
        _albumDataCache = [[NSCache alloc] init];
    }
    return _albumDataCache;
}

-(NSCache *)albumLivePhotoCache {
    if (!_albumLivePhotoCache) {
        _albumLivePhotoCache = [[NSCache alloc] init];
    }
    return _albumLivePhotoCache;
}

@end

@implementation DWAssetModel

-(void)configWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize media:(id)media info:(NSDictionary *)info  {
    _asset = asset;
    _targetSize = targetSize;
    _media = media;
    _info = info;
}

-(BOOL)satisfiedSize:(CGSize)targetSize {
    return YES;
}

#pragma mark --- setter/getter ---
-(PHAssetMediaType)mediaType {
    return _asset.mediaType;
}

-(NSString *)localIdentifier {
    return _asset.localIdentifier;
}

-(NSDate *)creationDate {
    return _asset.creationDate;
}

-(NSDate *)modificationDate {
    return _asset.modificationDate;
}

-(CGSize)originSize {
    return CGSizeMake(_asset.pixelWidth, _asset.pixelHeight);
}

#pragma mark --- override ---
-(NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p> (Media: %@ - Info: %@)",NSStringFromClass([self class]),self,self.media,self.info];
}

@end

@implementation DWImageAssetModel
@dynamic media;

-(void)configWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize media:(id)media info:(NSDictionary *)info{
    [super configWithAsset:asset targetSize:targetSize media:media info:info];
    _isDegraded = [info[PHImageResultIsDegradedKey] boolValue];
}

-(BOOL)satisfiedSize:(CGSize)targetSize {
    if (CGSizeEqualToSize(self.media.size, self.originSize)) {
        return YES;
    }
    
    if (CGSizeEqualToSize(targetSize, PHImageManagerMaximumSize)) {
        return CGSizeEqualToSize(self.media.size, self.originSize);
    }
    
    return targetSize.width - self.media.size.width < 20 && targetSize.height - self.media.size.height < 0;
}

@end

@implementation DWVideoAssetModel
@dynamic media;

@end

@implementation DWImageDataAssetModel
@dynamic media;

-(BOOL)satisfiedSize:(CGSize)targetSize {
    if (CGSizeEqualToSize(self.targetSize, self.originSize)) {
        return YES;
    }
    
    if (CGSizeEqualToSize(targetSize, PHImageManagerMaximumSize)) {
        return CGSizeEqualToSize(self.targetSize, PHImageManagerMaximumSize);
    }
    
    return self.targetSize.width >= targetSize.width && self.targetSize.height >= targetSize.height;
}

@end

@implementation DWLivePhotoAssetModel
@dynamic media;

-(void)configWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize media:(id)media info:(NSDictionary *)info{
    [super configWithAsset:asset targetSize:targetSize media:media info:info];
    if ([info.allKeys containsObject:PHImageResultIsDegradedKey]) {
        _isDegraded = [info[PHImageResultIsDegradedKey] boolValue];
    } else if ([info.allKeys containsObject:PHLivePhotoInfoIsDegradedKey]) {
        _isDegraded = [info[PHLivePhotoInfoIsDegradedKey] boolValue];
    } else {
        _isDegraded = NO;
    }
}

-(BOOL)satisfiedSize:(CGSize)targetSize {
    if (CGSizeEqualToSize(self.media.size, self.originSize)) {
        return YES;
    }
    
    if (CGSizeEqualToSize(targetSize, PHImageManagerMaximumSize)) {
        return CGSizeEqualToSize(self.media.size, self.originSize);
    }
    
    return self.media.size.width >= targetSize.width && self.media.size.height >= targetSize.height;
}

@end

@interface DWAlbumExportVideoOption ()

@property (nonatomic ,copy) NSString * presetStr;

@end

@implementation DWAlbumExportVideoOption

-(instancetype)init {
    if (self = [super init]) {
        _createIfNotExist = YES;
        _presetType = DWAlbumExportPresetTypePassthrough;
    }
    return self;
}

-(NSString *)presetStr {
    switch (_presetType) {
        case DWAlbumExportPresetTypeLowQuality:
            return AVAssetExportPresetLowQuality;
        case DWAlbumExportPresetTypeMediumQuality:
            return AVAssetExportPresetMediumQuality;
        case DWAlbumExportPresetTypeHEVCHighestQualityWithAlpha:
        {
            if (@available(iOS 13.0,*)) {
                return AVAssetExportPresetHEVCHighestQualityWithAlpha;
            }
        }
        case DWAlbumExportPresetTypeHEVCHighestQuality:
        {
            if (@available(iOS 11.0,*)) {
                return AVAssetExportPresetHEVCHighestQuality;
            }
        }
        case DWAlbumExportPresetTypeHighestQuality:
            return AVAssetExportPresetHighestQuality;
        case DWAlbumExportPresetType640x480:
            return AVAssetExportPreset640x480;
        case DWAlbumExportPresetType960x540:
            return AVAssetExportPreset960x540;
        case DWAlbumExportPresetType1280x720:
            return AVAssetExportPreset1280x720;
        case DWAlbumExportPresetTypeHEVC3840x2160WithAlpha:
        {
            if (@available(iOS 13.0,*)) {
                return AVAssetExportPresetHEVC3840x2160WithAlpha;
            }
        }
        case DWAlbumExportPresetTypeHEVC3840x2160:
        {
            if (@available(iOS 11.0,*)) {
                return AVAssetExportPresetHEVC3840x2160;
            }
        }
        case DWAlbumExportPresetType3840x2160:
        {
            if (@available(iOS 9.0,*)) {
                return AVAssetExportPreset3840x2160;;
            }
            return AVAssetExportPreset1920x1080;
        }
        case DWAlbumExportPresetTypeHEVC1920x1080WithAlpha:
        {
            if (@available(iOS 13.0,*)) {
                return AVAssetExportPresetHEVC1920x1080WithAlpha;
            }
        }
        case DWAlbumExportPresetTypeHEVC1920x1080:
        {
            if (@available(iOS 11.0,*)) {
                return AVAssetExportPresetHEVC1920x1080;
            }
        }
        case DWAlbumExportPresetType1920x1080:
            return AVAssetExportPreset1920x1080;
        case DWAlbumExportPresetTypeAppleM4A:
            return AVAssetExportPresetAppleM4A;
        case DWAlbumExportPresetTypePassthrough:
            return AVAssetExportPresetPassthrough;
        default:
            return AVAssetExportPresetPassthrough;
    }
}

@end

@interface DWAlbumManager ()

@property (nonatomic ,strong) PHImageRequestOptions * defaultOpt;

@end

@implementation DWAlbumManager

#pragma mark --- interface method ---
+(PHAuthorizationStatus)authorizationStatus {
    return [PHPhotoLibrary authorizationStatus];
}

+(void)requestAuthorization:(void (^)(PHAuthorizationStatus))completion {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(status);
            });
        }
    }];
}

-(void)fetchCameraRollWithOption:(DWAlbumFetchOption *)opt completion:(DWAlbumFetchCameraRollCompletion)completion {
    PHFetchOptions * phOpt = [self phOptFromDWOpt:opt];
    PHAssetCollection * smartAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].firstObject;
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:smartAlbum options:phOpt];
    if (completion) {
        DWAlbumModel * albumModel = [[DWAlbumModel alloc] init];
        [albumModel configTypeWithFetchOption:opt name:smartAlbum.localizedTitle result:fetchResult isCameraRoll:YES];
        completion(self,albumModel);
    }
}

-(void)fetchAlbumsWithOption:(DWAlbumFetchOption *)opt completion:(DWAlbumFetchAlbumCompletion)completion {
    PHFetchOptions * phOpt = [self phOptFromDWOpt:opt];
    NSMutableArray * allAlbums = [NSMutableArray arrayWithCapacity:5];
    
    DWAlbumFetchAlbumType albumType = opt.albumType;
    if (!opt) {
        albumType = DWAlbumFetchAlbumTypeAll;
    }
    if (albumType & DWAlbumFetchAlbumTypeAllUnited) {
        PHFetchResult * allAlbum = [PHAsset fetchAssetsWithOptions:phOpt];
        [allAlbums addObject:allAlbum];
    } else {
        if (albumType & DWAlbumFetchAlbumTypeMyPhotoSteam) {
            PHFetchResult *myPhotoStreamAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
            [allAlbums addObject:myPhotoStreamAlbum];
        }
        
        ///这里由于隐藏相册在PHAssetCollectionTypeSmartAlbum中，所以如果有隐藏选项，也要获取，在后续处理相关行为即可
        if (albumType & DWAlbumFetchAlbumTypeCameraRoll || albumType & DWAlbumFetchAlbumTypeHidden) {
            PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
            [allAlbums addObject:smartAlbums];
        }
        
        if (albumType & DWAlbumFetchAlbumTypeTopLevelUser) {
            PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
            [allAlbums addObject:topLevelUserCollections];
        }
        
        if (albumType & DWAlbumFetchAlbumTypeSyncedAlbum) {
            PHFetchResult *syncedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
            [allAlbums addObject:syncedAlbums];
        }
        
        if (albumType & DWAlbumFetchAlbumTypeAlbumCloudShared) {
            PHFetchResult *sharedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumCloudShared options:nil];
            [allAlbums addObject:sharedAlbums];
        }
    }
    BOOL needTransform = (completion != nil);
    NSMutableArray * albumArr = nil;
    if (needTransform) {
        albumArr = [NSMutableArray arrayWithCapacity:0];
    }
    
    if (albumType & DWAlbumFetchAlbumTypeAllUnited) {
        PHFetchResult * album = allAlbums.firstObject;
        if (album.count && needTransform) {
            DWAlbumModel * albumModel = [[DWAlbumModel alloc] init];
            [albumModel configTypeWithFetchOption:opt name:nil result:album isCameraRoll:NO];
            [albumArr addObject:albumModel];
        }
    } else {
        
        BOOL hasCamera = NO;
        for (PHFetchResult * album in allAlbums) {
            
            for (PHAssetCollection * obj in album) {
                
                if (![obj isKindOfClass:[PHAssetCollection class]]) {
                    continue;
                }
                
                ///这里判断隐藏相册
                ///由于隐藏相册引入，即使未指定DWAlbumFetchAlbumTypeCameraRoll也会获取PHAssetCollectionTypeSmartAlbum，所以分三种状况，既两者都有或只有其中一个，两者都有就不用返回了，只有一个就按条件判断了
                if ((albumType & DWAlbumFetchAlbumTypeHidden) && !(albumType & DWAlbumFetchAlbumTypeCameraRoll)) {
                    ///选择了隐藏模式，但是没有选择cameraRoll。过滤非hidden的smartAlbum
                    if (obj.assetCollectionType == PHAssetCollectionTypeSmartAlbum && obj.assetCollectionSubtype != PHAssetCollectionSubtypeSmartAlbumAllHidden) {
                        ///上述五种类型中，只有DWAlbumFetchAlbumTypeCameraRoll和DWAlbumFetchAlbumTypeHidden的assetCollectionType是PHAssetCollectionTypeSmartAlbum。所以这种情况就排除掉这里不是hidden的即可
                        continue;
                    }
                }
                
                if ((albumType & DWAlbumFetchAlbumTypeCameraRoll) && !(albumType & DWAlbumFetchAlbumTypeHidden)) {
                    ///这种情况就是不要隐藏，直接过滤隐藏就行
                    if (obj.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden) {//『隐藏』相册
                        continue;
                    }
                }
                
                if (obj.assetCollectionSubtype == 1000000201) {
                    continue; //『最近删除』相册
                }
                
                BOOL isCamera = YES;
                if (hasCamera) {
                    isCamera = NO;
                } else {
                    isCamera = [self isCameraRollAlbum:obj];
                }

                if (obj.estimatedAssetCount <= 0 && !isCamera) {
                    continue;
                }
                
                PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:obj options:phOpt];
                if (fetchResult.count < 1 && !isCamera) {
                    continue;
                }
                
                if (needTransform) {
                    DWAlbumModel * albumModel = [[DWAlbumModel alloc] init];
                    [albumModel configTypeWithFetchOption:opt name:obj.localizedTitle result:fetchResult isCameraRoll:isCamera];
                    if (isCamera) {
                        [albumArr insertObject:albumModel atIndex:0];
                        hasCamera = YES;
                    } else {
                        [albumArr addObject:albumModel];
                    }
                }
            }
        }
    }

    if (needTransform) {
        completion(self,albumArr);
    }
}

-(PHImageRequestID)fetchPostForAlbum:(DWAlbumModel *)album targetSize:(CGSize)targetSize completion:(DWAlbumFetchImageCompletion)completion {
    if (!album || CGSizeEqualToSize(targetSize, CGSizeZero)) {
        NSAssert(NO, @"DWAlbumManager can't fetch post for album is nil or targetSize is zero.");
        completion(self,nil);
        return PHInvalidImageRequestID;
    }
    
    PHAsset * asset = (album.sortType == DWAlbumSortTypeCreationDateAscending || album.sortType == DWAlbumSortTypeModificationDateAscending) ? album.fetchResult.lastObject : album.fetchResult.firstObject;
    
    return [self fetchImageWithAsset:asset targetSize:targetSize networkAccessAllowed:YES progress:nil completion:completion];
}

-(PHImageRequestID)fetchImageWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize networkAccessAllowed:(BOOL)networkAccessAllowed progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageCompletion)completion {
    
    if (!asset) {
        return PHInvalidImageRequestID;
    }
    
    PHImageRequestOptions * option = nil;
    PHAssetImageProgressHandler progressHandler = nil;
    if (progress) {
        progressHandler = ^(double progress_num, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progress(progress_num,error,stop,info);
            });
        };
        option = [[PHImageRequestOptions alloc] init];
        option.resizeMode = PHImageRequestOptionsResizeModeFast;
        option.progressHandler = progressHandler;
    } else {
        option = self.defaultOpt;
    }
    
    return [self.phManager requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage *result, NSDictionary *info) {
        if (result) {
            ///本地相册
            result = [self fixOrientation:result];
            BOOL downloadFinined = (![info[PHImageCancelledKey] boolValue] && !info[PHImageErrorKey]);
            if (downloadFinined && completion) {
                DWImageAssetModel * model = [[DWImageAssetModel alloc] init];
                [model configWithAsset:asset targetSize:targetSize media:result info:info];
                completion(self,model);
            }
        } else if (networkAccessAllowed && [info objectForKey:PHImageResultIsInCloudKey]) {
            ///iCloud
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.progressHandler = progressHandler;
            options.networkAccessAllowed = YES;
            options.resizeMode = PHImageRequestOptionsResizeModeFast;
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary * remoteinfo) {
                UIImage *resultImage = [UIImage imageWithData:imageData];
                resultImage = [self fixOrientation:resultImage];
                if (completion) {
                    DWImageAssetModel * model = [[DWImageAssetModel alloc] init];
                    [model configWithAsset:asset targetSize:targetSize media:resultImage info:remoteinfo];
                    completion(self,model);
                }
            }];
        } else {
            if (completion) {
                completion(self,nil);
            }
        }
    }];
}

-(PHImageRequestID)fetchImageDataWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize networkAccessAllowed:(BOOL)networkAccessAllowed progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageDataCompletion)completion {
    if (!asset) {
        return PHInvalidImageRequestID;
    }
    
    PHImageRequestOptions * option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    option.networkAccessAllowed = networkAccessAllowed;
    if (progress) {
        option.progressHandler = ^(double progress_num, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
            dispatch_async(dispatch_get_main_queue(), ^{
                progress(progress_num,error,stop,info);
            });
        };
    }
    
    return [self.phManager requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        if (imageData) {
            DWImageDataAssetModel * model = [[DWImageDataAssetModel alloc] init];
            [model configWithAsset:asset targetSize:targetSize media:imageData info:info];
            if (completion) {
                completion(self,model);
            }
        } else {
            if (completion) {
                completion(self,nil);
            }
        }
    }];
}

-(PHImageRequestID)fetchLivePhotoWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize networkAccessAllowed:(BOOL)networkAccessAllowed progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchLivePhotoCompletion)completion {
    if (@available(iOS 9.1,*)) {
        if (!asset) {
            return PHInvalidImageRequestID;
        }
        
        PHLivePhotoRequestOptions * option = [[PHLivePhotoRequestOptions alloc] init];
        option.networkAccessAllowed = networkAccessAllowed;
        if (progress) {
            option.progressHandler = ^(double progress_num, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    progress(progress_num,error,stop,info);
                });
            };
        }
        
        return [self.phManager requestLivePhotoForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFit options:option resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
            if (livePhoto) {
                DWLivePhotoAssetModel * model = [[DWLivePhotoAssetModel alloc] init];
                [model configWithAsset:asset targetSize:targetSize media:livePhoto info:info];
                if (completion) {
                    completion(self,model);
                }
            } else {
                if (completion) {
                    completion(self,nil);
                }
            }
        }];
    }
    return PHInvalidImageRequestID;
}

-(PHImageRequestID)fetchVideoWithAsset:(PHAsset *)asset networkAccessAllowed:(BOOL)networkAccessAllowed progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchVideoCompletion)completion {
    
    if (!asset) {
        return PHInvalidImageRequestID;
    }
    PHVideoRequestOptions *option = [[PHVideoRequestOptions alloc] init];
    option.networkAccessAllowed = networkAccessAllowed;
    option.progressHandler = ^(double progress_num, NSError *error, BOOL *stop, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progress) {
                progress(progress_num, error, stop, info);
            }
        });
    };
    return [self.phManager requestPlayerItemForVideo:asset options:option resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
        if (completion) {
            DWVideoAssetModel * model = [[DWVideoAssetModel alloc] init];
            [model configWithAsset:asset targetSize:PHImageManagerMaximumSize media:playerItem info:info];
            completion(self,model);
        }
    }];
}

-(PHImageRequestID)fetchImageWithAlbum:(DWAlbumModel *)album index:(NSUInteger)index targetSize:(CGSize)targetSize shouldCache:(BOOL)shouldCache progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageCompletion)completion {
    
    if (index >= album.fetchResult.count) {
        if (completion) {
            completion(self,nil);
        }
        return PHInvalidImageRequestID;
    }
    
    DWImageAssetModel * model = [album.albumImageCache objectForKey:@(index)];
    if (model && [model satisfiedSize:targetSize]) {
        if (completion) {
            completion(self,model);
        }
        return PHCachedImageRequestID;
    }
    
    PHAsset * asset = [album.fetchResult objectAtIndex:index];
    
    if (asset.mediaType != PHAssetMediaTypeImage && asset.mediaType != PHAssetMediaTypeVideo) {
        if (completion) {
            completion(self,nil);
        }
        return PHInvalidImageRequestID;
    }
    
    return [self fetchImageWithAsset:asset targetSize:targetSize networkAccessAllowed:album.networkAccessAllowed progress:progress completion:^(DWAlbumManager *mgr, DWImageAssetModel *obj) {
        if (obj && shouldCache && !obj.isDegraded) {
            [album.albumImageCache setObject:obj forKey:@(index)];
        }
        if (completion) {
            completion(mgr,obj);
        }
    }];
}

-(PHImageRequestID)fetchImageDataWithAlbum:(DWAlbumModel *)album index:(NSUInteger)index targetSize:(CGSize)targetSize shouldCache:(BOOL)shouldCache progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageDataCompletion)completion {
    if (index >= album.fetchResult.count) {
        if (completion) {
            completion(self,nil);
        }
        return PHInvalidImageRequestID;
    }
    
    DWImageDataAssetModel * model = [album.albumDataCache objectForKey:@(index)];
    if (model && [model satisfiedSize:targetSize]) {
        if (completion) {
            completion(self,model);
        }
        return PHCachedImageRequestID;
    }
    
    PHAsset * asset = [album.fetchResult objectAtIndex:index];
    
    if (asset.mediaType != PHAssetMediaTypeImage && asset.mediaType != PHAssetMediaTypeVideo) {
        if (completion) {
            completion(self,nil);
        }
        return PHInvalidImageRequestID;
    }
    
    return [self fetchImageDataWithAsset:asset targetSize:targetSize networkAccessAllowed:album.networkAccessAllowed progress:progress completion:^(DWAlbumManager * _Nullable mgr, DWImageDataAssetModel * _Nullable obj) {
        if (obj && shouldCache) {
            [album.albumDataCache setObject:obj forKey:@(index)];
        }
        if (completion) {
            completion(mgr,obj);
        }
    }];
}


-(PHImageRequestID)fetchLivePhotoWithAlbum:(DWAlbumModel *)album index:(NSUInteger)index targetSize:(CGSize)targetSize shouldCache:(BOOL)shouldCache progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchLivePhotoCompletion)completion {
    if (@available(iOS 9.1,*)) {
        if (index >= album.fetchResult.count) {
            if (completion) {
                completion(self,nil);
            }
            return PHInvalidImageRequestID;
        }
        DWLivePhotoAssetModel * model = [album.albumLivePhotoCache objectForKey:@(index)];
        if (model) {
            if (completion) {
                completion(self,model);
            }
            return PHCachedImageRequestID;
        }
        
        PHAsset * asset = [album.fetchResult objectAtIndex:index];
        
        if (asset.mediaType != PHAssetMediaTypeImage) {
            if (completion) {
                completion(self,nil);
            }
            return PHInvalidImageRequestID;
        }
        
        return [self fetchLivePhotoWithAsset:asset targetSize:targetSize networkAccessAllowed:album.networkAccessAllowed progress:progress completion:^(DWAlbumManager * _Nullable mgr, DWLivePhotoAssetModel * _Nullable obj) {
            if (obj && shouldCache) {
                [album.albumVideoCache setObject:obj forKey:@(index)];
            }
            if (completion) {
                completion(mgr,obj);
            }
        }];
    }
    return PHInvalidImageRequestID;
}

-(PHImageRequestID)fetchVideoWithAlbum:(DWAlbumModel *)album index:(NSUInteger)index shouldCache:(BOOL)shouldCache progrss:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchVideoCompletion)completion {
    if (index >= album.fetchResult.count) {
        if (completion) {
            completion(self,nil);
        }
        return PHInvalidImageRequestID;
    }
    
    DWVideoAssetModel * model = [album.albumVideoCache objectForKey:@(index)];
    if (model) {
        if (completion) {
            completion(self,model);
        }
        return PHCachedImageRequestID;
    }
    
    PHAsset * asset = [album.fetchResult objectAtIndex:index];
    
    if (asset.mediaType != PHAssetMediaTypeVideo) {
        if (completion) {
            completion(self,nil);
        }
        return PHInvalidImageRequestID;
    }
    
    return [self fetchVideoWithAsset:asset networkAccessAllowed:album.networkAccessAllowed progress:progress completion:^(DWAlbumManager *mgr, DWVideoAssetModel *obj) {
        if (obj && shouldCache) {
            [album.albumVideoCache setObject:obj forKey:@(index)];
        }
        if (completion) {
            completion(mgr,obj);
        }
    }];
}

-(PHImageRequestID)fetchOriginImageWithAsset:(PHAsset *)asset networkAccessAllowed:(BOOL)networkAccessAllowed progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageCompletion)completion {
    return [self fetchImageWithAsset:asset targetSize:PHImageManagerMaximumSize networkAccessAllowed:networkAccessAllowed progress:progress completion:completion];
}

-(PHImageRequestID)fetchOriginImageDataWithAsset:(PHAsset *)asset networkAccessAllowed:(BOOL)networkAccessAllowed progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageDataCompletion)completion {
    return [self fetchImageDataWithAsset:asset targetSize:PHImageManagerMaximumSize networkAccessAllowed:networkAccessAllowed progress:progress completion:completion];
}

-(PHImageRequestID)fetchOriginLivePhotoWithAsset:(PHAsset *)asset networkAccessAllowed:(BOOL)networkAccessAllowed progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchLivePhotoCompletion)completion {
    return [self fetchLivePhotoWithAsset:asset targetSize:PHImageManagerMaximumSize networkAccessAllowed:networkAccessAllowed progress:progress completion:completion];
}

-(PHImageRequestID)fetchOriginImageWithAlbum:(DWAlbumModel *)album index:(NSUInteger)index progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageCompletion)completion {
    return [self fetchImageWithAlbum:album index:index targetSize:PHImageManagerMaximumSize shouldCache:YES progress:progress completion:completion];
}

-(PHImageRequestID)fetchOriginImageDataWithAlbum:(DWAlbumModel *)album index:(NSUInteger)index progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchImageDataCompletion)completion {
    return [self fetchImageDataWithAlbum:album index:index targetSize:PHImageManagerMaximumSize shouldCache:YES progress:progress completion:completion];
}

-(PHImageRequestID)fetchOriginLivePhotoWithAlbum:(DWAlbumModel *)album index:(NSUInteger)index progress:(PHAssetImageProgressHandler)progress completion:(DWAlbumFetchLivePhotoCompletion)completion {
    return [self fetchLivePhotoWithAlbum:album index:index targetSize:PHImageManagerMaximumSize shouldCache:YES progress:progress completion:completion];
}

-(void)startCachingImagesForAssets:(NSArray <PHAsset *>*)assets targetSize:(CGSize)targetSize {
    [self.phManager startCachingImagesForAssets:assets targetSize:targetSize contentMode:PHImageContentModeAspectFill options:self.defaultOpt];
}

-(void)stopCachingImagesForAssets:(NSArray<PHAsset *> *)assets targetSize:(CGSize)targetSize {
    [self.phManager stopCachingImagesForAssets:assets targetSize:targetSize contentMode:PHImageContentModeAspectFill options:self.defaultOpt];
}

-(void)stopCachingAllImages {
    [self.phManager stopCachingImagesForAllAssets];
}

-(NSIndexSet *)startCachingImagesForAlbum:(DWAlbumModel *)album indexes:(NSIndexSet *)indexes targetSize:(CGSize)targetSize {
    if (!album || indexes.count == 0) {
        return nil;
    }
    
    NSMutableArray <PHAsset *>* filtered = [NSMutableArray arrayWithCapacity:indexes.count];
    NSMutableIndexSet * filteredSet = [NSMutableIndexSet indexSet];
    PHFetchResult * result = album.fetchResult;
    [self filterAlbum:album indexes:indexes handler:^(NSUInteger idx, BOOL *stop) {
        [filtered addObject:[result objectAtIndex:idx]];
        [filteredSet addIndex:idx];
    }];
    [self startCachingImagesForAssets:filtered targetSize:targetSize];
    return filteredSet;
}

-(void)stopCachingImagesForAlbum:(DWAlbumModel *)album indexes:(NSIndexSet *)indexes targetSize:(CGSize)targetSize {
    if (!album || indexes.count == 0) {
        return ;
    }
    
    NSMutableArray <PHAsset *>* filtered = [NSMutableArray arrayWithCapacity:indexes.count];
    PHFetchResult * result = album.fetchResult;
    [self filterAlbum:album indexes:indexes handler:^(NSUInteger idx, BOOL *stop) {
        [filtered addObject:[result objectAtIndex:idx]];
    }];
    [self stopCachingImagesForAssets:filtered targetSize:targetSize];
}

-(void)cancelRequestByID:(PHImageRequestID)requestID {
    [self.phManager cancelImageRequest:requestID];
}

-(void)cachedImageWithAsset:(DWAssetModel *)asset album:(DWAlbumModel *)album {
    if (!album || !asset) {
        return;
    }
    NSUInteger index = [album.fetchResult indexOfObject:asset.asset];
    if (index == NSNotFound) {
        return;
    }
    [album.albumImageCache setObject:asset forKey:@(index)];
}

-(void)clearCacheForAlbum:(DWAlbumModel *)album {
    [album clearCache];
}

-(void)saveImage:(UIImage *)image toAlbum:(NSString *)albumName location:(CLLocation *)loc createIfNotExist:(BOOL)createIfNotExist completion:(DWAlbumSaveMediaCompletion)completion {
    [self saveMedia:image url:nil mediaType:(DWAlbumMediaTypeImage) toAlbum:albumName location:loc createIfNotExist:createIfNotExist completion:completion];
}

-(void)saveImageToCameraRoll:(UIImage *)image completion:(DWAlbumSaveMediaCompletion)completion {
    [self saveImage:image toAlbum:nil location:nil createIfNotExist:NO completion:completion];
}

-(void)saveLivePhotoWithImage:(UIImage *)image video:(NSURL *)videoURL toAlbum:(NSString *)albumName location:(CLLocation *)loc createIfNotExist:(BOOL)createIfNotExist completion:(DWAlbumSaveMediaCompletion)completion {
    [self saveMedia:image url:videoURL mediaType:(DWAlbumMediaTypeAll) toAlbum:albumName location:loc createIfNotExist:createIfNotExist completion:completion];
}

-(void)saveLivePhotoToCameraRoll:(UIImage *)image video:(NSURL *)videoURL completion:(DWAlbumSaveMediaCompletion)completion {
    [self saveLivePhotoWithImage:image video:videoURL toAlbum:nil location:nil createIfNotExist:NO completion:completion];
}

-(void)saveVideo:(NSURL *)videoURL toAlbum:(NSString *)albumName location:(CLLocation *)loc createIfNotExist:(BOOL)createIfNotExist completion:(DWAlbumSaveMediaCompletion)completion {
    [self saveMedia:nil url:videoURL mediaType:(DWAlbumMediaTypeVideo) toAlbum:albumName location:loc createIfNotExist:createIfNotExist completion:completion];
}

-(void)saveVideoToCameraRoll:(NSURL *)videoURL completion:(DWAlbumSaveMediaCompletion)completion {
    [self saveVideo:videoURL toAlbum:nil location:nil createIfNotExist:NO completion:completion];
}

-(void)exportLivePhoto:(PHAsset *)asset option:(DWAlbumExportVideoOption *)opt completion:(DWAlbumExportLivePhotoCompletion)completion {
    if (!asset) {
        if (completion) {
            completion(self,NO,nil,nil,[NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumNilObjectErrorCode userInfo:@{@"errMsg":@"Invalid asset who is nil."}]);
        }
        return;
    }
    
    [self exportVideo:asset option:opt completion:^(DWAlbumManager * _Nullable mgr, BOOL success, DWVideoAssetModel * _Nullable video, NSError * _Nullable error) {
        if (success) {
            [self fetchOriginImageWithAsset:asset networkAccessAllowed:YES progress:nil completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable image) {
                if (!image.isDegraded && completion) {
                    completion(self,((image != nil) && (video != nil)),image,video,error);
                }
            }];
        } else {
            if (completion) {
                completion(self,NO,nil,nil,error);
            }
        }
    }];
}

-(void)exportVideo:(PHAsset *)asset option:(DWAlbumExportVideoOption *)opt completion:(DWAlbumExportVideoCompletion)completion {
    if (!asset) {
        if (completion) {
            completion(self,NO,nil,[NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumNilObjectErrorCode userInfo:@{@"errMsg":@"Invalid asset who is nil."}]);
        }
        return;
    }
    
    PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionOriginal;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    options.networkAccessAllowed = YES;
    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset* avasset, AVAudioMix* audioMix, NSDictionary* info){
        [self exportVideoWithAVAsset:(AVURLAsset *)avasset asset:asset option:opt completion:completion];
    }];
}

#pragma mark --- tool method ---
-(PHFetchOptions *)phOptFromDWOpt:(DWAlbumFetchOption *)fetchOpt {
    PHFetchOptions * opt = [[PHFetchOptions alloc] init];
    if (!fetchOpt) {
        opt.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    } else {
        switch (fetchOpt.mediaType) {
            case DWAlbumMediaTypeImage:
            {
                opt.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
            }
                break;
            case DWAlbumMediaTypeVideo:
            {
                opt.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",
                                   PHAssetMediaTypeVideo];
            }
                break;
            default:
                break;
        }
        
        switch (fetchOpt.sortType) {
            case DWAlbumSortTypeCreationDateAscending:
            {
                opt.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
            }
                break;
            case DWAlbumSortTypeCreationDateDesending:
            {
                opt.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
            }
                break;
            case DWAlbumSortTypeModificationDateDesending:
            {
                opt.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:NO]];
            }
                break;
            default:
                break;
        }
        
        if (fetchOpt.albumType & DWAlbumFetchAlbumTypeHidden) {
            opt.includeHiddenAssets = YES;
        }
    }
    return opt;
}

- (BOOL)isCameraRollAlbum:(PHAssetCollection *)metadata {
    NSString *versionStr = [[UIDevice currentDevice].systemVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    if (versionStr.length < 2) {
        versionStr = [versionStr stringByAppendingString:@"00"];
    } else if (versionStr.length == 2) {
        versionStr = [versionStr stringByAppendingString:@"0"];
    }
    CGFloat version = versionStr.floatValue;
    
    if (version >= 800 && version <= 802) {
        return ((PHAssetCollection *)metadata).assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumRecentlyAdded;
    } else {
        return ((PHAssetCollection *)metadata).assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary;
    }
}

/// 修正图片转向
- (UIImage *)fixOrientation:(UIImage *)aImage {
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

///获取资源
-(void)saveMedia:(id)media url:(NSURL *)url mediaType:(DWAlbumMediaType)mediaType toAlbum:(NSString *)albumName location:(CLLocation *)loc createIfNotExist:(BOOL)createIfNotExist completion:(DWAlbumSaveMediaCompletion)completion {
    
    ///状态码，0 合法，1 空参数，2 错误类型参数，3 不支持的存储类型，4 降级为图片，5 降级为视频
    NSInteger validCode = 0;
    
    switch (mediaType) {
        case DWAlbumMediaTypeImage:
        {
            if (!media && !url) {
                validCode = 1;
            } else if (!media) {
                ///如果media为空，将url给过去，图片类型后续统一使用media
                media = url;
            }
            
            if (![media isKindOfClass:[UIImage class]] && ![media isKindOfClass:[NSURL class]]) {
                validCode = 2;
            }
        }
            break;
        case DWAlbumMediaTypeVideo:
        {
            if (!url) {
                validCode = 1;
            }
            
            if (![url isKindOfClass:[NSURL class]]) {
                validCode = 2;
            }
        }
            break;
        ///这个类型是livePhoto
        case DWAlbumMediaTypeAll:
        {
            if (!media && !url) {
                validCode = 1;
            } else if (!media) {
                ///降级视频逻辑
                if (![url isKindOfClass:[NSURL class]]) {
                    validCode = 2;
                } else {
                    validCode = 5;
                    mediaType = DWAlbumMediaTypeVideo;
                }
            } else if (!url) {
                ///降级为图片逻辑
                if (![media isKindOfClass:[UIImage class]] && ![media isKindOfClass:[NSURL class]]) {
                    validCode = 2;
                } else {
                    validCode = 4;
                    mediaType = DWAlbumMediaTypeImage;
                }
            } else if (@available(iOS 9.1,*)) {
                ///参数都有，但是系统级别不够，降级成为图片
                if (![media isKindOfClass:[UIImage class]] && ![media isKindOfClass:[NSURL class]]) {
                    validCode = 2;
                } else {
                    validCode = 4;
                    mediaType = DWAlbumMediaTypeImage;
                }
            }
        }
            break;
        default:
        {
            validCode = 3;
        }
            break;
    }
    
    if (validCode == 1) {
        if (completion) {
            completion(self,NO,nil,[NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumNilObjectErrorCode userInfo:@{@"errMsg":@"Invalid media which is nil."}]);
        }
        return;
    }
    
    if (validCode == 2) {
        if (completion) {
            completion(self,NO,nil,[NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumInvalidTypeErrorCode userInfo:@{@"errMsg":@"Invalid media which should be UIImage or NSURL."}]);
        }
        return;
    }
    
    if (validCode == 3) {
        if (completion) {
            completion(self,NO,nil,[NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumInvalidTypeErrorCode userInfo:@{@"errMsg":@"Invalid media type which is not supported to save."}]);
        }
        return;
    }
    
    PHAssetCollection * album = nil;
    if (!albumName.length) {
        album = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil].firstObject;
    } else {
        ///遍历所有相册
        PHFetchResult * results = [PHAssetCollection fetchAssetCollectionsWithType:(PHAssetCollectionTypeAlbum) subtype:(PHAssetCollectionSubtypeAny) options:nil];
        for (PHAssetCollection * obj in results) {
            if ([obj.localizedTitle isEqualToString:albumName]) {
                album = obj;
                break;
            }
        }
        ///如果不存在则按需创建
        if (!album) {
            if (createIfNotExist) {
                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                    [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:albumName];
                } completionHandler:^(BOOL success, NSError * _Nullable error) {
                    [self saveMedia:media url:url mediaType:mediaType toAlbum:albumName location:loc createIfNotExist:NO completion:completion];
                }];
            } else {
                if (completion) {
                    completion(self,NO,nil,[NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumSaveErrorCode userInfo:@{@"errMsg":@"Save error for target path is not exist."}]);
                }
            }
            return;
        }
    }
    __block NSString *localIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *requestToCameraRoll = nil;
        switch (mediaType) {
            case DWAlbumMediaTypeImage:
            {
                if ([media isKindOfClass:[NSURL class]]) {
                    requestToCameraRoll = [PHAssetCreationRequest creationRequestForAssetFromImageAtFileURL:media];
                } else if ([media isKindOfClass:[UIImage class]]) {
                    requestToCameraRoll = [PHAssetChangeRequest creationRequestForAssetFromImage:media];
                }
            }
                break;
            case DWAlbumMediaTypeVideo:
            {
                requestToCameraRoll = [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:media];
            }
                break;
            case DWAlbumMediaTypeAll:
            {
                ///这里就这么写没问题，因为如果版本不合适，上面就已经降级为图片了，不会走到这里。所以这里并没有丢分支
                if (@available(iOS 9.1,*)) {
                    PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
                    if ([media isKindOfClass:[NSURL class]]) {
                        [request addResourceWithType:PHAssetResourceTypePhoto fileURL:media options:nil];
                    } else if ([media isKindOfClass:[UIImage class]]) {
                        [request addResourceWithType:PHAssetResourceTypePhoto data:UIImageJPEGRepresentation(media, 1) options:nil];
                    }
                    [request addResourceWithType:PHAssetResourceTypePairedVideo fileURL:url options:nil];
                    requestToCameraRoll = request;
                }
            }
                break;
            default:
                break;
        }
        
        localIdentifier = requestToCameraRoll.placeholderForCreatedAsset.localIdentifier;
        requestToCameraRoll.location = loc;
        requestToCameraRoll.creationDate = [NSDate date];
        
        if (albumName) {
            PHObjectPlaceholder * placeHolder = requestToCameraRoll.placeholderForCreatedAsset;
            PHAssetCollectionChangeRequest * requestToAlbum = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:album];
            [requestToAlbum addAssets:@[placeHolder]];
        }
        
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil] firstObject];
            switch (mediaType) {
                case DWAlbumMediaTypeImage:
                {
//                    model = [[DWImageAssetModel alloc] init];
//                    if ([media isKindOfClass:[UIImage class]]) {
//                        [model configWithAsset:asset targetSize:CGSizeZero media:media info:nil];
//                    } else {
//                        [model configWithAsset:asset targetSize:CGSizeZero media:[UIImage imageWithContentsOfFile:((NSURL *)media).path] info:@{DWAlbumMediaSourceURL:media}];
//                    }
                    [self fetchOriginImageWithAsset:asset networkAccessAllowed:NO progress:nil completion:^(DWAlbumManager * _Nullable mgr, DWImageAssetModel * _Nullable obj) {
                        if (!obj.isDegraded) {
                            if (completion) {
                                NSError * degradeError = nil;
                                if (validCode == 4) {
                                    //降级为图片的
                                    degradeError = [NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumSaveErrorCode userInfo:@{@"errMsg":@"Save error for target video is not exist and save operation is degraded to save image."}];
                                }
                                completion(self,YES,obj, degradeError);
                            }
                        }
                    }];
                }
                    break;
                case DWAlbumMediaTypeVideo:
                {
                    //                    model = [[DWVideoAssetModel alloc] init];
                    //                    [model configWithAsset:asset targetSize:CGSizeZero media:[[AVPlayerItem alloc] initWithURL:url] info:@{DWAlbumMediaSourceURL:url}];
                    [self fetchVideoWithAsset:asset networkAccessAllowed:NO
                                     progress:nil completion:^(DWAlbumManager * _Nullable mgr, DWVideoAssetModel * _Nullable obj) {
                        if (completion) {
                            NSError * degradeError = nil;
                            if (validCode == 5) {
                                //降级为视频的
                                degradeError = [NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumSaveErrorCode userInfo:@{@"errMsg":@"Save error for target image is not exist and save operation is degraded to save video."}];
                            }
                            completion(self,YES,obj, degradeError);
                        }
                    }];
                }
                    break;
                case DWAlbumMediaTypeAll:
                {
                    if (@available(iOS 9.1,*)) {
                        [self fetchOriginLivePhotoWithAsset:asset networkAccessAllowed:NO progress:nil completion:^(DWAlbumManager * _Nullable mgr, DWLivePhotoAssetModel * _Nullable obj) {
                            if (!obj.isDegraded) {
                                if (completion) {
                                    completion(self,YES,obj, nil);
                                }
                            }
                        }];
                    }
                }
                    break;
                default:
                    break;
            }
            
            
        } else {
            if (completion) {
                completion(self,NO,nil, error);
            }
        }
    }];
}

-(void)exportVideoWithAVAsset:(AVURLAsset *)avasset asset:(PHAsset *)asset option:(DWAlbumExportVideoOption *)opt completion:(DWAlbumExportVideoCompletion)completion {
    NSArray * presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avasset];
    DWAlbumExportPresetType presetType = DWAlbumExportPresetTypePassthrough;
    NSString * presetString = AVAssetExportPresetPassthrough;
    BOOL createInNotExist = YES;
    if (opt) {
        presetType = opt.presetType;
        presetString = opt.presetStr;
        createInNotExist = opt.createIfNotExist;
    }
    if (opt.presetType == presetType || [presets containsObject:opt.presetStr]) {
        AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:avasset presetName:presetString];
        NSString * fileName = opt.exportName?: [[NSNumber numberWithInteger:[[NSDate date] timeIntervalSince1970] * 1000] stringValue];
        if (avasset.URL && avasset.URL.pathExtension) {
            fileName = [fileName stringByAppendingPathExtension:avasset.URL.pathExtension];
        } else {
            fileName = [fileName stringByAppendingPathExtension:@"mp4"];
        }
        
        NSString * exportPath = opt.savePath?:NSTemporaryDirectory();
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:exportPath]) {
            if (!createInNotExist) {
                if (completion) {
                    completion(self,NO,nil,[NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumExportErrorCode userInfo:@{@"errMsg":@"Export error for target path is not exist!"}]);
                }
                return;
            } else {
                [[NSFileManager defaultManager] createDirectoryAtPath:exportPath withIntermediateDirectories:YES attributes:nil error:nil];
            }
        }
        
        exportPath = [exportPath stringByAppendingPathComponent:fileName];
        session.outputURL = [NSURL fileURLWithPath:exportPath];
        session.shouldOptimizeForNetworkUse = YES;
        
        NSArray *supportedTypeArray = session.supportedFileTypes;
        if ([supportedTypeArray containsObject:AVFileTypeMPEG4]) {
            session.outputFileType = AVFileTypeMPEG4;
        } else if (supportedTypeArray.count == 0) {
            if (completion) {
                completion(self,NO,nil,[NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumExportErrorCode userInfo:@{@"errMsg":@"Export error for media does't support exporting."}]);
            }
            return;
        } else {
            session.outputFileType = [supportedTypeArray objectAtIndex:0];
        }
        
        [session exportAsynchronouslyWithCompletionHandler:^(void) {
            
            if (completion) {
                NSError * error;
                switch (session.status) {
                    case AVAssetExportSessionStatusCompleted:
                    {
                        //doNothing
                    }
                        break;
                    case AVAssetExportSessionStatusFailed:
                    {
                        error = [NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumExportErrorCode userInfo:@{@"errMsg":@"Export Error!",@"detail":session.error}];
                    }
                        break;
                    case AVAssetExportSessionStatusCancelled:
                    {
                        error = [NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumExportErrorCode userInfo:@{@"errMsg":@"Export Error by canceling exporting."}];
                    }
                        break;
                    default:
                    {
                        error = [NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumExportErrorCode userInfo:@{@"errMsg":@"Export error with unknown status"}];
                    }
                        break;
                }
                
                if (error) {
                    completion(self,NO,nil,error);
                } else {
                    DWVideoAssetModel * model = [[DWVideoAssetModel alloc] init];
                    [model configWithAsset:asset targetSize:CGSizeZero media:nil info:@{DWAlbumMediaSourceURL:exportPath}];
                    completion(self,YES,model,nil);
                }
            }
        }];
    } else {
        if (completion) {
            completion(self,NO,nil,[NSError errorWithDomain:DWAlbumErrorDomain code:DWAlbumExportErrorCode userInfo:@{@"errMsg":@"Invalid export type which is not supported!"}]);
        }
    }
}

-(void)filterAlbum:(DWAlbumModel *)album indexes:(NSIndexSet *)indexes handler:(void (^)(NSUInteger idx, BOOL *stop))handler {
    if (!handler) {
        return;
    }
    PHFetchResult * result = album.fetchResult;
    NSUInteger count = result.count;
    NSCache * albumCache = album.albumImageCache;
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx < count && ![albumCache objectForKey:@(idx)]) {
            handler(idx,stop);
        }
    }];
}

#pragma mark --- setter/getter ---
-(PHCachingImageManager *)phManager {
    if (!_phManager) {
        _phManager = [[PHCachingImageManager alloc] init];
    }
    return _phManager;
}

-(PHImageRequestOptions *)defaultOpt {
    if (!_defaultOpt) {
        _defaultOpt = [[PHImageRequestOptions alloc] init];
        _defaultOpt.resizeMode = PHImageRequestOptionsResizeModeFast;
    }
    return _defaultOpt;
}

@end

@implementation DWAlbumFetchOption

#pragma mark --- override ---
-(instancetype)init {
    if (self = [super init]) {
        _mediaType = DWAlbumMediaTypeAll;
        _sortType = DWAlbumSortTypeCreationDateAscending;
        _albumType = DWAlbumFetchAlbumTypeAll;
        _networkAccessAllowed = YES;
    }
    return self;
}

@end
