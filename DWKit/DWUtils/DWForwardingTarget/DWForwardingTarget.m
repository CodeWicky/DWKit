//
//  DWForwardingTarget.m
//  DWKitDemo
//
//  Created by Wicky on 2020/12/15.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWForwardingTarget.h"
#import <objc/runtime.h>

@interface DWForwardingTarget ()

@property (nonatomic ,assign) BOOL debugAssertEnabled;

@end

@implementation DWForwardingTarget

#pragma mark --- interface method ---
+(instancetype)forwardingTargetForSelector:(SEL)selector {
    if (selector == NULL) {
        return nil;
    }
    DWForwardingTarget * t = [self target];
    [t addFunc:selector];
    return t;
}

+(void)setDebugAssertEnable:(BOOL)enable {
#if DEBUG
    DWForwardingTarget * target = [self target];
    target.debugAssertEnabled = enable;
#endif
}

#pragma mark --- singleton ---
+(instancetype)target {
    static DWForwardingTarget * t = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        t = [DWForwardingTarget new];
#if DEBUG
        t.debugAssertEnabled = YES;
#endif
    });
    return t;
}

#pragma mark --- tool func ---
int smartFunction(id target, SEL cmd, ...) {
    return 0;
}

static BOOL _dw_addMethod(Class clazz, SEL sel) {
    NSString *selName = NSStringFromSelector(sel);
    NSMutableString *tmpString = [[NSMutableString alloc] initWithFormat:@"%@", selName];
    int count = (int)[tmpString replaceOccurrencesOfString:@":" withString:@"_" options:NSCaseInsensitiveSearch range:NSMakeRange(0, selName.length)];
    NSMutableString *val = [[NSMutableString alloc] initWithString:@"i@:"];
    for (int i = 0; i < count; i++) {
        [val appendString:@"@"];
    }
    const char *funcTypeEncoding = [val UTF8String];
    return class_addMethod(clazz, sel, (IMP)smartFunction, funcTypeEncoding);
}

-(BOOL)addFunc:(SEL)sel {
    if (self.debugAssertEnabled) {
        NSAssert(NO, @"Unrecognized selector crashed! Selector is %@",NSStringFromSelector(sel));
        return NO;
    }
    return _dw_addMethod([self class], sel);
}

+(BOOL)addClassFunc:(SEL)sel {
    Class metaClass = objc_getMetaClass(class_getName([self class]));
    return _dw_addMethod(metaClass, sel);
}

@end
