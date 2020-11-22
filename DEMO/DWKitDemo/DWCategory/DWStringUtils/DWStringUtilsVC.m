//
//  DWStringUtilsVC.m
//  DWKitDemo
//
//  Created by Wicky on 2020/4/30.
//  Copyright © 2020 Wicky. All rights reserved.
//

#import "DWStringUtilsVC.h"
#import <DWKit/NSString+DWStringUtils.h>

@interface DWStringUtilsVC ()

@end

@implementation DWStringUtilsVC

-(void)configActions {
    self.actions = @[
                     actionWithTitle(@selector(chinesePinyinString), @"展示【Wicky老司机】的拼音"),
                     actionWithTitle(@selector(randomString), @"获取指定长度的随机字符串"),
                     actionWithTitle(@selector(generateUUID),@"获取8位长度的UUID"),
                     actionWithTitle(@selector(fixFileName), @"给文件名【东风破.mp3】添加序号"),
                     actionWithTitle(@selector(transformToPinyin), @"将【Wicky老司机】转换为拼音，无需空格间隔及音调"),
                     actionWithTitle(@selector(rangeForPattern), @"获取【abc123def】中符合表达式的范围"),
                     actionWithTitle(@selector(subStringForPattern), @"获取【abc123def】中符合表达式的子串"),
                     actionWithTitle(@selector(trimWord), @"以此为单位断句【Code Wicky 老司机】"),
                     actionWithTitle(@selector(stringIsChinese), @"判断【Code Wicky 老司机】是不是中文"),
                     actionWithTitle(@selector(replaceChars), @"替换【Code Wicky 老司机】中指定的字符串"),
                     actionWithTitle(@selector(trimString), @"去除首位及压缩【     你好   老司机  】中的空格"),
                     actionWithTitle(@selector(sortStringInPinyin), @"按拼音排序指定字符串数组"),
                     actionWithTitle(@selector(comparePinyinIgnoreTone), @"不考虑音调比较两个字符串的拼音"),
                     actionWithTitle(@selector(comparePinyin), @"考虑音调比较两个字符串的拼音"),
                     actionWithTitle(@selector(stringSize), @"计算字符串的尺寸"),
                     actionWithTitle(@selector(md5String), @"打印【Wicky老司机】MD5加密后的结果"),
                     actionWithTitle(@selector(urlEncode), @"打印URLEncode后的字符串"),
                     actionWithTitle(@selector(urlDecode), @"打印URLDecode后的字符串"),
                     actionWithTitle(@selector(base64Encode), @"打印base64编码后的字符串"),
                     actionWithTitle(@selector(base64Decode), @"打印base64解码后的字符串"),
                     actionWithTitle(@selector(hasEmoji), @"检测字符串是否包含emoji"),
                     actionWithTitle(@selector(isEmoji), @"检测字符串是否全部为emoji"),
                     actionWithTitle(@selector(emojiSubString), @"截取包含emoji的字符串"),
                     ];
}

-(void)chinesePinyinString {
    NSLog(@"%@",@"Wicky老司机".pinyinString);
}

-(void)randomString {
    NSLog(@"%@",[NSString dw_randomStringWithLength:16]);
}

-(void)generateUUID {
    NSLog(@"%@",[NSString dw_generateUUID]);
}

-(void)fixFileName {
    NSLog(@"%@",[@"东风破.mp3" dw_fixFileNameStringWithIndex:1]);
}

-(void)transformToPinyin {
    NSLog(@"%@",[@"Wicky老司机" dw_transferChineseToPinYinWithWhiteSpace:NO tone:NO]);
}

-(void)rangeForPattern {
    NSLog(@"%@",[@"abc123def" dw_rangesConfirmToPattern:@"[a-z]+"]);
}

-(void)subStringForPattern {
    NSLog(@"%@",[@"abc123def" dw_subStringConfirmToPattern:@"[a-z]+"]);
}

-(void)trimWord {
    NSLog(@"%@",[@"Code Wicky 老司机" dw_trimStringToWord]);
}

-(void)stringIsChinese {
    NSLog(@"%d",[@"Code Wicky 老司机" dw_stringIsChinese]);
}

-(void)replaceChars {
    NSLog(@"%@",[@"Code Wicky 老司机" dw_stringByReplacingCharactersInArray:@[@"C",@" ",@"老"] withString:@"+" caseInsensitive:NO]);
}

-(void)trimString {
    NSLog(@"%@",[@"     你好   老司机  " dw_stringByTrimmingWhitespace]);
}

-(void)sortStringInPinyin {
    NSLog(@"%@",[NSString dw_sortedStringsInPinyin:@[@"张三",@"李四",@"王二",@"冯五",@"疯六",@"John",@"Wicky",@"王二麻子"]]);
}

-(void)comparePinyinIgnoreTone {
    NSLog(@"%ld",[@"汪汪" dw_comparedInPinyinWithString:@"忘忘" considerTone:NO]);
}

-(void)comparePinyin {
    NSLog(@"%ld",[@"疯五" dw_comparedInPinyinWithString:@"凤舞"]);
}

-(void)stringSize {
    NSLog(@"%@",NSStringFromCGSize([@"Wicky老司机" dw_stringSizeWithFont:[UIFont systemFontOfSize:12] widthLimit:70 heightLimit:MAXFLOAT]));
}

-(void)md5String {
    NSLog(@"%@",[@"Wicky老司机" dw_md5String]);
}

-(void)urlEncode {
    NSLog(@"%@",[@"http://www.baidu.com?keyword=Wicky老司机" dw_urlEncode]);
}

-(void)urlDecode {
    NSLog(@"%@",[@"http://www.baidu.com?keyword=Wicky%E8%80%81%E5%8F%B8%E6%9C%BA" dw_urlDecode]);
}

-(void)base64Encode {
    NSLog(@"%@",[@"Wicky老司机" dw_base64Encode]);
}

-(void)base64Decode {
    NSLog(@"%@",[@"V2lja3nogIHlj7jmnLo=" dw_base64Decode]);
}

-(void)hasEmoji {
    NSLog(@"%d",[@"Wicky🚄老司机🚄" dw_hasEmoji]);
}

-(void)isEmoji {
    NSLog(@"%d",[@"🚄" dw_hasEmoji]);
}

-(void)emojiSubString {
    NSLog(@"%@",[@"Wicky🚄老司机🚄"  dw_subEmojiStringWithRange:NSMakeRange(6, 5)]);
}

@end
