//
//  DWGradientView.h
//  AccountBook
//
//  Created by Wicky on 2018/10/16.
//  Copyright © 2018年 Wicky. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*
 v0.0.0.21
 增加gradientView 快捷方法
 */

/*
 Axis Location Tip:
 
 (1)    (2)
 
 
 (3)    (4)
 */
typedef NS_ENUM(NSUInteger, DWGradientViewAxis) {
    DWGradientViewAxisHorizontal,//1 -> 2
    DWGradientViewAxisVertical,//1 -> 3
    DWGradientViewAxisDiagonalLeft,//1 -> 4
    DWGradientViewAxisDiagonalRight,//3 -> 2
};

@interface DWGradientView : UIView

///CGColors
@property (nonatomic ,strong ,nullable) NSArray * colors;

@property (nonatomic ,strong) NSArray <NSNumber *>* locations;

@property (nonatomic ,assign) CGPoint startPoint;

@property (nonatomic ,assign) CGPoint endPoint;

+(instancetype)gradientViewWithStartColor:(UIColor *)startColor endColor:(UIColor *)endColor axis:(DWGradientViewAxis)axis;

@end

NS_ASSUME_NONNULL_END
