//
//  NSThread+DWThreadUtils.m
//  DWKitDemo
//
//  Created by Wicky on 2020/3/30.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "NSThread+DWThreadUtils.h"

@implementation NSThread (DWThreadUtils)

+(BOOL)isMainQueue {
    static void * kDWThreadMainQueueKey = "kDWThreadMainQueueKey";
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_queue_t mainQ = dispatch_get_main_queue();
        dispatch_queue_set_specific(mainQ, kDWThreadMainQueueKey, &kDWThreadMainQueueKey, NULL);
    });
    if (dispatch_get_specific(kDWThreadMainQueueKey)) {
        return YES;
    }
    return NO;
}

-(BOOL)isMainQueue {
    if ([self isMainThread]) {
        return [NSThread isMainQueue];
    }
    return NO;
}

+(BOOL)isInQueue:(dispatch_queue_t)queue {
    if (!queue) {
        return NO;
    }
    if ([queue isEqual:dispatch_get_main_queue()]) {
        return [self isMainQueue];
    } else {
        static void * kDWThreadTargetQueueKey = "kDWThreadTargetQueueKey";
        if (!dispatch_queue_get_specific(queue, kDWThreadTargetQueueKey)) {
            void * posString = (void *)[[NSString stringWithFormat:@"%p",queue] UTF8String];
            dispatch_queue_set_specific(queue, kDWThreadTargetQueueKey, &posString, NULL);
        }
        return (dispatch_get_specific(kDWThreadTargetQueueKey) == dispatch_queue_get_specific(queue, kDWThreadTargetQueueKey));
    }
}

+(void)performActionOnMainQueue:(dispatch_block_t)action {
    if (!action) {
        return;
    }
    if ([self isMainQueue] || [self isMainThread]) {
        action();
    } else {
        dispatch_sync(dispatch_get_main_queue(), action);
    }
}

+(void)performActionOnQueue:(dispatch_queue_t)targetQueue action:(dispatch_block_t)action {
    if (!targetQueue || !action) {
        return;
    }
    if ([targetQueue isEqual:dispatch_get_main_queue()]) {
        [self performActionOnMainQueue:action];
    } else {
        if ([self isInQueue:targetQueue]) {
            action();
        } else {
            dispatch_sync(targetQueue, action);
        }
    }
}

@end
