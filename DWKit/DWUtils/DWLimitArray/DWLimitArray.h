//
//  DWLimitArray.h
//  DWAlbumGridController
//
//  Created by Wicky on 2020/6/1.
//

#import <Foundation/Foundation.h>

/**
 DWLimitArray
 
 定长数组，适用于收集指定数据源的最新指定条数的数据。内部避免频繁移除数组顶部元素的操作。
 可指定最大长度的数组，初始化时可指定数组最大长度。当数组长度小于最大长度时，可正常将元素添加至数组。当数组长度大于或等于最大长度时，添加元素时将移除当前数组的第一个元素，并添加元素至数组尾部。
 */
NS_ASSUME_NONNULL_BEGIN

@interface DWLimitArray : NSObject

@property (nonatomic ,assign ,readonly) NSUInteger capacity;

@property (nonatomic ,assign ,readonly) NSUInteger count;

+(instancetype)arrayWithCapacity:(NSUInteger)capacity;

-(instancetype)initWithCapacity:(NSUInteger)capacity;

-(id)addObject:(id)value;

-(NSArray *)allObjects;

@end

NS_ASSUME_NONNULL_END
