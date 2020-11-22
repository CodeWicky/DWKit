//
//  A.h
//  DWKitDemo
//
//  Created by Wicky on 2020/4/30.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "B.h"
NS_ASSUME_NONNULL_BEGIN

@interface A : NSObject

@property (nonatomic ,assign) float a;

@property (nonatomic ,strong) NSArray <B *>* array;

@property (nonatomic ,strong) NSString * string;

@end

NS_ASSUME_NONNULL_END
