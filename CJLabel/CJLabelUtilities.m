//
//  CJLabelUtilities.m
//  CJLabelTest
//
//  Created by ChiJinLian on 2017/4/13.
//  Copyright © 2017年 ChiJinLian. All rights reserved.
//

#import "CJLabelUtilities.h"

NSString * const kCJImageAttributeName                       = @"kCJImageAttributeName";
NSString * const kCJLinkAttributesName                       = @"kCJLinkAttributesName";
NSString * const kCJActiveLinkAttributesName                 = @"kCJActiveLinkAttributesName";
NSString * const kCJIsLinkAttributesName                     = @"kCJIsLinkAttributesName";
NSString * const kCJLinkRangeAttributesName                  = @"kCJLinkRangeAttributesName";
NSString * const kCJLinkParameterAttributesName              = @"kCJLinkParameterAttributesName";
NSString * const kCJClickLinkBlockAttributesName             = @"kCJClickLinkBlockAttributesName";
NSString * const kCJLongPressBlockAttributesName             = @"kCJLongPressBlockAttributesName";
NSString * const kCJLinkNeedRedrawnAttributesName            = @"kCJLinkNeedRedrawnAttributesName";



void RunDelegateDeallocCallback(void * refCon) {
    
}

//获取图片高度
CGFloat RunDelegateGetAscentCallback(void * refCon) {
    return [(NSNumber *)[(__bridge NSDictionary *)refCon objectForKey:@"height"] floatValue];
}

CGFloat RunDelegateGetDescentCallback(void * refCon) {
    return 0;
}
//获取图片宽度
CGFloat RunDelegateGetWidthCallback(void * refCon) {
    return [(NSNumber *)[(__bridge NSDictionary *)refCon objectForKey:@"width"] floatValue];
}

@implementation CJLabelUtilities

+ (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
                                                addImageName:(NSString *)imageName
                                                   imageSize:(CGSize)size
                                                     atIndex:(NSUInteger)loc
                                              linkAttributes:(NSDictionary *)linkAttributes
                                        activeLinkAttributes:(NSDictionary *)activeLinkAttributes
                                                   parameter:(id)parameter
                                              clickLinkBlock:(CJLabelLinkModelBlock)clickLinkBlock
                                              longPressBlock:(CJLabelLinkModelBlock)longPressBlock
                                                      islink:(BOOL)isLink
{
    if (CJLabelIsNull(imageName) || imageName.length == 0) {
        return [[NSMutableAttributedString alloc]initWithAttributedString:attrStr];
    }
    
    NSDictionary *imgInfoDic = @{@"imageName":imageName,@"width":@(size.width),@"height":@(size.height)};
    
    //创建CTRunDelegateRef并设置回调函数
    CTRunDelegateCallbacks imageCallbacks;
    imageCallbacks.version = kCTRunDelegateVersion1;
    imageCallbacks.dealloc = RunDelegateDeallocCallback;
    imageCallbacks.getWidth = RunDelegateGetWidthCallback;
    imageCallbacks.getAscent = RunDelegateGetAscentCallback;
    imageCallbacks.getDescent = RunDelegateGetDescentCallback;
    CTRunDelegateRef runDelegate = CTRunDelegateCreate(&imageCallbacks, (__bridge void *)imgInfoDic);
    
    //插入空白表情占位符
    NSMutableAttributedString *imageAttributedString = [[NSMutableAttributedString alloc] initWithString:@" "];
    [imageAttributedString addAttribute:(NSString *)kCTRunDelegateAttributeName value:(__bridge id)runDelegate range:NSMakeRange(0, 1)];
    [imageAttributedString addAttribute:kCJImageAttributeName value:imgInfoDic range:NSMakeRange(0, 1)];
    
    if (!CJLabelIsNull(linkAttributes) && linkAttributes.count > 0) {
        [imageAttributedString addAttribute:kCJLinkAttributesName value:linkAttributes range:NSMakeRange(0, 1)];
    }
    if (!CJLabelIsNull(activeLinkAttributes) && activeLinkAttributes.count > 0) {
        [imageAttributedString addAttribute:kCJActiveLinkAttributesName value:activeLinkAttributes range:NSMakeRange(0, 1)];
    }
    if (!CJLabelIsNull(parameter)) {
        [imageAttributedString addAttribute:kCJLinkParameterAttributesName value:parameter range:NSMakeRange(0, 1)];
    }
    if (!CJLabelIsNull(clickLinkBlock)) {
        [imageAttributedString addAttribute:kCJClickLinkBlockAttributesName value:clickLinkBlock range:NSMakeRange(0, 1)];
    }
    if (!CJLabelIsNull(longPressBlock)) {
        [imageAttributedString addAttribute:kCJLongPressBlockAttributesName value:longPressBlock range:NSMakeRange(0, 1)];
    }
    if (isLink) {
        [imageAttributedString addAttribute:kCJIsLinkAttributesName value:@(YES) range:NSMakeRange(0, 1)];
    }
    NSRange range = NSMakeRange(loc, 1);
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithAttributedString:attrStr];
    [attributedString insertAttributedString:imageAttributedString atIndex:range.location];
    CFRelease(runDelegate);
    
    return attributedString;
}

+ (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
                                                     atRange:(NSRange)range
                                              linkAttributes:(NSDictionary *)linkAttributes
                                        activeLinkAttributes:(NSDictionary *)activeLinkAttributes
                                                   parameter:(id)parameter
                                              clickLinkBlock:(CJLabelLinkModelBlock)clickLinkBlock
                                              longPressBlock:(CJLabelLinkModelBlock)longPressBlock
                                                      islink:(BOOL)isLink
{
    NSParameterAssert((range.location + range.length) <= attrStr.length);
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithAttributedString:attrStr];
    UIFont *linkFont = nil;
    UIFont *activeLinkFont = nil;
    if (!CJLabelIsNull(linkAttributes) && linkAttributes.count > 0) {
        linkFont = linkAttributes[NSFontAttributeName];
        [attributedString addAttribute:kCJLinkAttributesName value:linkAttributes range:range];
    }
    if (!CJLabelIsNull(activeLinkAttributes) && activeLinkAttributes.count > 0) {
        activeLinkFont = activeLinkAttributes[NSFontAttributeName];
        [attributedString addAttribute:kCJActiveLinkAttributesName value:activeLinkAttributes range:range];
    }
    //正常状态跟点击高亮状态下字体大小不同，标记需要重绘
    if ((linkFont && activeLinkFont) && (![linkFont.fontName isEqualToString:activeLinkFont.fontName] || linkFont.pointSize != activeLinkFont.pointSize)) {
        [attributedString addAttribute:kCJLinkNeedRedrawnAttributesName value:@(YES) range:range];
    }
    if (!CJLabelIsNull(parameter)) {
        [attributedString addAttribute:kCJLinkParameterAttributesName value:parameter range:range];
    }
    if (!CJLabelIsNull(clickLinkBlock)) {
        [attributedString addAttribute:kCJClickLinkBlockAttributesName value:clickLinkBlock range:range];
    }
    if (!CJLabelIsNull(longPressBlock)) {
        [attributedString addAttribute:kCJLongPressBlockAttributesName value:longPressBlock range:range];
    }
    if (isLink) {
        [attributedString addAttribute:kCJIsLinkAttributesName value:@(YES) range:range];
    }
    return attributedString;
}

+ (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
                                               withAttString:(NSAttributedString *)withAttString
                                            sameStringEnable:(BOOL)sameStringEnable
                                              linkAttributes:(NSDictionary *)linkAttributes
                                        activeLinkAttributes:(NSDictionary *)activeLinkAttributes
                                                   parameter:(id)parameter
                                              clickLinkBlock:(CJLabelLinkModelBlock)clickLinkBlock
                                              longPressBlock:(CJLabelLinkModelBlock)longPressBlock
                                                      islink:(BOOL)isLink
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithAttributedString:attrStr];
    if (!sameStringEnable) {
        NSRange range = [self getFirstRangeWithAttString:withAttString inAttString:attrStr];
        if (range.location != NSNotFound) {
            attributedString = [self configureLinkAttributedString:attributedString atRange:range linkAttributes:linkAttributes activeLinkAttributes:activeLinkAttributes parameter:parameter clickLinkBlock:clickLinkBlock longPressBlock:longPressBlock islink:isLink];
        }
    }else{
        NSArray *rangeAry = [self getRangeArrayWithString:withAttString.string inString:attrStr.string lastRange:NSMakeRange(0, 0) rangeArray:[NSMutableArray array]];
        if (rangeAry.count > 0) {
            for (NSString *strRange in rangeAry) {
                attributedString = [self configureLinkAttributedString:attributedString atRange:NSRangeFromString(strRange) linkAttributes:linkAttributes activeLinkAttributes:activeLinkAttributes parameter:parameter clickLinkBlock:clickLinkBlock longPressBlock:longPressBlock islink:isLink];
            }
        }
    }
    return attributedString;
}

#pragma mark -

+ (NSRange)getFirstRangeWithAttString:(NSAttributedString *)withAttString inAttString:(NSAttributedString *)attString {
    NSRange range = [attString.string rangeOfString:withAttString.string];
    if (range.location == NSNotFound) {
        return range;
    }
    NSAttributedString *str = [attString attributedSubstringFromRange:range];
    if (![withAttString isEqualToAttributedString:str]) {
        range = NSMakeRange(NSNotFound, 0);
    }
    return range;
}

+ (NSArray <NSString *>*)getRangeArrayWithAttString:(NSAttributedString *)withAttString inAttString:(NSAttributedString *)attString {
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:3];
    NSArray *strRanges = [self getRangeArrayWithString:withAttString.string inString:attString.string lastRange:NSMakeRange(0, 0) rangeArray:[NSMutableArray array]];
    
    if (strRanges.count > 0) {
        for (NSString *rangeStr in strRanges) {
            NSRange range = NSRangeFromString(rangeStr);
            NSAttributedString *str = [attString attributedSubstringFromRange:range];
            if ([withAttString isEqualToAttributedString:str]) {
                [array addObject:rangeStr];
            }
        }
    }
    return array;
}

/**
 *  遍历string，获取withString在string中的所有NSRange数组
 *
 *  @param withString 需要匹配的string
 *  @param string     string文本
 *  @param lastRange  withString上一次出现的NSRange值，初始为NSMakeRange(0, 0)
 *  @param array      初始NSRange数组
 *
 *  @return           返回最后的NSRange数组
 */
+ (NSArray <NSString *>*)getRangeArrayWithString:(NSString *)withString
                                        inString:(NSString *)string
                                       lastRange:(NSRange)lastRange
                                      rangeArray:(NSMutableArray *)array
{
    NSRange range = [string rangeOfString:withString];
    if (range.location == NSNotFound){
        return array;
    }else{
        NSRange curRange = NSMakeRange(lastRange.location+lastRange.length+range.location, range.length);
        [array addObject:NSStringFromRange(curRange)];
        NSString *tempString = [string substringFromIndex:(range.location+range.length)];
        [self getRangeArrayWithString:withString inString:tempString lastRange:curRange rangeArray:array];
        return array;
    }
}

@end



@implementation CJGlyphRunStrokeItem

- (id)copyWithZone:(NSZone *)zone {
    CJGlyphRunStrokeItem *item = [[[self class] allocWithZone:zone] init];
    item.strokeColor = [self.strokeColor copyWithZone:zone];
    item.fillColor = self.fillColor;
    item.lineWidth = self.lineWidth;
    item.runBounds = self.runBounds;
    item.locBounds = self.locBounds;
    item.cornerRadius = self.cornerRadius;
    item.activeFillColor = self.activeFillColor;
    item.activeStrokeColor = self.activeStrokeColor;
    item.image = self.image;
    item.range = self.range;
    item.parameter = self.parameter;
    item.linkBlock = self.linkBlock;
    item.longPressBlock = self.longPressBlock;
    item.isLink = self.isLink;
    item.needRedrawn = self.needRedrawn;
    return item;
}

@end
