//
//  DWLimitArray.m
//  DWAlbumGridController
//
//  Created by Wicky on 2020/6/1.
//

#import "DWLimitArray.h"

@interface DWLimitArrayNode : NSObject

@property (nonatomic ,strong) id value;

@property (nonatomic ,weak) DWLimitArrayNode * nextNode;

+(instancetype)nodeWithValue:(id)value;

-(void)appendNode:(DWLimitArrayNode *)node;

-(void)deleteNextNode;

@end

@implementation DWLimitArrayNode

+(instancetype)nodeWithValue:(id)value {
    if (!value) {
        return nil;
    }
    DWLimitArrayNode * node = [DWLimitArrayNode new];
    node.value = value;
    return node;
}

-(void)appendNode:(DWLimitArrayNode *)node {
    if (!node) {
        return;
    }
    self.nextNode = node;
}

-(void)deleteNextNode {
    self.nextNode = nil;
}

@end

@interface DWLimitArray()

@property (nonatomic ,strong) DWLimitArrayNode * headNode;

@property (nonatomic ,strong) DWLimitArrayNode * tailNode;

@property (nonatomic ,strong) NSMutableSet <DWLimitArrayNode *>* nodes;

@property (nonatomic ,strong) NSArray * _allObjects;

@property (nonatomic ,strong) dispatch_queue_t serial_Q;

@end

@implementation DWLimitArray

#pragma mark --- interface method ---
+(instancetype)arrayWithCapacity:(NSUInteger)capacity {
    DWLimitArray * array = [[DWLimitArray alloc]  initWithCapacity:capacity];
    return array;
}

-(instancetype)initWithCapacity:(NSUInteger)capacity {
    if (self = [super init]) {
        _capacity = capacity;
    }
    return self;
}

-(id)addObject:(id)value {
    if (!value) {
        return nil;
    }
    
   __block id ret = nil;
    dispatch_sync(self.serial_Q, ^{
        ///可直接添加新node
        if (_capacity == 0 || _nodes.count < _capacity) {
            [self _addObject:value];
        } else {
            ret = [self _reuseFirstNodeWithObject:value];
        }
        self._allObjects = nil;
    });
    
    return ret;
}

-(NSArray *)allObjects {
    if (self._allObjects) {
        return self._allObjects;
    }
    
    if (!self.headNode) {
        return @[];
    }
    
    dispatch_sync(self.serial_Q, ^{
        NSMutableArray * tmp = [NSMutableArray arrayWithCapacity:self.nodes.count];
        DWLimitArrayNode * node = self.headNode;
        while (node && node.value) {
            [tmp addObject:node.value];
            node = node.nextNode;
        }
        
        self._allObjects = [tmp copy];
    });
    
    return self._allObjects;
}

#pragma mark --- tool method ---
-(void)_addObject:(id)value {
    DWLimitArrayNode * node = [DWLimitArrayNode nodeWithValue:value];
    if (!value) {
        return;
    }
    if (!self.tailNode) {
        self.headNode = node;
        self.tailNode = node;
    } else {
        [self.tailNode appendNode:node];
        self.tailNode = node;
    }
    [self.nodes addObject:node];
}

-(id)_reuseFirstNodeWithObject:(id)value {
    if (!value) {
        return nil;
    }
    
    ///只有一个node，直接替换value即可
    if (self.capacity == 1) {
        id ret = self.headNode.value;
        self.headNode.value = value;
        return ret;
    }
    
    
    DWLimitArrayNode * headNode = self.headNode;
    DWLimitArrayNode * nextNode = headNode.nextNode;
    id ret = headNode.value;
    
    ///处理头结点
    ///1.移除头部节点的下一个节点
    ///2.复用头部节点，改新value
    ///3.将原头部节点追加至当前的尾部节点之后
    ///4.更改当前尾部节点为原头部节点
    [headNode deleteNextNode];
    headNode.value = value;
    [self.tailNode appendNode:headNode];
    self.tailNode = headNode;
    
    ///处理次节点
    ///1.将原次节点更改为新头结点
    self.headNode = nextNode;
    return ret;
}

#pragma mark --- override ---
-(NSString *)description {
    return [[self allObjects] description];
}

-(NSString *)debugDescription {
    return [[self allObjects] debugDescription];
}

#pragma mark --- setter/getter ---
-(NSMutableSet<DWLimitArrayNode *> *)nodes {
    if (!_nodes) {
        _nodes = [NSMutableSet setWithCapacity:_capacity];
    }
    return _nodes;
}

-(NSUInteger)count {
    return _nodes.count;
}

-(dispatch_queue_t)serial_Q {
    if (!_serial_Q) {
        _serial_Q = dispatch_queue_create("com.DWLimitArray.serialQueue", NULL);
    }
    return _serial_Q;
}

@end
