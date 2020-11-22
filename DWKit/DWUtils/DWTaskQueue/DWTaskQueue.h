//
//  DWTaskQueue.h
//  DWAlbumGridController
//
//  Created by Wicky on 2020/6/1.
//

#import <Foundation/Foundation.h>
/**
 DWTaskQueue
 
 可控制任务并行数的队列。
 调用 -enqueue 可以入列一个任务，并传入用户参数。
 调用 -dequeue 可以标记队列头部的任务完成，并出列该任务。
 调用 -reset 可以清空当前队列中的所有任务。
 调用 -configTaskQueueEmptyHandler: 可设置队列为空时的回调。
 当队列为空时，入列的任务会立刻回调。
 当队列中的任务数小于等于最大并行数时，入列的任务均会立刻回调。
 当队列中的任务数大于最大并行数时，后续入列的任务会等待先入列的任务完成，先入列的任务完成后自动按入列顺序回调下一个任务。
 当队列中的任务全部出列或者队列被清空时，会触发队列为空的回调，回调中的finish参数为YES时表示任务全部出列，为NO时表示队列被清空。
 */

NS_ASSUME_NONNULL_BEGIN
typedef void(^DWTaskQueueHandler)(_Nullable id userInfo);
typedef void(^DWTaskQueueEmptyHandler)(BOOL finish);

@interface DWTaskQueue : NSObject

+(instancetype)taskQueueWithConcurrentCount:(NSInteger)concurrentCount handler:(nullable DWTaskQueueHandler)handler;

-(void)enqueue:(nullable id)userInfo;

-(void)dequeue;

-(void)reset;

-(void)configTaskQueueEmptyHandler:(nullable DWTaskQueueEmptyHandler)handler;

@end
NS_ASSUME_NONNULL_END
