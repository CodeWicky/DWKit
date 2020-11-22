//
//  DemoBaseActionViewController.m
//  DWKitDemo
//
//  Created by Wicky on 2019/9/13.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DemoBaseActionViewController.h"

@interface DemoBaseActionViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic ,strong) UITableView * mainTab;

@end

@implementation DemoBaseActionViewController

#pragma mark --- life cycle ---
- (void)viewDidLoad {
    [super viewDidLoad];
    [self configActions];
    [self setupUI];
}

#pragma mark --- interface method ---
-(void)configActions {
    
}

DemoActionModel * actionWithTarget(id target,SEL selector,id object,NSString * title) {
    DemoActionModel * model = [DemoActionModel new];
    model.target = target;
    model.selector = selector;
    model.object = object;
    if (!title) {
        title = NSStringFromSelector(selector);
    }
    model.title = title;
    return model;
}

DemoActionModel * actionWithObject(SEL selector,id object,NSString * title) {
    return actionWithTarget(nil, selector, object, title);
}

DemoActionModel * actionWithTitle(SEL selector,NSString * title) {
    return actionWithTarget(nil, selector, nil, title);
}

DemoActionModel * actionWithSelector(SEL selector) {
    return actionWithTarget(nil, selector, nil, nil);
}

#pragma mark --- tool method ---
-(void)setupUI {
    [self.view addSubview:self.mainTab];
}

#pragma mark --- tableview delegate ---
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.actions.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    DemoActionModel * actionModel = self.actions[indexPath.row];
    cell.textLabel.text = actionModel.title;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DemoActionModel * model = self.actions[indexPath.row];
    id target = model.target;
    if (!target) {
        target = self;
    }
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([NSStringFromSelector(model.selector) hasSuffix:@":"]) {
        [target performSelector:model.selector withObject:model.object];
    } else {
        [target performSelector:model.selector];
    }
#pragma clang diagnostic pop
}

#pragma mark --- setter/getter ---
-(UITableView *)mainTab {
    if (!_mainTab) {
        _mainTab = [[UITableView alloc] initWithFrame:self.view.bounds style:(UITableViewStylePlain)];
        _mainTab.delegate = self;
        _mainTab.dataSource = self;
        [_mainTab registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
        _mainTab.tableFooterView = [UIView new];
    }
    return _mainTab;
}

@end

@implementation DemoActionModel

@end
