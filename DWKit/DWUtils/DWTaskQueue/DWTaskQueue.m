//
//  DWTaskQueue.m
//  DWAlbumGridController
//
//  Created by Wicky on 2020/6/1.
//

#import "DWTaskQueue.h"

@interface DWTaskQueueNode : NSObject

@property (nonatomic ,strong) id value;

@property (nonatomic ,weak) DWTaskQueueNode * previousNode;

@property (nonatomic ,strong) DWTaskQueueNode * nextNode;

+(instancetype)nodeWithValue:(id)value;

-(void)appendNode:(DWTaskQueueNode *)node;

@end

@implementation DWTaskQueueNode

+(instancetype)nodeWithValue:(id)value {
    DWTaskQueueNode * node = [DWTaskQueueNode new];
    node.value = value;
    return node;
}

-(void)appendNode:(DWTaskQueueNode *)node {
    if (!node) {
        return;
    }
    self.nextNode = node;
    node.previousNode = self;
}

-(void)deleteNextNode {
    if (self.nextNode) {
        self.nextNode.previousNode = nil;
        self.nextNode = nil;
    }
}

@end

@interface DWTaskQueue ()

@property (nonatomic ,assign) NSInteger concurrentCount;

@property (nonatomic ,assign) NSInteger reuseCount;

@property (nonatomic ,copy) DWTaskQueueHandler handler;

@property (nonatomic ,copy) DWTaskQueueEmptyHandler emptyHandler;

@property (nonatomic ,strong) dispatch_queue_t serial_Q;

@property (nonatomic ,strong) DWTaskQueueNode * headNode;

@property (nonatomic ,weak) DWTaskQueueNode * tailNode;

@end

@implementation DWTaskQueue

+(instancetype)taskQueueWithConcurrentCount:(NSInteger)concurrentCount handler:(DWTaskQueueHandler)handler {
    if (!handler || concurrentCount == 0) {
        return nil;
    }
    DWTaskQueue * queue = [DWTaskQueue new];
    queue.concurrentCount = concurrentCount;
    queue.reuseCount = concurrentCount;
    queue.handler = handler;
    return queue;
}

-(void)enqueue:(id)userInfo {
    dispatch_async(self.serial_Q, ^{
        if (self.reuseCount > 0) {
            self.reuseCount --;
            if (self.handler) {
                self.handler(userInfo);
            }
        } else {
            [self appendValue:userInfo];
        }
    });
}

-(void)dequeue {
    dispatch_async(self.serial_Q, ^{
        if (self.reuseCount >= self.concurrentCount) {
            return ;
        }
        DWTaskQueueNode * node = [self removeFirstValue];
        if (node) {
            if (self.handler) {
                self.handler(node.value);
            }
        } else {
            self.reuseCount ++;
            if (self.reuseCount == self.concurrentCount) {
                if (self.emptyHandler) {
                    self.emptyHandler(YES);
                }
            }
        }
    });
}

-(void)reset {
    dispatch_sync(self.serial_Q, ^{
        [self removeAllValue];
        self.reuseCount = self.concurrentCount;
        if (self.emptyHandler) {
            self.emptyHandler(NO);
        }
    });
}

-(void)configTaskQueueEmptyHandler:(DWTaskQueueEmptyHandler)handler {
    dispatch_sync(self.serial_Q, ^{
        self.emptyHandler = handler;
    });
}

#pragma mark --- tool method ---
-(void)appendValue:(id)value {
    DWTaskQueueNode * node = [DWTaskQueueNode nodeWithValue:value];
    if (self.tailNode) {
        [self.tailNode appendNode:node];
        self.tailNode = node;
    } else {
        self.headNode = node;
        self.tailNode = node;
    }
}

-(DWTaskQueueNode *)removeFirstValue {
    if (!self.headNode) {
        return nil;
    }
    DWTaskQueueNode * node = self.headNode;
    DWTaskQueueNode * next = node.nextNode;
    if (!next) {
        self.headNode = nil;
        self.tailNode = nil;
    } else {
        [node deleteNextNode];
        self.headNode = next;
    }
    return node;
}

-(void)removeAllValue {
    self.headNode = nil;
    self.tailNode = nil;
}

#pragma mark --- setter/getter ---
-(dispatch_queue_t)serial_Q {
    if (!_serial_Q) {
        _serial_Q = dispatch_queue_create("com.DWTaskQueue.serialQueue", NULL);
    }
    return _serial_Q;
}

@end
