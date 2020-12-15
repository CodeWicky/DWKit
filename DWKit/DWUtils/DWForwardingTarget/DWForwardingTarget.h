//
//  DWForwardingTarget.h
//  DWKitDemo
//
//  Created by Wicky on 2020/12/15.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 DWForwardingTarget
 
 消息转发工具类
 对于任意实例，避免Unrecoginzed Selector Crash。
 仅需根据需要，在想要避免崩溃的类中实现 -forwardingTargetForSelector: 即可。
 
 e.g.:
 -(id)forwardingTargetForSelector:(SEL)aSelector {
     if (aSelector == NSSelectorFromString(@"gotoAnCrash")) {
         return [DWForwardingTarget forwardingTargetForSelector:aSelector];
     }
     return [super forwardingTargetForSelector:aSelector];
 }
 */


@interface DWForwardingTarget : NSObject

///对于任意选择子，返回一个可以接受的target，避免Unrecoginzed Selector Crash。当前仅支持实例方法的兼容。
+(instancetype)forwardingTargetForSelector:(SEL)selector;

///设置Debug模式下是否转发消息，默认不转发消息，暴露问题。仅在Debug模式下有效。
+(void)setDebugAssertEnable:(BOOL)enable;

@end
