//
//  CJLabel.m
//  CJLabelTest
//
//  Created by C.K.Lian on 15/12/11.
//  Copyright © 2015年 C.K.Lian. All rights reserved.
//

#import "CJLabel.h"
#import <CoreText/CoreText.h>

@interface CJLabel ()<UIGestureRecognizerDelegate>
@property (nonatomic) CTFrameRef theFrame;
@property (nonatomic) NSRange linkRange;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, strong) UITapGestureRecognizer *labelTapGestureRecognizer;
@end

@implementation CJLabel
@synthesize theFrame = _theFrame;
@synthesize font = _font;

- (void)dealloc {
    
    // The property is marked 'assign', but retain count for this CFType is managed here and via
    // the setter.
    if (NULL != _theFrame) {
        CFRelease(_theFrame);
    }
    self.labelTapGestureRecognizer.delegate = nil;
}

+ (CGFloat)getAttributedStringHeightWithString:(NSAttributedString *)string  width:(CGFloat)width
{
    CGFloat total_value = 0;
    //string 为要计算高的NSAttributedString
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)string);
    //这里的高要设置足够大
    CGRect drawingRect = CGRectMake(0, 0, width, 1000);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, drawingRect);
    CTFrameRef textFrame = CTFramesetterCreateFrame(framesetter,CFRangeMake(0,0), path, NULL);
    CGPathRelease(path);
    CFRelease(framesetter);
    
    NSArray *linesArray = (NSArray *) CTFrameGetLines(textFrame);
    
    CGPoint origins[[linesArray count]];
    CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), origins);
    
    CGFloat line_y = (CGFloat) origins[[linesArray count] -1].y;  //最后一行line的原点y坐标
    
    CGFloat ascent = 0;
    CGFloat descent = 0;
    CGFloat leading = 0;
    
    CTLineRef line = (__bridge CTLineRef) [linesArray objectAtIndex:[linesArray count]-1];
    CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
    
    total_value = 1000 - line_y + (CGFloat) descent + 1;    //+1为了纠正descent转换成int小数点后舍去的值
    
    CFRelease(textFrame);
    return total_value;
}

- (CGSize)getStringRect:(NSAttributedString *)aString width:(CGFloat)width height:(CGFloat)height labelFont:(UIFont *)font
{
    CGSize size = CGSizeZero;
    
    NSMutableAttributedString *atrString = [[NSMutableAttributedString alloc] initWithAttributedString:aString];
    
    NSRange range = NSMakeRange(0, atrString.length);
    
    //获取指定位置上的属性信息，并返回与指定位置属性相同并且连续的字符串的范围信息。
    NSDictionary* dic = [atrString attributesAtIndex:0 effectiveRange:&range];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:dic];
    [attributes setObject:paragraphStyle.copy forKey:NSParagraphStyleAttributeName];
    
    _font = font;
    self.width = width;
    [attributes setObject:font forKey:NSFontAttributeName];
    
    CGSize strSize = [[aString string] boundingRectWithSize:CGSizeMake(width, height)
                                                    options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                 attributes:dic
                                                    context:nil].size;
    
    size = CGSizeMake(ceilf(strSize.width), ceilf(strSize.height));
    
    return  size;
}

+ (NSMutableAttributedString *)getLabelNSAttributedString:(NSString *)labelStr labelDict:(NSDictionary *)labelDic
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
    
    return atrString;
}

+ (NSAttributedString *)handleLinkString:(NSAttributedString *)linkString
{
    if (linkString.length <= 2) {
        return linkString;
    }
    NSAttributedString *handleLinkString = [linkString attributedSubstringFromRange:NSMakeRange(1,linkString.length-2)];
    return handleLinkString;
}

- (void)setTouchUpInsideLinkString:(NSAttributedString *)linkString withString:(NSAttributedString *)string block:(CJLabelBlock)labelBlock
{
    self.userInteractionEnabled = YES;
    self.labelTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(labelTouchUpInside:)];
    self.labelTapGestureRecognizer.delegate = self;
    [self addGestureRecognizer:self.labelTapGestureRecognizer];
    
    self.labelBlock = labelBlock;
    self.linkString = linkString;
    self.string = string;
    
    //点击链接的NSRange
    self.linkRange = [[string string] rangeOfString:[linkString string]];
}

- (void)labelTouchUpInside:(UITapGestureRecognizer *)sender
{
    //获取触摸点击当前view的坐标位置
    CGPoint location = [sender locationInView:self];
    //获取CTFrameRef
    [self setFrameValue:self.string];
    //获取每一行
    CFArrayRef lines = CTFrameGetLines(self.theFrame);
    CGPoint origins[CFArrayGetCount(lines)];
    //获取每行的原点坐标
    CTFrameGetLineOrigins(self.theFrame, CFRangeMake(0, 0), origins);
    CTLineRef line = NULL;
    CGPoint lineOrigin = CGPointZero;
    
    //linkString最后一行字符
    NSAttributedString *linkLastString = nil;
    BOOL isLastLine = NO;
    NSRange lastLineRunRange;
    //最后一行文字的宽度
    CGFloat lastLineWidth = 0;
    
    CFIndex count = CFArrayGetCount(lines);
    for (int i= 0; i < count; i++)
    {
        CGPoint origin = origins[i];
        CGPathRef path = CTFrameGetPath(self.theFrame);
        //获取整个CTFrame的大小
        CGRect rect = CGPathGetBoundingBox(path);
        //坐标转换，把每行的原点坐标转换为UIView的坐标体系
        CGFloat y = rect.origin.y + rect.size.height - origin.y;
        
        //判断点击的位置处于那一行范围内
        if ((location.y <= y) && (location.x >= origin.x))
        {
            line = CFArrayGetValueAtIndex(lines, i);
            lineOrigin = origin;
            
            //如果是最后一行
            if (i == CFArrayGetCount(lines)-1 && CFArrayGetCount(lines)>1) {
                isLastLine = YES;
                CFRange lastRange = CTLineGetStringRange(line);
                lastLineRunRange = NSMakeRange(lastRange.location, lastRange.length);
                linkLastString = [self.string attributedSubstringFromRange:lastLineRunRange];
                lastLineWidth = [[CJLabel new] getStringRect:linkLastString width:MAXFLOAT height:(rect.size.height/CFArrayGetCount(lines)) labelFont:_font].width;
                
//                NSLog(@"linkLastString :%@",[linkLastString string]);
//                NSLog(@"lastLinkLineWidth :%@",@(lastLineWidth));
            }
            break;
        }
        
    }

//    NSLog(@"location:%@ %@",@(location.x),@(location.y));
    
    location.x -= lineOrigin.x;
    //获取点击位置所处的字符位置，就是相当于点击了第几个字符
    CFIndex index = CTLineGetStringIndexForPosition(line, location);
//    NSLog(@"index:%ld",index);
    
    if (index >= self.linkRange.location && index <= self.linkRange.length + self.linkRange.location) {
        if (isLastLine && (location.x > lastLineWidth)) {
//            NSLog(@"点击的是最后一行的空白区域");
            return;
        }
        if (self.labelBlock) {
            self.labelBlock();
        }
    }
    
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (CTFrameRef)setFrameValue:(NSAttributedString *)aString {
    CFAttributedStringRef attributedString = (__bridge CFAttributedStringRef)aString;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attributedString);
    
    if (NULL == framesetter) {
        return NULL;
    }
    
    CGMutablePathRef path = CGPathCreateMutable();
    
    if (NULL == path) {
        CFRelease(framesetter);
        return NULL;
    }
//    NSLog(@"%@", NSStringFromCGRect(self.bounds));
    CGRect bounds = self.bounds;
    bounds.size = [[CJLabel new] getStringRect:aString width:_width height:MAXFLOAT labelFont:_font];
    CGPathAddRect(path, NULL, bounds);
    CTFrameRef linkFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    self.theFrame = linkFrame;
    if (linkFrame) {
        CFRelease(linkFrame);
    }
    CGPathRelease(path);
    CFRelease(framesetter);
    return self.theFrame;
}

- (void)setTheFrame:(CTFrameRef)textFrame {
    // The property is marked 'assign', but retain count for this CFType is managed via this setter
    // and -dealloc.
    if (textFrame != _theFrame) {
        if (NULL != _theFrame) {
            CFRelease(_theFrame);
        }
        if (NULL != textFrame) {
            CFRetain(textFrame);
        }
        _theFrame = textFrame;
    }
}

@end
