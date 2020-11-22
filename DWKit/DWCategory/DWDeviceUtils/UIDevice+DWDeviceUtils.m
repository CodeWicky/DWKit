//
//  UIDevice+DWDeviceUtils.m
//  DWLogger
//
//  Created by Wicky on 2017/10/9.
//  Copyright © 2017年 Wicky. All rights reserved.
//

#import "UIDevice+DWDeviceUtils.h"
#import <sys/utsname.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <Security/Security.h>

static NSDictionary * infoDic = nil;

@implementation UIDevice (DWDeviceSystemInfo)

+(NSString *)dw_projectBuildNo {
    return getInfoFromSystemInfoDic(CFBridgingRelease(kCFBundleVersionKey));
}

+(NSString *)dw_projectBundleId {
    return getInfoFromSystemInfoDic(CFBridgingRelease(kCFBundleIdentifierKey));
}

+(NSString *)dw_projectDisplayName {
    return getInfoFromSystemInfoDic(CFBridgingRelease(kCFBundleExecutableKey));
}

+(NSString *)dw_projectVersion {
    return getInfoFromSystemInfoDic(@"CFBundleShortVersionString");
}

+(NSString *)dw_deviceUUID {
    return loadUUID();
}

+(NSString *)dw_deviceUserName {
    return [UIDevice currentDevice].name;
}

+(NSString *)dw_deviceName {
    return [UIDevice currentDevice].systemName;
}

+(NSString *)dw_deviceSystemVersion {
    return [UIDevice currentDevice].systemVersion;
}

+(NSString *)dw_deviceModel {
    return [UIDevice currentDevice].model;
}

+(NSString *)dw_devicePlatform {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString: systemInfo.machine encoding:NSASCIIStringEncoding];
}

+(NSString *)dw_deviceDetailModel {
    NSString * platform = [self dw_devicePlatform];
    NSString * model = [deviceModelMap() valueForKey:platform];
    if (model.length) {
        return model;
    }
    return @"Unknown";
}

+(NSString *)dw_deviceCPUCore {
    NSString * platform = [self dw_devicePlatform];
    NSString * core = [deviceCPUCoreMap() valueForKey:platform];
    if (core.length) {
        return core;
    }
    return @"Unknown";
}

+(CGFloat)dw_deviceTotalMemory {
    float size = 0.0;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: nil];
    if (dictionary) {
        NSNumber *_total = [dictionary objectForKey:NSFileSystemSize];
        size = [_total unsignedLongLongValue]*1.0/(1024);
    }
    return size;
}

+(CGFloat)dw_deviceFreeMemory {
    float size = 0.0;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: nil];
    if (dictionary)
    {
        NSNumber *_free = [dictionary objectForKey:NSFileSystemFreeSize];
        size = [_free unsignedLongLongValue]*1.0/(1024);
    }
    return size;
}

+(NSString *)dw_mobileOperator {
    CTTelephonyNetworkInfo * info = [[CTTelephonyNetworkInfo alloc] init];
    CTCarrier * carrier = [info subscriberCellularProvider];
    NSString * mCarrier = [NSString stringWithFormat:@"%@",[carrier carrierName]];
    return mCarrier;
}

+(NSString *)dw_developSDKVersion {
    return getInfoFromSystemInfoDic(@"DTSDKBuild");
}

+(CGFloat)dw_batteryVolumn {
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    double deviceLevel = [UIDevice currentDevice].batteryLevel;
    [UIDevice currentDevice].batteryMonitoringEnabled = NO;
    return deviceLevel;
}

#pragma mark --- tool func ---
NS_INLINE id getInfoFromSystemInfoDic(NSString * key) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        infoDic = [[NSBundle mainBundle] infoDictionary];
    });
    return [infoDic objectForKey:key];
}

NS_INLINE NSString * uuidString() {
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    
    NSString *uuidValue = (__bridge_transfer NSString *)uuidStringRef;
    uuidValue = [uuidValue lowercaseString];
    uuidValue = [uuidValue stringByReplacingOccurrencesOfString:@"-" withString:@""];
    return uuidValue;
}

NS_INLINE NSString * loadUUID() {
    NSString * uuid = nil;
    NSString * storeKey = uuidKey();
    NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
    uuid = [ud valueForKey:storeKey];
    
    if (uuid.length) {
        return uuid;
    }

    uuid = loadUUIDFromKeyChain(storeKey);

    if (uuid.length) {
        [ud setValue:uuid forKey:storeKey];
        [ud synchronize];
        return uuid;
    }
    
    uuid = uuidString();
    if (uuid) {
        [ud setValue:uuid forKey:storeKey];
        [ud synchronize];
        saveUUIDToKeyChain(uuid, storeKey);
    }
    return uuid;
}

NS_INLINE NSString * uuidKey() {
    return [NSString stringWithFormat:@"uuid-for-%@",[UIDevice dw_projectBundleId]];
}

NS_INLINE NSString * loadUUIDFromKeyChain(NSString * storeKey) {
    if (!storeKey.length) {
        return nil;
    }
    
    CFTypeRef result = NULL;
    NSMutableDictionary *query = queryDictionary(storeKey);
    [query setObject:@YES forKey:(__bridge id)kSecReturnData];
    [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status != errSecSuccess) {
        return nil;
    }
    
    NSData * data = (__bridge_transfer NSData *)result;
    if ([data length]) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return nil;
}

NS_INLINE void saveUUIDToKeyChain(NSString * uuid,NSString * storeKey) {
    
    if (!uuid.length || !storeKey.length) {
        return;
    }
    
    NSData * uuidData = [uuid dataUsingEncoding:NSUTF8StringEncoding];
    if (!uuidData.length) {
        return;
    }
    
    NSMutableDictionary *query = nil;
    NSMutableDictionary *searchQuery = queryDictionary(storeKey);
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchQuery, nil);
    if (status == errSecSuccess) {
        query = [NSMutableDictionary dictionary];
        [query setObject:uuidData forKey:(__bridge id)kSecValueData];
        status = SecItemUpdate((__bridge CFDictionaryRef)(searchQuery), (__bridge CFDictionaryRef)(query));
    } else if (status == errSecItemNotFound){
        query = queryDictionary(storeKey);
        [query setObject:uuidData forKey:(__bridge id)kSecValueData];
        status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    }
}

NS_INLINE NSMutableDictionary * queryDictionary(NSString * storeKey) {
    NSMutableDictionary * query = [NSMutableDictionary dictionary];
    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:storeKey forKey:(__bridge id)kSecAttrService];
    [query setObject:storeKey forKey:(__bridge id)kSecAttrAccount];
    [query setObject:(__bridge id)(kSecAttrSynchronizableAny) forKey:(__bridge id)(kSecAttrSynchronizable)];
    return query;
}

NS_INLINE NSDictionary * deviceModelMap () {
    static NSDictionary * modelMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        modelMap = @{
            ///apple tv
            @"AppleTV1,1":@"Apple TV (1st generation)",
            @"AppleTV2,1":@"Apple TV (2nd generation)",
            @"AppleTV3,1":@"Apple TV (3rd generation)",
            @"AppleTV3,2":@"Apple TV (3rd generation)",
            @"AppleTV5,3":@"Apple TV (4th generation)",
            @"AppleTV6,2":@"Apple TV 4K",
            
            ///apple watch
            @"Watch1,1":@"Apple Watch (1st generation)",
            @"Watch1,2":@"Apple Watch (1st generation)",
            @"Watch2,6":@"Apple Watch Series 1",
            @"Watch2,7":@"Apple Watch Series 1",
            @"Watch2,3":@"Apple Watch Series 2",
            @"Watch2,4":@"Apple Watch Series 2",
            @"Watch3,1":@"Apple Watch Series 3",
            @"Watch3,2":@"Apple Watch Series 3",
            @"Watch3,3":@"Apple Watch Series 3",
            @"Watch3,4":@"Apple Watch Series 3",
            @"Watch4,1":@"Apple Watch Series 4",
            @"Watch4,2":@"Apple Watch Series 4",
            @"Watch4,3":@"Apple Watch Series 4",
            @"Watch4,4":@"Apple Watch Series 4",
            @"Watch5,1":@"Apple Watch Series 5",
            @"Watch5,2":@"Apple Watch Series 5",
            @"Watch5,3":@"Apple Watch Series 5",
            @"Watch5,4":@"Apple Watch Series 5",
            
            ///home pod
            @"AudioAccessory1,1":@"HomePod",
            @"AudioAccessory1,2":@"HomePod",
            
            ///iPad
            @"iPad1,1":@"iPad",
            @"iPad2,1":@"iPad 2",
            @"iPad2,2":@"iPad 2",
            @"iPad2,3":@"iPad 2",
            @"iPad2,4":@"iPad 2",
            @"iPad3,1":@"iPad (3rd generation)",
            @"iPad3,2":@"iPad (3rd generation)",
            @"iPad3,3":@"iPad (3rd generation)",
            @"iPad3,4":@"iPad (4th generation)",
            @"iPad3,5":@"iPad (4th generation)",
            @"iPad3,6":@"iPad (4th generation)",
            @"iPad6,11":@"iPad (5th generation)",
            @"iPad6,12":@"iPad (5th generation)",
            @"iPad7,5":@"iPad (6th generation)",
            @"iPad7,6":@"iPad (6th generation)",
            @"iPad7,11":@"iPad (7th generation)",
            @"iPad7,12":@"iPad (7th generation)",
            
            ///iPad Air
            @"iPad4,1":@"iPad Air",
            @"iPad4,2":@"iPad Air",
            @"iPad4,3":@"iPad Air",
            @"iPad5,3":@"iPad Air 2",
            @"iPad5,4":@"iPad Air 2",
            @"iPad11,3":@"iPad Air (3rd generation)",
            @"iPad11,4":@"iPad Air (3rd generation)",
            
            ///iPad Pro
            @"iPad6,7":@"iPad Pro (12.9-inch)",
            @"iPad6,8":@"iPad Pro (12.9-inch)",
            @"iPad6,3":@"iPad Pro (9.7-inch)",
            @"iPad6,4":@"iPad Pro (9.7-inch)",
            @"iPad7,1":@"iPad Pro (12.9-inch) (2nd generation)",
            @"iPad7,2":@"iPad Pro (12.9-inch) (2nd generation)",
            @"iPad7,3":@"iPad Pro (10.5-inch)",
            @"iPad7,4":@"iPad Pro (10.5-inch)",
            @"iPad8,1":@"iPad Pro (11-inch)",
            @"iPad8,2":@"iPad Pro (11-inch)",
            @"iPad8,3":@"iPad Pro (11-inch)",
            @"iPad8,4":@"iPad Pro (11-inch)",
            @"iPad8,5":@"iPad Pro (12.9-inch) (3rd generation)",
            @"iPad8,6":@"iPad Pro (12.9-inch) (3rd generation)",
            @"iPad8,7":@"iPad Pro (12.9-inch) (3rd generation)",
            @"iPad8,8":@"iPad Pro (12.9-inch) (3rd generation)",
            @"iPad8,9":@"iPad Pro (11-inch) (2nd generation)",
            @"iPad8,10":@"iPad Pro (11-inch) (2nd generation)",
            @"iPad8,11":@"iPad Pro (12.9-inch) (4th generation)",
            @"iPad8,12":@"iPad Pro (12.9-inch) (4th generation)",
            
            ///iPad mini
            @"iPad2,5":@"iPad mini",
            @"iPad2,6":@"iPad mini",
            @"iPad2,7":@"iPad mini",
            @"iPad4,4":@"iPad mini 2",
            @"iPad4,5":@"iPad mini 2",
            @"iPad4,6":@"iPad mini 2",
            @"iPad4,7":@"iPad mini 3",
            @"iPad4,8":@"iPad mini 3",
            @"iPad4,9":@"iPad mini 3",
            @"iPad5,1":@"iPad mini 4",
            @"iPad5,2":@"iPad mini 4",
            @"iPad11,1":@"iPad mini (5th generation)",
            @"iPad11,2":@"iPad mini (5th generation)",
            
            ///iPhone
            @"iPhone1,1":@"iPhone",
            @"iPhone1,2":@"iPhone 3G",
            @"iPhone2,1":@"iPhone 3GS",
            @"iPhone3,1":@"iPhone 4",
            @"iPhone3,2":@"iPhone 4",
            @"iPhone3,3":@"iPhone 4",
            @"iPhone4,1":@"iPhone 4S",
            @"iPhone5,1":@"iPhone 5",
            @"iPhone5,2":@"iPhone 5",
            @"iPhone5,3":@"iPhone 5c",
            @"iPhone5,4":@"iPhone 5c",
            @"iPhone6,1":@"iPhone 5s",
            @"iPhone6,2":@"iPhone 5s",
            @"iPhone7,2":@"iPhone 6",
            @"iPhone7,1":@"iPhone 6 Plus",
            @"iPhone8,1":@"iPhone 6s",
            @"iPhone8,2":@"iPhone 6s Plus",
            @"iPhone8,4":@"iPhone SE (1st generation)",
            @"iPhone9,1":@"iPhone 7",
            @"iPhone9,3":@"iPhone 7",
            @"iPhone9,2":@"iPhone 7 Plus",
            @"iPhone9,4":@"iPhone 7 Plus",
            @"iPhone10,1":@"iPhone 8",
            @"iPhone10,4":@"iPhone 8",
            @"iPhone10,2":@"iPhone 8 Plus",
            @"iPhone10,5":@"iPhone 8 Plus",
            @"iPhone10,3":@"iPhone X",
            @"iPhone10,6":@"iPhone X",
            @"iPhone11,8":@"iPhone XR",
            @"iPhone11,2":@"iPhone XS",
            @"iPhone11,6":@"iPhone XS Max",
            @"iPhone11,4":@"iPhone XS Max",
            @"iPhone12,1":@"iPhone 11",
            @"iPhone12,3":@"iPhone 11 Pro",
            @"iPhone12,5":@"iPhone 11 Pro Max",
            @"iPhone12,8":@"iPhone SE (2nd generation)",
            
            ///iPod touch
            @"iPod1,1":@"iPod touch",
            @"iPod2,1":@"iPod touch (2nd generation)",
            @"iPod3,1":@"iPod touch (3rd generation)",
            @"iPod4,1":@"iPod touch (4th generation)",
            @"iPod5,1":@"iPod touch (5th generation)",
            @"iPod7,1":@"iPod touch (6th generation)",
            @"iPod9,1":@"iPod touch (7th generation)",
            
            ///simulator
            @"i386":@"iPhone Simulator",
            @"x86_64":@"iPhone Simulator",
        };
    });
    return modelMap;
}

NS_INLINE NSDictionary * deviceCPUCoreMap () {
    static NSDictionary * CPUCoreMap = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CPUCoreMap = @{
            ///apple tv
            @"AppleTV1,1":@"Unknown",
            @"AppleTV2,1":@"ARMv7",
            @"AppleTV3,1":@"ARMv7",
            @"AppleTV3,2":@"ARMv7",
            @"AppleTV5,3":@"ARMv8",
            @"AppleTV6,2":@"ARMv8",
            
            ///apple watch
            @"Watch1,1":@"Unknown",
            @"Watch1,2":@"Unknown",
            @"Watch2,6":@"Unknown",
            @"Watch2,7":@"Unknown",
            @"Watch2,3":@"Unknown",
            @"Watch2,4":@"Unknown",
            @"Watch3,1":@"Unknown",
            @"Watch3,2":@"Unknown",
            @"Watch3,3":@"Unknown",
            @"Watch3,4":@"Unknown",
            @"Watch4,1":@"Unknown",
            @"Watch4,2":@"Unknown",
            @"Watch4,3":@"Unknown",
            @"Watch4,4":@"Unknown",
            @"Watch5,1":@"Unknown",
            @"Watch5,2":@"Unknown",
            @"Watch5,3":@"Unknown",
            @"Watch5,4":@"Unknown",
            
            ///home pod
            @"AudioAccessory1,1":@"ARMv8",
            @"AudioAccessory1,2":@"ARMv8",
            
            ///iPad
            @"iPad1,1":@"ARMv7",
            @"iPad2,1":@"ARMv7",
            @"iPad2,2":@"ARMv7",
            @"iPad2,3":@"ARMv7",
            @"iPad2,4":@"ARMv7",
            @"iPad3,1":@"ARMv7",
            @"iPad3,2":@"ARMv7",
            @"iPad3,3":@"ARMv7",
            @"iPad3,4":@"ARMv7",
            @"iPad3,5":@"ARMv7",
            @"iPad3,6":@"ARMv7",
            @"iPad6,11":@"ARMv8",
            @"iPad6,12":@"ARMv8",
            @"iPad7,5":@"ARMv8",
            @"iPad7,6":@"ARMv8",
            @"iPad7,11":@"ARMv8",
            @"iPad7,12":@"ARMv8",
            
            ///iPad Air
            @"iPad4,1":@"ARMv8",
            @"iPad4,2":@"ARMv8",
            @"iPad4,3":@"ARMv8",
            @"iPad5,3":@"ARMv8",
            @"iPad5,4":@"ARMv8",
            @"iPad11,3":@"ARMv8",
            @"iPad11,4":@"ARMv8",
            
            ///iPad Pro
            @"iPad6,7":@"ARMv8-A",
            @"iPad6,8":@"ARMv8-A",
            @"iPad6,3":@"ARMv8-A",
            @"iPad6,4":@"ARMv8-A",
            @"iPad7,1":@"ARMv8-A",
            @"iPad7,2":@"ARMv8-A",
            @"iPad7,3":@"ARMv8-A",
            @"iPad7,4":@"ARMv8-A",
            @"iPad8,1":@"ARMv8.3-A",
            @"iPad8,2":@"ARMv8.3-A",
            @"iPad8,3":@"ARMv8.3-A",
            @"iPad8,4":@"ARMv8.3-A",
            @"iPad8,5":@"ARMv8.3-A",
            @"iPad8,6":@"ARMv8.3-A",
            @"iPad8,7":@"ARMv8.3-A",
            @"iPad8,8":@"ARMv8.3-A",
            @"iPad8,9":@"ARMv8.3-A",
            @"iPad8,10":@"ARMv8.3-A",
            @"iPad8,11":@"ARMv8.3-A",
            @"iPad8,12":@"ARMv8.3-A",
            
            ///iPad mini
            @"iPad2,5":@"ARMv7",
            @"iPad2,6":@"ARMv7",
            @"iPad2,7":@"ARMv7",
            @"iPad4,4":@"ARMv8",
            @"iPad4,5":@"ARMv8",
            @"iPad4,6":@"ARMv8",
            @"iPad4,7":@"ARMv8",
            @"iPad4,8":@"ARMv8",
            @"iPad4,9":@"ARMv8",
            @"iPad5,1":@"ARMv8",
            @"iPad5,2":@"ARMv8",
            @"iPad11,1":@"ARMv8",
            @"iPad11,2":@"ARMv8",
            
            ///iPhone
            @"iPhone1,1":@"ARMv6",
            @"iPhone1,2":@"ARMv6",
            @"iPhone2,1":@"ARMv7",
            @"iPhone3,1":@"ARMv7",
            @"iPhone3,2":@"ARMv7",
            @"iPhone3,3":@"ARMv7",
            @"iPhone4,1":@"ARMv7",
            @"iPhone5,1":@"ARMv7s",
            @"iPhone5,2":@"ARMv7s",
            @"iPhone5,3":@"ARMv7s",
            @"iPhone5,4":@"ARMv7s",
            @"iPhone6,1":@"ARMv8",
            @"iPhone6,2":@"ARMv8",
            @"iPhone7,2":@"ARMv8",
            @"iPhone7,1":@"ARMv8",
            @"iPhone8,1":@"ARMv8",
            @"iPhone8,2":@"ARMv8",
            @"iPhone8,4":@"ARMv8",
            @"iPhone9,1":@"ARMv8",
            @"iPhone9,3":@"ARMv8",
            @"iPhone9,2":@"ARMv8",
            @"iPhone9,4":@"ARMv8",
            @"iPhone10,1":@"ARMv8",
            @"iPhone10,4":@"ARMv8",
            @"iPhone10,2":@"ARMv8",
            @"iPhone10,5":@"ARMv8",
            @"iPhone10,3":@"ARMv8",
            @"iPhone10,6":@"ARMv8",
            @"iPhone11,8":@"ARMv8.3",
            @"iPhone11,2":@"ARMv8.3",
            @"iPhone11,6":@"ARMv8.3",
            @"iPhone11,4":@"ARMv8.3",
            @"iPhone12,1":@"ARMv8.4-A",
            @"iPhone12,3":@"ARMv8.4-A",
            @"iPhone12,5":@"ARMv8.4-A",
            @"iPhone12,8":@"ARMv8.4-A",
            
            ///iPod touch
            @"iPod1,1":@"Unknown",
            @"iPod2,1":@"Unknown",
            @"iPod3,1":@"Unknown",
            @"iPod4,1":@"Unknown",
            @"iPod5,1":@"Unknown",
            @"iPod7,1":@"Unknown",
            @"iPod9,1":@"Unknown",
            
            ///simulator
            @"i386":@"Unknown",
            @"x86_64":@"Unknown",
        };
    });
    return CPUCoreMap;
}

@end
