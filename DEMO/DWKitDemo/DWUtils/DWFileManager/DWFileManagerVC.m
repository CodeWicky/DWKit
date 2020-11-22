//
//  DWFileManagerVC.m
//  DWKitDemo
//
//  Created by Wicky on 2019/9/13.
//  Copyright © 2019 Wicky. All rights reserved.
//

#import "DWFileManagerVC.h"
#import <DWKit/DWFileManager.h>

@interface DWFileManagerVC ()

@property (nonatomic ,copy) NSString * testFolderPath;

@property (nonatomic ,copy) NSString * testFilePath;

@end

@implementation DWFileManagerVC

#pragma mark --- life cycle ---
-(void)viewDidLoad {
    self.testFolderPath = [[DWFileManager tmpDir] stringByAppendingPathComponent:@"testFolder"];
    self.testFilePath = [self.testFolderPath stringByAppendingPathComponent:@"testFile.txt"];
    [super viewDidLoad];
}

#pragma mark --- override ---
-(void)configActions {
    self.actions = @[
                     actionWithSelector(@selector(homeDir)),
                     actionWithSelector(@selector(documentsDir)),
                     actionWithSelector(@selector(libraryDir)),
                     actionWithSelector(@selector(preferencesDir)),
                     actionWithSelector(@selector(cachesDir)),
                     actionWithSelector(@selector(tmpDir)),
                     actionWithObject(@selector(attributesOfItemAtPath:), self.testFilePath, @"打印测试文件属性"),
                     actionWithObject(@selector(isDirectoryAtPath:), self.testFolderPath, @"测试文件夹是否存在"),
                     actionWithObject(@selector(isFileAtPath:), self.testFilePath, @"测试文件是否存在"),
                     actionWithObject(@selector(listFilesInDirectoryAtPath:), [DWFileManager tmpDir], @"列出当前tmp文件夹下所有文件"),
                     actionWithObject(@selector(createDirectoryAtPath:), self.testFolderPath, nil),
                     actionWithObject(@selector(isDirectoryIsEmptyAtPath:), self.testFolderPath, @"测试文件夹是否为空"),
                     actionWithObject(@selector(removeItemAtPath:), self.testFolderPath, @"删除测试文件夹"),
                     actionWithObject(@selector(clearDirectoryAtPath:), self.testFolderPath, @"清空测试文件夹"),
                     actionWithSelector(@selector(clearCachesDir)),
                     actionWithObject(@selector(createFileAtPath:), self.testFilePath, @"创建测试文件"),
                     actionWithObject(@selector(writeFileAtPath:), self.testFilePath, @"写入内容至测试文件"),
                     actionWithObject(@selector(copyItemAtPath:), self.testFilePath, nil),
                     actionWithObject(@selector(moveItemAtPath:), self.testFilePath, nil),
                     ];
}

-(void)homeDir {
    NSLog(@"%@",[DWFileManager homeDir]);
}

-(void)documentsDir {
    NSLog(@"%@",[DWFileManager documentsDir]);
}

-(void)libraryDir {
    NSLog(@"%@",[DWFileManager libraryDir]);
}

-(void)preferencesDir {
    NSLog(@"%@",[DWFileManager preferencesDir]);
}

-(void)cachesDir {
    NSLog(@"%@",[DWFileManager cachesDir]);
}

-(void)tmpDir {
    NSLog(@"%@",[DWFileManager tmpDir]);
}

-(void)attributesOfItemAtPath:(NSString *)path {
    NSError * error = nil;
    NSDictionary * attr = [DWFileManager attributesOfItemAtPath:path error:&error];
    if (error) {
        NSLog(@"%@",error);
    } else {
        NSLog(@"%@",attr);
    }
}

-(void)isDirectoryAtPath:(NSString *)path {
    NSLog(@"%@",[DWFileManager isDirectoryAtPath:path]?@"指定路径存在文件夹":@"无法找到指定路径的文件夹");
}

-(void)isFileAtPath:(NSString *)path {
    NSLog(@"%@",[DWFileManager isFileAtPath:path]?@"指定路径存在文件":@"无法找到指定路径的文件");
}

-(void)listFilesInDirectoryAtPath:(NSString *)path {
    NSLog(@"%@",[DWFileManager listFilesInDirectoryAtPath:path deep:YES]);
}

-(void)createDirectoryAtPath:(NSString *)path {
    NSError * error = nil;
    BOOL success = [DWFileManager createDirectoryAtPath:path error:&error];
    if (error) {
        NSLog(@"%@",error);
    } else {
        NSLog(@"文件夹创建%@",success?@"成功":@"失败");
    }
}

-(void)isDirectoryIsEmptyAtPath:(NSString *)path {
    NSLog(@"测试文件夹是%@",[DWFileManager isDirectoryIsEmptyAtPath:path]?@"空文件夹":@"非空文件夹");
}

-(void)removeItemAtPath:(NSString *)path {
    NSLog(@"指定路径文件夹或文件删除%@",[DWFileManager removeItemAtPath:path]?@"成功":@"失败");
}

-(void)clearDirectoryAtPath:(NSString *)path {
    NSLog(@"指定路径文件夹或文件清空%@",[DWFileManager clearDirectoryAtPath:path]?@"成功":@"失败");
}

-(void)clearCachesDir {
    NSLog(@"清空Caches文件夹%@",[DWFileManager cachesDir]?@"成功":@"失败");
}

-(void)createFileAtPath:(NSString *)path {
    NSError * error = nil;
    BOOL success = [DWFileManager createFileAtPath:path content:@"hello world." overwrite:NO error:&error];
    if (error) {
        NSLog(@"%@",error);
    } else {
        NSLog(@"创建文件%@",success?@"成功":@"失败");
    }
}

-(void)writeFileAtPath:(NSString *)path {
    NSError * error = nil;
    BOOL success = [DWFileManager writeFileAtPath:path content:@"write some thing new." error:&error];
    if (error) {
        NSLog(@"%@",error);
    } else {
        NSLog(@"写入文件%@",success?@"成功":@"失败");
    }
}

-(void)copyItemAtPath:(NSString *)path {
    NSError * error = nil;
    BOOL success = [DWFileManager copyItemAtPath:path toPath:[[DWFileManager cachesDir] stringByAppendingPathComponent:[path lastPathComponent]] overwrite:NO error:&error];
    if (error) {
        NSLog(@"%@",error);
    } else {
        NSLog(@"复制文件%@",success?@"成功":@"失败");
    }
}

-(void)moveItemAtPath:(NSString *)path {
    NSError * error = nil;
    BOOL success = [DWFileManager moveItemAtPath:path toPath:[[DWFileManager cachesDir] stringByAppendingPathComponent:[path lastPathComponent]] overwrite:NO error:&error];
    if (error) {
        NSLog(@"%@",error);
    } else {
        NSLog(@"移动文件%@",success?@"成功":@"失败");
    }
}

@end
