//
//  NSString+DWStringUtils.h
//  RegExp
//
//  Created by Wicky on 17/1/8.
//  Copyright © 2017年 Wicky. All rights reserved.
//

/**
 DWStringUtils
 NSString工具类
 
 version 1.0.0
 提供生成连续相同字符组成的指定长度字符串api
 提供根据字体及限制尺寸返回文本尺寸api
 提供以指定长度生成随机字符串的api
 提供文件名序数修复api
 
 version 1.0.1
 添加汉字转拼音api
 添加正则匹配结果api
 
 version 1.0.2
 添加数组按拼音排序方法
 
 version 1.0.3
 结构修改
 拼音排序方法统一修改
 转换时音调支持
 排序时音调支持
 
 version 1.0.4
 再次更改中文排序算法，改为逐字比较。
 */

#import <UIKit/UIKit.h>

@interface NSString (DWStringTransferUtils)

///转拼音后的字符串
@property (nonatomic ,copy) NSString * pinyinString;

///以长度生成随机字符串，字符串有大小写字母及数字组成
+(NSString *)dw_randomStringWithLength:(NSUInteger)length;

+(NSString *)dw_generateUUID;

///给文件名添加序数（文件名重复时使用）
-(NSString *)dw_fixFileNameStringWithIndex:(NSUInteger)idx;

/**
 汉字转拼音

 @param needWhiteSpace 是否需要空格间隔
 @param tone           是否需要音调

 @return 转换后用拼音
 */
-(NSString *)dw_transferChineseToPinYinWithWhiteSpace:(BOOL)needWhiteSpace tone:(BOOL)tone;

///返回整串字符串中符合正则的结果集
-(NSArray <NSTextCheckingResult *> *)dw_rangesConfirmToPattern:(NSString *)pattern;

///符合正则的子串集
-(NSArray <NSString *> *)dw_subStringConfirmToPattern:(NSString *)pattern;

///将字符串分割成词（中文汉字为最小单位，英文单词为最小单位）
-(NSArray *)dw_trimStringToWord;

///判断字符串是否是中文
-(BOOL)dw_stringIsChinese;


/**
 将字符串中的包含在数组中的子串替换为另一字符串

 @param characters 要被替换的子串数组
 @param replacement 替换的目标串
 @param caseInsensitive 是否区分大小写
 @return 替换后的字符串
 */
-(NSString *)dw_stringByReplacingCharactersInArray:(NSArray *)characters withString:(NSString *)replacement caseInsensitive:(BOOL)caseInsensitive;


/**
 去除首尾空格并压缩串中空格至1个

 @return 压缩后的字符串
 */
-(NSString *)dw_stringByTrimmingWhitespace;

@end

@interface NSString (DWStringSortUtils)

///将数组内字符串以拼音排序
+(NSMutableArray <NSString *>*)dw_sortedStringsInPinyin:(NSArray <NSString *>*)strings;

/**
 返回以拼音比较的结果

 @param string 被比较的字符串
 @param tone   是否考虑音调

 @return 比较结果
 */
-(NSComparisonResult)dw_comparedInPinyinWithString:(NSString *)string considerTone:(BOOL)tone;


/**
 返回考虑音调的拼音比较结果

 @param string 被比较的字符串
 @return 比较结果
 */
-(NSComparisonResult)dw_comparedInPinyinWithString:(NSString *)string;

@end

@interface NSString (DWStringSizeUtils)

///根据字号及尺寸限制返回文本尺寸
-(CGSize)dw_stringSizeWithFont:(UIFont *)font widthLimit:(CGFloat)widthLimit heightLimit:(CGFloat)heightLimit;

@end


@interface NSString (Crypto)

///获取MD5后的字符串
-(NSString *)dw_md5String;

@end

@interface NSString (Encode)

-(NSString *)dw_urlEncode;

-(NSString *)dw_urlDecode;

-(NSString *)dw_base64Encode;

-(NSString *)dw_base64Decode;

@end

@interface NSString (Emoji)

///是否包含emoji
-(BOOL)dw_hasEmoji;

///是否全是emoji
-(BOOL)dw_isEmoji;

///截取一个包含emoji的字符串。一个emoji字符串的长度为2，故截取时可能截取到emoji字符串中间的位置导致无法解析，本方法用来解决这个问题。若range的location出恰好位于emoji字符串中间，则自动修正为表情的下一个字符作为起始。若range的最后范围恰好在emoji字符串中间，则自动修正为表情的下一个字符结束，即表情为最后一个字符。
-(NSString *)dw_subEmojiStringWithRange:(NSRange)range;

-(NSString *)dw_subEmojiStringFromIndex:(NSUInteger)from;

-(NSString *)dw_subEmojiStringToIndex:(NSUInteger)to;

@end
