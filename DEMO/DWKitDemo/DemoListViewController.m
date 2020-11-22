//
//  DemoViewController.m
//  DWKitDemo
//
//  Created by Wicky on 2019/9/7.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DemoListViewController.h"

@interface DemoListViewController ()<UITableViewDelegate>

@property (nonatomic ,strong) NSArray * config;

@end

@implementation DemoListViewController

#pragma mark --- interface method ---

-(instancetype)initWithConfig:(NSArray *)config {
    if (self = [super init]) {
        _config = config;
    }
    return self;
}

#pragma mark --- life cycle ---
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

#pragma mark --- tableView delegate ---
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    cell.textLabel.text = self.config[indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString * vcStr = [self.config[indexPath.row] stringByAppendingString:@"VC"];
    Class clazz = NSClassFromString(vcStr);
    [self.navigationController pushViewController:[clazz new] animated:YES];
}

@end
