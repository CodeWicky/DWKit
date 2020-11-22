//
//  DWObjectUtilsVC.m
//  DWKitDemo
//
//  Created by Wicky on 2020/4/30.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWObjectUtilsVC.h"
#import <DWKit/NSObject+DWObjectUtils.h>
#import "A.h"

@interface DWObjectUtilsVC ()

@end

@implementation DWObjectUtilsVC

-(void)configActions {
    self.actions = @[
                     actionWithTitle(@selector(fetchAllProp), @"获取类A的全部属性"),
                     actionWithTitle(@selector(fetchKeysProp), @"获取类A的a属性"),
                     actionWithTitle(@selector(getValueWithProp),@"通过prop获取正确类型的值"),
                     actionWithTitle(@selector(setValueWithProp), @"通过prop设置正确的值的类型"),
                     actionWithTitle(@selector(objectToJson), @"对象Json化"),
                     actionWithTitle(@selector(modelToDictionary), @"将模型转换成字典"),
                     actionWithTitle(@selector(modelToDictionaryWithKeys), @"将模型按指定键值转换成字典"),
                     actionWithTitle(@selector(dictionaryToModel), @"将字典转换为模型"),
                     actionWithTitle(@selector(dictionaryToModelWithKeys), @"将字典按指定键值转换为模型"),
                     ];
}

-(void)fetchAllProp {
    NSLog(@"类A的全部属性：%@",[A dw_allPropertyInfos]);
}

-(void)fetchKeysProp {
    NSLog(@"类A的a属性：%@",[A dw_propertyInfosForKeys:@[@"a"]]);
}

-(void)getValueWithProp {
    A * model = [A new];
    model.string = (NSString *)@100;
    DWPrefix_YYClassPropertyInfo * prop = [A dw_propertyInfosForKeys:@[@"string"]][@"string"];
    NSString * string = [model dw_valueForPropertyInfo:prop];
    NSLog(@"%@",string);
}

-(void)setValueWithProp {
    A * model = [A new];
    DWPrefix_YYClassPropertyInfo * prop = [A dw_propertyInfosForKeys:@[@"string"]][@"string"];
    [model dw_setValue:@(100) forPropertyInfo:prop];
    NSLog(@"%@",model.string);
}

-(void)objectToJson {
    NSDate * date = [NSDate date];
    NSLog(@"%@",[date dw_jsonObject]);
}

-(void)modelToDictionary {
    A * model = [A new];
    model.string = @"hello world";
    model.a = 3.14;
    
    B * b1 = [B new];
    b1.intNum = 128;
    b1.str = @"b1";
    
    B * b2 = [B new];
    b2.intNum = 256;
    b2.str = @"b2";
    
    model.array = @[b1,b2];
    
    NSLog(@"%@", [model dw_transformToDictionary]);
}

-(void)modelToDictionaryWithKeys {
    A * model = [A new];
    model.string = @"hello world";
    model.a = 3.14;
    
    B * b1 = [B new];
    b1.intNum = 128;
    b1.str = @"b1";
    
    B * b2 = [B new];
    b2.intNum = 256;
    b2.str = @"b2";
    
    model.array = @[b1,b2];
    
    NSLog(@"%@", [model dw_transformToDictionaryForKeys:@[@"string",@"array"]]);
}

-(void)dictionaryToModel {
    NSDictionary * dic = @{@"string":@"hello world",@"a":@(3.14),@"array":@[@{@"intNum":@"128",@"str":@"b1"},@{@"intNum":@(256),@"str":@"b2"}]};
    A * model = [A dw_modelFromDictionary:dic];
    NSLog(@"%@",model);
}

-(void)dictionaryToModelWithKeys {
    NSDictionary * dic = @{@"string":@"hello world",@"a":@(3.14),@"array":@[@{@"intNum":@"128",@"str":@"b1"},@{@"intNum":@(256),@"str":@"b2"}]};
    A * model = [A dw_modelFromDictionary:dic withKeys:@[@"array",@"string"]];
    NSLog(@"%@",model);
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
