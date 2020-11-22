//
//  NSThread+DWThreadUtils.h
//  DWKitDemo
//
//  Created by Wicky on 2020/3/30.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSThread (DWThreadUtils)

/**
 获取当前队列是否为主队列
 
 MainThread != MainQueue。
 前提是主线程与主队列并不存在绑定关系。
 队列只是一种数据结构，一种由GCD包装并管理的数据结构。
 我们将任务Task提交给GCD指定队列Queue时，GCD内部根据队列类型选择合适的线程来执行Task。
 GCD默认为我们生成一个主队列。
 线程与runLoop具有一一对应关系。
 一个线程中，可能执行多个队列的任务。
 主线程中，也可以执行其他队列的任务。
 
 详细内容可参见如下博客：
 http://blog.benjamin-encz.de/post/main-queue-vs-main-thread/
 */
@property (nonatomic ,assign ,readonly ,class) BOOL isMainQueue;

@property (nonatomic ,assign ,readonly) BOOL isMainQueue;

+(BOOL)isMainQueue;

-(BOOL)isMainQueue;

+(BOOL)isInQueue:(dispatch_queue_t)queue;

+(void)performActionOnMainQueue:(dispatch_block_t)action;

+(void)performActionOnQueue:(dispatch_queue_t)targetQueue action:(dispatch_block_t)action;

@end

NS_ASSUME_NONNULL_END
