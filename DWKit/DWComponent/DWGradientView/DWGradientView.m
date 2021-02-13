//
//  DWGradientView.m
//  AccountBook
//
//  Created by Wicky on 2018/10/16.
//  Copyright © 2018年 Wicky. All rights reserved.
//

#import "DWGradientView.h"

@interface DWGradientView ()

@property (nonatomic ,strong ,readonly) CAGradientLayer * layer;

@end

@implementation DWGradientView
@dynamic layer;

#pragma mark --- interface method ---
+(instancetype)gradientViewWithStartColor:(UIColor *)startColor endColor:(UIColor *)endColor axis:(DWGradientViewAxis)axis {
    DWGradientView * gradient = [DWGradientView new];
    gradient.colors = @[(id)(startColor?startColor.CGColor:[UIColor blackColor].CGColor),(id)(endColor?endColor.CGColor:[UIColor blackColor].CGColor)];
    CGPoint startPoint = CGPointZero;
    CGPoint endPoint = CGPointZero;
    switch (axis) {
        case DWGradientViewAxisVertical:
        {
            startPoint = CGPointMake(0.5, 0);
            endPoint = CGPointMake(0.5, 1);
        }
            break;
        case DWGradientViewAxisDiagonalLeft:
        {
            startPoint = CGPointMake(0, 0);
            endPoint = CGPointMake(1, 1);
        }
            break;
        case DWGradientViewAxisDiagonalRight:
        {
            startPoint = CGPointMake(0, 1);
            endPoint = CGPointMake(1, 0);
        }
            break;
        default:
        {
            startPoint = CGPointMake(0, 0.5);
            endPoint = CGPointMake(1, 0.5);
        }
            break;
    }
    gradient.startPoint = startPoint;
    gradient.endPoint = endPoint;
    return gradient;
}

#pragma mark --- override ---
+(Class)layerClass {
    return [CAGradientLayer class];
}

#pragma mark --- setter/getter ---
-(void)setColors:(NSArray*)colors {
    self.layer.colors = colors;
}

-(NSArray *)colors {
    return self.layer.colors;
}

-(void)setLocations:(NSArray<NSNumber *> *)locations {
    self.layer.locations = locations;
}

-(NSArray<NSNumber *> *)locations {
    return self.layer.locations;
}

-(void)setStartPoint:(CGPoint)startPoint {
    self.layer.startPoint = startPoint;
}

-(CGPoint)startPoint {
    return self.layer.startPoint;
}

-(void)setEndPoint:(CGPoint)endPoint {
    self.layer.endPoint = endPoint;
}

-(CGPoint)endPoint {
    return self.layer.endPoint;
}

@end
