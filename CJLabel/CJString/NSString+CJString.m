//
//  NSString+CJString.m
//  CJLabelTest
//
//  Created by C.K.Lian on 16/4/5.
//  Copyright © 2016年 C.K.Lian. All rights reserved.
//

#import "NSString+CJString.h"
#import <CoreText/CoreText.h>

@implementation NSString (CJString)

static inline CGFLOAT_TYPE CGFloat_ceil(CGFLOAT_TYPE cgfloat) {
#if CGFLOAT_IS_DOUBLE
    return ceil(cgfloat);
#else
    return ceilf(cgfloat);
#endif
}

+ (NSRange)getFirstRangeWithLinkString:(NSString *)linkString inTextString:(NSString *)string {
    NSRange linkRange = [string rangeOfString:linkString];
    return linkRange;
}

+ (NSArray *)getRangeArrayWithLinkString:(NSString *)linkString
                            inTextString:(NSString *)string
                               lastRange:(NSRange)lastRange
                              rangeArray:(NSMutableArray *)array
{
    NSRange range = [string rangeOfString:linkString];
    if (range.location == NSNotFound){
        return array;
    }else{
        NSRange curRange = NSMakeRange(lastRange.location+lastRange.length+range.location, range.length);
        [array addObject:NSStringFromRange(curRange)];
        NSString *tempString = [string substringFromIndex:(range.location+range.length)];
        [self getRangeArrayWithLinkString:linkString inTextString:tempString lastRange:curRange rangeArray:array];
        return array;
    }
}

+ (CGSize)sizeLabelToFit:(NSAttributedString *)aString width:(CGFloat)width height:(CGFloat)height {
    UILabel *tempLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, width, height)];
    tempLabel.attributedText = aString;
    tempLabel.numberOfLines = 0;
    [tempLabel sizeToFit];
    CGSize size = tempLabel.frame.size;
    size = CGSizeMake(CGFloat_ceil(size.width), CGFloat_ceil(size.height));
//    NSLog(@"###### 方法二 ########");
//    NSLog(@"sizeLabelToFitSize %@",NSStringFromCGSize(size));
    return size;
}

+ (CGSize)getStringRect:(NSAttributedString *)aString width:(CGFloat)width height:(CGFloat)height
{
    CGSize size = CGSizeZero;
    NSMutableAttributedString *atrString = [[NSMutableAttributedString alloc] initWithAttributedString:aString];
    NSRange range = NSMakeRange(0, atrString.length);
    
    //获取指定位置上的属性信息，并返回与指定位置属性相同并且连续的字符串的范围信息。
    NSDictionary* dic = [atrString attributesAtIndex:0 effectiveRange:&range];
    //不存在段落属性，则存入默认值
    NSMutableParagraphStyle *paragraphStyle = dic[NSParagraphStyleAttributeName];
    if (!paragraphStyle || nil == paragraphStyle) {
        paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineSpacing = 0.0;//增加行高
        paragraphStyle.headIndent = 0;//头部缩进，相当于左padding
        paragraphStyle.tailIndent = 0;//相当于右padding
        paragraphStyle.lineHeightMultiple = 0;//行间距是多少倍
        paragraphStyle.alignment = NSTextAlignmentLeft;//对齐方式
        paragraphStyle.firstLineHeadIndent = 0;//首行头缩进
        paragraphStyle.paragraphSpacing = 0;//段落后面的间距
        paragraphStyle.paragraphSpacingBefore = 0;//段落之前的间距
        [atrString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
    }
    
    //设置默认字体属性
    UIFont *font = dic[NSFontAttributeName];
    if (!font || nil == font) {
        font = [UIFont fontWithName:@"HelveticaNeue" size:12.0];
        [atrString addAttribute:NSFontAttributeName value:font range:range];
    }
    
    NSMutableDictionary *attDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    [attDic setObject:font forKey:NSFontAttributeName];
    [attDic setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    
    CGSize strSize = [[aString string] boundingRectWithSize:CGSizeMake(width, height)
                                                    options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                 attributes:attDic
                                                    context:nil].size;
    
    size = CGSizeMake(CGFloat_ceil(strSize.width), CGFloat_ceil(strSize.height));
//    NSLog(@"###### 方法一 ########");
//    NSLog(@"boundingRectWithSize %@",NSStringFromCGSize(size));
    return size;
}

+ (NSMutableAttributedString *)getNSAttributedString:(NSString *)labelStr labelDict:(NSDictionary *)labelDic
{
    
    NSMutableAttributedString *atrString = [[NSMutableAttributedString alloc] initWithString:labelStr];
    NSRange range = NSMakeRange(0, atrString.length);
    if (labelDic && labelDic.count > 0) {
        NSEnumerator *enumerator = [labelDic keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
            [atrString addAttribute:key value:labelDic[key] range:range];
        }
    }
    //段落属性
    NSMutableParagraphStyle *paragraphStyle = labelDic[NSParagraphStyleAttributeName];
    if (!paragraphStyle || nil == paragraphStyle) {
        paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineSpacing = 0.0;//增加行高
        paragraphStyle.headIndent = 0;//头部缩进，相当于左padding
        paragraphStyle.tailIndent = 0;//相当于右padding
        paragraphStyle.lineHeightMultiple = 0;//行间距是多少倍
        paragraphStyle.alignment = NSTextAlignmentLeft;//对齐方式
        paragraphStyle.firstLineHeadIndent = 0;//首行头缩进
        paragraphStyle.paragraphSpacing = 0;//段落后面的间距
        paragraphStyle.paragraphSpacingBefore = 0;//段落之前的间距
        [atrString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
    }
    
    //字体
    UIFont *font = labelDic[NSFontAttributeName];
    if (!font || nil == font) {
        font = [UIFont fontWithName:@"HelveticaNeue" size:12.0];
        [atrString addAttribute:NSFontAttributeName value:font range:range];
    }
    
    return atrString;
}


#pragma - mark 计算AttributedStringHeight，包含的三种方法计算结果均有误差，UILabel显示时上下会有空白行，且留白范围与所显示内容呈递增关系
+ (CGFloat)getAttributedStringHeightWithString:(NSAttributedString *)string width:(CGFloat)width {
    CGFloat heightValue = 0;
    //string 为要计算高的NSAttributedString
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)string);
    
    /******************
     * 1、使用CTFramesetterSuggestFrameSizeWithConstraints计算
     ******************/
    CGSize size = CGSizeMake(width, CJFLOAT_MAX);
    CGSize suggestedSize= CTFramesetterSuggestFrameSizeForAttributedStringWithConstraints(framesetter,string,size,CJFLOAT_MAX);
    heightValue = suggestedSize.height;
//    NSLog(@"###### 方法三 ########");
//    NSLog(@"1、使用CTFramesetterSuggestFrameSizeWithConstraints计算");
//    NSLog(@"suggestedSize %@",NSStringFromCGSize(suggestedSize));
    
    
    //这里的高要设置足够大
    CGFloat height = CJFLOAT_MAX;
    CGRect drawingRect = CGRectMake(0, 0, width, height);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, drawingRect);
    CTFrameRef textFrame = CTFramesetterCreateFrame(framesetter,CFRangeMake(0,0), path, NULL);
    CGPathRelease(path);
    CFRelease(framesetter);
    CFArrayRef lines = CTFrameGetLines(textFrame);
    CGPoint lineOrigins[CFArrayGetCount(lines)];
    CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), lineOrigins);
    
    /******************
     * 2、逐行lineHeight累加
     ******************/
    heightValue = 0;
    for (int i = 0; i < CFArrayGetCount(lines); i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CGFloat lineAscent;//上行行高
        CGFloat lineDescent;//下行行高
        CGFloat lineLeading;//行距
        CGFloat lineHeight;//行高
        //获取每行的高度
        CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
        lineHeight = lineAscent +  fabs(lineDescent) + lineLeading;
        heightValue = heightValue + lineHeight;
    }
    heightValue = CGFloat_ceil(heightValue);
//    NSLog(@"2、逐行lineHeight累加");
//    NSLog(@"heightValue %@",@(heightValue));
    
    /******************
     * 3、最后一行原点y坐标加最后一行高度
     ******************/
    heightValue = 0;
    CGFloat line_y = (CGFloat)lineOrigins[CFArrayGetCount(lines)-1].y;  //最后一行line的原点y坐标
    CGFloat lastAscent = 0;//上行行高
    CGFloat lastDescent = 0;//下行行高
    CGFloat lastLeading = 0;//行距
    CTLineRef lastLine = CFArrayGetValueAtIndex(lines, CFArrayGetCount(lines)-1);
    CTLineGetTypographicBounds(lastLine, &lastAscent, &lastDescent, &lastLeading);
    //height - line_y为除去最后一行的字符原点以下的高度，descent + leading为最后一行不包括上行行高的字符高度
    heightValue = height - line_y + (CGFloat)(fabs(lastDescent) + lastLeading);
    heightValue = CGFloat_ceil(heightValue);
//    NSLog(@"3、最后一行原点y坐标加最后一行高度");
//    NSLog(@"heightValue %@",@(heightValue));
    
    CFRelease(textFrame);
    return heightValue;
}

static inline CGSize CTFramesetterSuggestFrameSizeForAttributedStringWithConstraints(CTFramesetterRef framesetter, NSAttributedString *attributedString, CGSize size, NSUInteger numberOfLines) {
    CFRange rangeToSize = CFRangeMake(0, (CFIndex)[attributedString length]);
    CGSize constraints = CGSizeMake(size.width, CJFLOAT_MAX);
    
    if (numberOfLines == 1) {
        // If there is one line, the size that fits is the full width of the line
        constraints = CGSizeMake(CJFLOAT_MAX, CJFLOAT_MAX);
    } else if (numberOfLines > 0) {
        // If the line count of the label more than 1, limit the range to size to the number of lines that have been set
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0.0f, 0.0f, constraints.width, CJFLOAT_MAX));
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
        CFArrayRef lines = CTFrameGetLines(frame);
        
        if (CFArrayGetCount(lines) > 0) {
            NSInteger lastVisibleLineIndex = MIN((CFIndex)numberOfLines, CFArrayGetCount(lines)) - 1;
            CTLineRef lastVisibleLine = CFArrayGetValueAtIndex(lines, lastVisibleLineIndex);
            
            CFRange rangeToLayout = CTLineGetStringRange(lastVisibleLine);
            rangeToSize = CFRangeMake(0, rangeToLayout.location + rangeToLayout.length);
        }
        
        CFRelease(frame);
        CGPathRelease(path);
    }
    
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, rangeToSize, NULL, constraints, NULL);
    
    return CGSizeMake(CGFloat_ceil(suggestedSize.width), CGFloat_ceil(suggestedSize.height));
}
@end
