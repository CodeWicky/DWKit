//
//  NSString+DWStringUtils.m
//  RegExp
//
//  Created by Wicky on 17/1/8.
//  Copyright © 2017年 Wicky. All rights reserved.
//

#import "NSString+DWStringUtils.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonCrypto.h>

#define replaceIfContains(string,target,replacement,tone) \
do {\
if ([string containsString:target]) {\
string = [string stringByReplacingOccurrencesOfString:target withString:replacement];\
string = [NSString stringWithFormat:@"%@%d",string,tone];\
}\
} while(0)

@interface NSString ()

@property (nonatomic ,strong) NSArray * wordArray;

@property (nonatomic ,copy) NSString * wordPinyinWithTone;

@property (nonatomic ,copy) NSString * wordPinyinWithoutTone;

@end

@implementation NSString (DWStringTransferUtils)

+(NSString *)dw_randomStringWithLength:(NSUInteger)length {
    char data[length];
    for (int i = 0; i < length; i ++) {
        int ran = arc4random() % 62;
        if (ran < 10) {
            ran += 48;
        } else if (ran < 36) {
            ran += 55;
        } else {
            ran += 61;
        }
        data[i] = (char)ran;
    }
    return [[NSString alloc] initWithBytes:data length:length encoding:NSUTF8StringEncoding];
}

+(NSString *)dw_generateUUID {
    NSString *result = nil;
    NSUUID *uuid = [NSUUID UUID];
    if (uuid) {
        result = uuid.UUIDString;
    }
    NSString * subResult = nil;
    if ([result length] > 8) {
        subResult = [result substringFromIndex:([result length] - 8)];
        return subResult;
    } else {
        return @"";
    }
}

-(NSString *)dw_fixFileNameStringWithIndex:(NSUInteger)idx {
    NSString * extention = [self pathExtension];
    NSString * pureStr = [self stringByDeletingPathExtension];
    pureStr = [pureStr stringByAppendingString:[NSString stringWithFormat:@"_%02lu",idx]];
    return [pureStr stringByAppendingPathExtension:extention];
}

-(NSString *)dw_transferChineseToPinYinWithWhiteSpace:(BOOL)needWhiteSpace tone:(BOOL)tone {
    if (!self.wordArray.count) {
        return nil;
    }
    __block NSString * string = @"";
    NSString * whiteSpace = needWhiteSpace ? @" " : @"";
    [self.wordArray enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString * pinyin = [obj transferWordToPinYinWithTone:tone];
        if (!string.length) {
            string = [string stringByAppendingString:[NSString stringWithString:pinyin]];
        } else {
            string = [string stringByAppendingString:[NSString stringWithFormat:@"%@%@",whiteSpace,pinyin]];
        }
    }];
    return string;
}

-(NSArray<NSTextCheckingResult *> *)dw_rangesConfirmToPattern:(NSString *)pattern {
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    return [regex matchesInString:self options:0 range:NSMakeRange(0, self.length)];
}

-(NSArray<NSString *> *)dw_subStringConfirmToPattern:(NSString *)pattern {
    NSArray * ranges = [self dw_rangesConfirmToPattern:pattern];
    NSMutableArray * strings = [NSMutableArray array];
    for (NSTextCheckingResult * result in ranges) {
        [strings addObject:[self substringWithRange:result.range]];
    }
    return strings;
}

-(NSArray *)dw_trimStringToWord {
    if (self.length) {
        NSMutableArray * temp = [NSMutableArray array];
        [self enumerateSubstringsInRange:NSMakeRange(0, self.length) options:NSStringEnumerationByWords usingBlock:^(NSString * _Nullable substring, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
            if (substring.length > 1 && temp.count == 0 && ![substring dw_stringIsChinese] && [substring dw_subStringConfirmToPattern:@"[\\u4E00-\\u9FA5]+"].count > 0) {///为防止第一个字与英文连在一起
                [temp addObject:[substring substringToIndex:1]];
                [temp addObject:[substring substringFromIndex:1]];
            } else {
                if (substring.length > 1 && [substring dw_stringIsChinese]) {
                    [substring enumerateSubstringsInRange:NSMakeRange(0, substring.length) options:(NSStringEnumerationByComposedCharacterSequences) usingBlock:^(NSString * _Nullable substring2, NSRange substringRange, NSRange enclosingRange, BOOL * _Nonnull stop) {
                        [temp addObject:substring2];
                    }];
                } else {
                    if (substring.length) {
                        [temp addObject:substring];
                    }
                }
            }
        }];
        return [temp copy];
    }
    return nil;
}

-(BOOL)dw_stringIsChinese {
    if (self.length == 0) {
        return NO;
    }
    NSPredicate * predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",@"[\\u4E00-\\u9FA5]+"];
    return [predicate evaluateWithObject:self];
}

-(NSString *)dw_stringByReplacingCharactersInArray:(NSArray *)characters withString:(NSString *)replacement caseInsensitive:(BOOL)caseInsensitive {
    if (characters.count == 0) {
        return nil;
    }
    NSString * pattern = [characters componentsJoinedByString:@","];
    pattern = [@"[" stringByAppendingString:pattern];
    pattern = [pattern stringByAppendingString:@"]"];
    NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:pattern options:(caseInsensitive?NSRegularExpressionCaseInsensitive:0) error:nil];
    return [regex stringByReplacingMatchesInString:self options:(NSMatchingReportProgress) range:NSMakeRange(0, self.length) withTemplate:replacement];
}

-(NSString *)dw_stringByTrimmingWhitespace {
    NSString * temp = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSArray *components = [temp componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    components = [components filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self <> ''"]];
    return [components componentsJoinedByString:@" "];
}

#pragma mark --- setter/getter ---
-(void)setPinyinString:(NSString *)pinyinString {
    objc_setAssociatedObject(self, @selector(pinyinString), pinyinString, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(NSString *)pinyinString {
    NSString * pinyin = objc_getAssociatedObject(self, _cmd);
    if (!pinyin) {
        pinyin = [self dw_transferChineseToPinYinWithWhiteSpace:YES tone:YES];
        objc_setAssociatedObject(self, @selector(pinyinString), pinyin, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    return pinyin;
}

#pragma mark --- tool method ---
-(NSString *)transferWordToPinYinWithTone:(BOOL)tone {
    if (tone && self.wordPinyinWithTone) {
        return self.wordPinyinWithTone;
    } else if (!tone && self.wordPinyinWithoutTone) {
        return self.wordPinyinWithoutTone;
    }
    NSMutableString * mutableString = [[NSMutableString alloc] initWithString:self];
    CFStringTransform((CFMutableStringRef)mutableString, NULL, kCFStringTransformToLatin, false);
    NSStringCompareOptions toneOption = tone ?NSCaseInsensitiveSearch:NSDiacriticInsensitiveSearch;
    NSString * pinyin = [mutableString stringByFoldingWithOptions:toneOption locale:[NSLocale currentLocale]];
    if (tone) {
        self.wordPinyinWithTone = pinyin;
    } else {
        self.wordPinyinWithoutTone = pinyin;
    }
    return pinyin;
}

@end

@implementation NSString (DWStringSortUtils)

+(NSMutableArray <NSString *>*)dw_sortedStringsInPinyin:(NSArray<NSString *> *)strings {
    NSMutableArray * newStrings = [NSMutableArray arrayWithArray:strings];
    ///按拼音/汉字排序指定范围联系人
    [newStrings sortUsingComparator:^NSComparisonResult(NSString * obj1, NSString * obj2) {
        return [obj1 dw_comparedInPinyinWithString:obj2 considerTone:YES];
    }];
    return newStrings;
}

-(NSComparisonResult)dw_comparedInPinyinWithString:(NSString *)string considerTone:(BOOL)tone {
    if ([self isEqualToString:string]) {
        return NSOrderedSame;
    }
    NSArray <NSString *>* arr1 = self.wordArray;
    NSArray <NSString *>* arr2 = string.wordArray;
    NSUInteger minL = MIN(arr1.count, arr2.count);
    for (int i = 0; i < minL; i ++) {
        if ([arr1[i] isEqualToString:arr2[i]]) {
            continue;
        }
        NSString * pinyin1 = [arr1[i] transferWordToPinYinWithTone:tone];
        NSString * pinyin2 = [arr2[i] transferWordToPinYinWithTone:tone];
        if (tone) {
            pinyin1 = transformPinyinTone(pinyin1);
            pinyin2 = transformPinyinTone(pinyin2);
        }
        NSComparisonResult result = [pinyin1 caseInsensitiveCompare:pinyin2];
        if (result != NSOrderedSame) {
            return result;
        } else {
            result = [arr1[i] localizedCompare:arr2[i]];
            if (result != NSOrderedSame) {
                return result;
            }
        }
    }
    if (arr1.count < arr2.count) {
        return NSOrderedAscending;
    } else if (arr1.count > arr2.count) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

-(NSComparisonResult)dw_comparedInPinyinWithString:(NSString *)string {
    return [self dw_comparedInPinyinWithString:string considerTone:YES];
}

-(void)setWordPinyinWithTone:(NSString *)wordPinyinWithTone {
    objc_setAssociatedObject(self, @selector(wordPinyinWithTone), wordPinyinWithTone, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(NSString *)wordPinyinWithTone {
    return objc_getAssociatedObject(self, _cmd);
}

-(void)setWordPinyinWithoutTone:(NSString *)wordPinyinWithoutTone {
    objc_setAssociatedObject(self, @selector(wordPinyinWithoutTone), wordPinyinWithoutTone, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

-(NSString *)wordPinyinWithoutTone {
    return objc_getAssociatedObject(self, _cmd);
}

-(void)setWordArray:(NSArray *)wordArray {
    objc_setAssociatedObject(self, @selector(wordArray), wordArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(NSArray *)wordArray {
    NSArray * array = objc_getAssociatedObject(self, _cmd);
    if (!array) {
        array = [self dw_trimStringToWord];
        objc_setAssociatedObject(self, @selector(wordArray), array, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return array;
}

#pragma mark --- inline method ---
static NSString * transformPinyinTone(NSString * pinyin) {
    replaceIfContains(pinyin, @"ā", @"a",1);
    replaceIfContains(pinyin, @"á", @"a",2);
    replaceIfContains(pinyin, @"ǎ", @"a",3);
    replaceIfContains(pinyin, @"à", @"a",4);
    replaceIfContains(pinyin, @"ō", @"o",1);
    replaceIfContains(pinyin, @"ó", @"o",2);
    replaceIfContains(pinyin, @"ǒ", @"o",3);
    replaceIfContains(pinyin, @"ò", @"o",4);
    replaceIfContains(pinyin, @"ē", @"e",1);
    replaceIfContains(pinyin, @"é", @"e",2);
    replaceIfContains(pinyin, @"ě", @"e",3);
    replaceIfContains(pinyin, @"è", @"e",4);
    replaceIfContains(pinyin, @"ī", @"i",1);
    replaceIfContains(pinyin, @"í", @"i",2);
    replaceIfContains(pinyin, @"ǐ", @"i",3);
    replaceIfContains(pinyin, @"ì", @"i",4);
    replaceIfContains(pinyin, @"ū", @"u",1);
    replaceIfContains(pinyin, @"ú", @"u",2);
    replaceIfContains(pinyin, @"ǔ", @"u",3);
    replaceIfContains(pinyin, @"ù", @"u",4);
    return pinyin;
}

@end

@implementation NSString (DWStringSizeUtils)

-(CGSize)dw_stringSizeWithFont:(UIFont *)font widthLimit:(CGFloat)widthLimit heightLimit:(CGFloat)heightLimit
{
    return  [self boundingRectWithSize:CGSizeMake(widthLimit, heightLimit) options: NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil].size;
}

@end

@implementation NSString (Crypto)

-(NSString *)dw_md5String {
    const char * chars = self.UTF8String;
    CC_MD5_CTX md5;
    CC_MD5_Init (&md5);
    CC_MD5_Update (&md5, chars, (uint)strlen(chars));
    
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final (digest, &md5);
    return  [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
             digest[0],  digest[1],
             digest[2],  digest[3],
             digest[4],  digest[5],
             digest[6],  digest[7],
             digest[8],  digest[9],
             digest[10], digest[11],
             digest[12], digest[13],
             digest[14], digest[15]];
}

@end

@implementation NSString (Encode)

-(NSString *)dw_urlEncode {
    return [self stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

-(NSString *)dw_urlDecode {
    return [self stringByRemovingPercentEncoding];
}

-(NSString *)dw_base64Encode {
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    return [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
}

-(NSString *)dw_base64Decode {
    NSData *data = [[NSData alloc] initWithBase64EncodedString:self options:NSDataBase64DecodingIgnoreUnknownCharacters];    
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end

@implementation NSString (Emoji)

-(BOOL)dw_hasEmoji {
    __block BOOL returnValue = NO;
    [self enumerateSubstringsInRange:NSMakeRange(0, [self length]) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
     ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        
        const unichar hs = [substring characterAtIndex:0];
        // surrogate pair
        if (0xd800 <= hs && hs <= 0xdbff) {
            if (substring.length > 1) {
                const unichar ls = [substring characterAtIndex:1];
                const int uc = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
                if (0x1d000 <= uc && uc <= 0x1f77f) {
                    returnValue = YES;
                }
            }
        } else if (substring.length > 1) {
            const unichar ls = [substring characterAtIndex:1];
            if (ls == 0x20e3) {
                returnValue = YES;
            }
            
        } else {
            // non surrogate
            if (0x2100 <= hs && hs <= 0x27ff) {
                returnValue = YES;
            } else if (0x2B05 <= hs && hs <= 0x2b07) {
                returnValue = YES;
            } else if (0x2934 <= hs && hs <= 0x2935) {
                returnValue = YES;
            } else if (0x3297 <= hs && hs <= 0x3299) {
                returnValue = YES;
            } else if (hs == 0xa9 || hs == 0xae || hs == 0x303d || hs == 0x3030 || hs == 0x2b55 || hs == 0x2b1c || hs == 0x2b1b || hs == 0x2b50) {
                returnValue = YES;
            }
        }
        
        if (returnValue) {
            *stop = YES;
        }
    }];
    return returnValue;
}

-(BOOL)dw_isEmoji {
    unichar startChar = 0xcfff;
    unichar endChar = 0xe000;
    NSUInteger length = [self length];
    BOOL isEmoji = NO;
    for (int i = 0; i < length; i ++) {
        unichar aChar = [self characterAtIndex:i];
        if (aChar >= startChar && aChar <= endChar) {
            isEmoji = YES;
        } else {
            isEmoji = NO;
            break;
        }
    }
    return isEmoji;
}

-(NSString *)dw_subEmojiStringWithRange:(NSRange)range {
    
    NSUInteger length = self.length;
    ///起点大于等于长度，不合法，返回空
    if (range.location >= length) {
        return nil;
    }
    
    ///长度是0，直接返回空字符串
    if (range.length == 0) {
        return @"";
    }
    ///最大位置大于长度，截取超长，修正长度为截取至结尾的长度
    if (NSMaxRange(range) > length) {
        range.length = length - range.location;
    }
    
    ///如果修正后的range的length等于字符串本身的length，只能是一种情况，location为零，且长度为字符串长度。此时结果即字符串本身，直接返回copy
    if (range.length == length) {
        return [self copy];
    }
    
    ///开始修正range，先修正location
    if (range.location > 0) {
        NSRange rangeLoc = [self rangeOfComposedCharacterSequenceAtIndex:range.location];
        ///说明不是长度为1的字符，改range
        if (rangeLoc.length > 1) {
            NSUInteger oriMaxIndex = NSMaxRange(range);
            range.location = NSMaxRange(rangeLoc);
            range.length = oriMaxIndex - range.location;
        }
    }
    
    ///修复完location后恰好长度小于等于0，返回空字符串
    if (range.length <= 0) {
        return @"";
    }
    
    ///开始修正最后一个字符
    if (NSMaxRange(range) < length) {
        NSRange rangeLen = [self rangeOfComposedCharacterSequenceAtIndex:NSMaxRange(range)];
        if (rangeLen.length > 1) {
            range.length = NSMaxRange(rangeLen) - range.location;
        }
    }
    
    ///同样，如果修正完没有长度，直接返回空字符串
    if (range.length <= 0) {
        return @"";
    }
    
    ///返回截取后的字符串
    return [self substringWithRange:range];
}

-(NSString *)dw_subEmojiStringFromIndex:(NSUInteger)from {
    return [self dw_subEmojiStringWithRange:NSMakeRange(from, self.length - from)];
}

-(NSString *)dw_subEmojiStringToIndex:(NSUInteger)to {
    return [self dw_subEmojiStringWithRange:NSMakeRange(0, to)];
}

@end
