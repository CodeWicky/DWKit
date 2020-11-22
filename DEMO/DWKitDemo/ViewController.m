//
//  ViewController.m
//  DWKitDemo
//
//  Created by Wicky on 2019/9/6.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "ViewController.h"
#import "DemoListViewController.h"

#import <DWFileManager.h>

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic ,strong) NSDictionary * config;

@property (nonatomic ,strong) UITableView * mainTab;

@end

@implementation ViewController

#pragma mark --- life cycle ---
- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.mainTab];
}

#pragma mark --- tableView delegate ---
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.config.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.text = self.config.allKeys[indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray * demoConfig  = self.config.allValues[indexPath.row];
    DemoListViewController * demo = [[DemoListViewController alloc] initWithConfig:demoConfig];
    demo.title = self.config.allKeys[indexPath.row];
    [self.navigationController pushViewController:demo animated:YES];
}

#pragma mark --- setter/getter ---
-(NSDictionary *)config {
    if (!_config) {
        NSString * path = [[NSBundle mainBundle] pathForResource:@"DWDemoConfig" ofType:@"plist"];
        _config = [NSDictionary dictionaryWithContentsOfFile:path];
    }
    return _config;
}

-(UITableView *)mainTab {
    if (!_mainTab) {
        _mainTab = [[UITableView alloc] initWithFrame:self.view.bounds style:(UITableViewStylePlain)];
        _mainTab.delegate = self;
        _mainTab.dataSource = self;
        [_mainTab registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    }
    return _mainTab;
}

@end
