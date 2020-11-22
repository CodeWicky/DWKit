//
//  DemoBaseActionViewController.h
//  DWKitDemo
//
//  Created by Wicky on 2019/9/13.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DemoBaseViewController.h"

@interface DemoActionModel : NSObject

@property (nonatomic ,copy) NSString * title;

@property (nonatomic ,strong) id target;

@property (nonatomic ,assign) SEL selector;

@property (nonatomic ,strong) id object;

@end

@interface DemoBaseActionViewController : DemoBaseViewController

@property (nonatomic ,strong) NSArray <DemoActionModel *>* actions;

@property (nonatomic ,strong ,readonly) UITableView * mainTab;

-(void)configActions;

@end

UIKIT_EXTERN DemoActionModel * actionWithTarget(id target,SEL selector,id object,NSString * title);
UIKIT_EXTERN DemoActionModel * actionWithObject(SEL selector,id object,NSString * title);
UIKIT_EXTERN DemoActionModel * actionWithTitle(SEL selector,NSString * title);
UIKIT_EXTERN DemoActionModel * actionWithSelector(SEL selector);
