//
//  DWInsetLabel.h
//  DWKitDemo
//
//  Created by Wicky on 2020/1/2.
//  Copyright © 2020 Wicky. All rights reserved.
//

/*
 v0.0.0.21
 修复多次设置marginInsets后导致自动布局失败问题
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DWLabel : UILabel

@property (nonatomic ,assign) UIEdgeInsets marginInsets;

@property (nonatomic ,assign) UIEdgeInsets touchPaddingInsets;

@property (nonatomic ,assign) CGSize minSize;

@property (nonatomic ,assign) CGSize maxSize;

///动作防抖时间，默认值0.5s，若设置为非正数则认为无需防抖
@property (nonatomic ,assign) NSTimeInterval actionTimeInterval;

-(void)addAction:(void(^)(DWLabel * label))action;

-(void)removeAction;

@end

NS_ASSUME_NONNULL_END
