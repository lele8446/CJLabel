//
//  CJLabel.m
//  CJLabelTest
//
//  Created by C.K.Lian on 15/12/11.
//  Copyright © 2015年 C.K.Lian. All rights reserved.
//

#import "CJLabel.h"
#import <CoreText/CoreText.h>
#import <objc/runtime.h>

static inline CGFLOAT_TYPE CGFloat_sqrt(CGFLOAT_TYPE cgfloat) {
#if CGFLOAT_IS_DOUBLE
    return sqrt(cgfloat);
#else
    return sqrtf(cgfloat);
#endif
}

static inline CGFLOAT_TYPE CGFloat_ceil(CGFLOAT_TYPE cgfloat) {
#if CGFLOAT_IS_DOUBLE
    return ceil(cgfloat);
#else
    return ceilf(cgfloat);
#endif
}

static inline CGFloat CJFlushFactorForTextAlignment(NSTextAlignment textAlignment) {
    switch (textAlignment) {
        case NSTextAlignmentCenter:
            return 0.5f;
        case NSTextAlignmentRight:
            return 1.0f;
        case NSTextAlignmentLeft:
        default:
            return 0.0f;
    }
}

@interface CJLabel ()
@property (nonatomic, strong) NSMutableArray *linkArray;
@property (nonatomic, assign) UIEdgeInsets textInsets;//内边距

@end

@implementation CJLabel

- (NSMutableArray *)linkArray {
    if (!_linkArray) {
        _linkArray = [[NSMutableArray alloc]initWithCapacity:4];
    }
    return _linkArray;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _extendsLinkTouchArea = NO;
        _sameLinkEnable = YES;
        self.userInteractionEnabled = YES;
        self.textInsets = UIEdgeInsetsZero;
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    _extendsLinkTouchArea = NO;
    _sameLinkEnable = YES;
    self.userInteractionEnabled = YES;
    self.textInsets = UIEdgeInsetsZero;
}

- (void)dealloc {
    
}

/**
 *  重写drawTextInRect方法调整内边距（未实现）
 */
- (void)drawTextInRect:(CGRect)rect {
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.textInsets)];
}

- (void)removeLinkString:(NSString *)linkString {
    __block NSUInteger index = 0;
    __block BOOL needRemove = NO;
    [self.linkArray enumerateObjectsUsingBlock:^(id num, NSUInteger idx, BOOL *stop){
        CJLinkLabelModel *linkModel = (CJLinkLabelModel *)num;
        if ([linkModel.linkString isEqualToString:linkString]) {
            index = idx;
            needRemove = YES;
            *stop = YES;
        }
    }];
    [self.linkArray removeObjectAtIndex:index];
}

- (void)removeAllLink {
    [self.linkArray removeAllObjects];
}

- (void)addLinkString:(NSString *)linkString linkAddAttribute:(NSDictionary *)linkDic block:(CJLinkLabelModelBlock)linkBlock {
    [self addLinkString:linkString linkAddAttribute:linkDic linkParameter:nil block:linkBlock];
}

- (void)addLinkString:(NSString *)linkString linkAddAttribute:(NSDictionary *)linkDic linkParameter:(id)parameter block:(CJLinkLabelModelBlock)linkBlock {
    NSArray *rangeAry = [self getRangeArrayWithLinkString:linkString inTextString:[self.attributedText string] lastRange:NSMakeRange(0, 0) rangeArray:[NSMutableArray array]];
    NSRange linkRange = [self getFirstRangeWithLinkString:linkString inTextString:[self.attributedText string]];
    NSMutableAttributedString *atrString = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
    
    if (linkDic && linkDic.count > 0 && atrString.length > 0) {
        NSEnumerator *enumerator = [linkDic keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
            if (self.sameLinkEnable) {
                for (NSString *strRange in rangeAry) {
                    [atrString addAttribute:key value:linkDic[key] range:NSRangeFromString(strRange)];
                }
            }else{
                [atrString addAttribute:key value:linkDic[key] range:linkRange];
            }
            
        }
        self.attributedText = atrString;
    }
    
    if (self.sameLinkEnable) {
        for (NSString *strRange in rangeAry) {
            CJLinkLabelModel *linkModel = [[CJLinkLabelModel alloc]initLinkLabelModelWithString:linkString range:NSRangeFromString(strRange) linkParameter:parameter block:linkBlock];
            if (nil != linkModel) {
                [self.linkArray addObject:linkModel];
            }
        }
    }else{
        CJLinkLabelModel *linkModel = [[CJLinkLabelModel alloc]initLinkLabelModelWithString:linkString range:linkRange linkParameter:parameter block:linkBlock];
        if (nil != linkModel) {
            [self.linkArray addObject:linkModel];
        }
    }
}

/**
 *  获取linkString在string中首次出现的NSRange值
 *
 *  @param linkString
 *  @param string
 *
 *  @return
 */
- (NSRange)getFirstRangeWithLinkString:(NSString *)linkString inTextString:(NSString *)string {
    NSRange linkRange = [string rangeOfString:linkString];
    return linkRange;
}

/**
 *  遍历string，获取linkString在string中的所有NSRange数组
 *
 *  @param linkString
 *  @param string
 *  @param lastRange  linkString上一次出现的NSRange值，初始为NSMakeRange(0, 0)
 *  @param array
 *
 *  @return
 */
- (NSArray *)getRangeArrayWithLinkString:(NSString *)linkString
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

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    UITouch * touch = touches.anyObject;
    //获取触摸点击当前view的坐标位置
    CGPoint location = [touch locationInView:self];
//    NSLog(@"location %@",NSStringFromCGPoint(location));
    
    if(![self needResponseTouchLabel:location]) {
        [self.nextResponder touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    [self.nextResponder touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.nextResponder touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    [self.nextResponder touchesCancelled:touches withEvent:event];
}

- (BOOL)needResponseTouchLabel:(CGPoint)location {
    NSUInteger curIndex = (NSUInteger)[self characterIndexAtPoint:location];
    if (!NSLocationInRange(curIndex, NSMakeRange(0, self.attributedText.length))) {
        return NO;
    }
    
    if (self.extendsLinkTouchArea) {
        NSMutableArray *linkIndexAry = [[NSMutableArray alloc]initWithCapacity:4];
        [linkIndexAry addObjectsFromArray:[self linkAtRadius:2.5f aroundPoint:location]];
        [linkIndexAry addObjectsFromArray:[self linkAtRadius:5.0f aroundPoint:location]];
        [linkIndexAry addObjectsFromArray:[self linkAtRadius:7.5f aroundPoint:location]];
        [linkIndexAry addObjectsFromArray:[self linkAtRadius:12.5f aroundPoint:location]];
        [linkIndexAry addObjectsFromArray:[self linkAtRadius:15.0f aroundPoint:location]];
        
        __block BOOL stopFor = NO;
        for (NSNumber *number in linkIndexAry) {
            if (stopFor) {
                return YES;
            }
            [self.linkArray enumerateObjectsUsingBlock:^(id num, NSUInteger idx, BOOL *stop){
                CJLinkLabelModel *linkModel = (CJLinkLabelModel *)num;
                if (NSLocationInRange([number unsignedIntegerValue], linkModel.range)) {
                    if (linkModel.linkBlock) {
                        linkModel.linkBlock(linkModel);
                    }
                    stopFor = YES;
                    *stop = YES;
                }
            }];
        }
        return NO;
    }else{
        __block BOOL needResponse = NO;
        [self.linkArray enumerateObjectsUsingBlock:^(id num, NSUInteger idx, BOOL *stop){
            CJLinkLabelModel *linkModel = (CJLinkLabelModel *)num;
            if (NSLocationInRange(curIndex, linkModel.range)) {
                if (linkModel.linkBlock) {
                    linkModel.linkBlock(linkModel);
                }
                needResponse = YES;
                *stop = YES;
            }
        }];
        if (needResponse) {
            return YES;
        }else{
            return NO;
        }
    }
}

- (NSArray *)linkAtRadius:(const CGFloat)radius aroundPoint:(CGPoint)point {
    NSMutableArray *linkIndexAry = [[NSMutableArray alloc]initWithCapacity:4];
    const CGFloat diagonal = CGFloat_sqrt(2 * radius * radius);
    const CGPoint deltas[] = {
        CGPointMake(0, -radius), CGPointMake(0, radius), // Above and below
        CGPointMake(-radius, 0), CGPointMake(radius, 0), // Beside
        CGPointMake(-diagonal, -diagonal), CGPointMake(-diagonal, diagonal),
        CGPointMake(diagonal, diagonal), CGPointMake(diagonal, -diagonal) // Diagonal
    };
    const size_t count = sizeof(deltas) / sizeof(CGPoint);
    
    for (NSInteger i = 0; i < count; i ++) {
        CGPoint currentPoint = CGPointMake(point.x + deltas[i].x, point.y + deltas[i].y);
        NSUInteger index = (NSUInteger)[self characterIndexAtPoint:currentPoint];
        [linkIndexAry addObject:[NSNumber numberWithUnsignedInteger:index]];
    }
    
    return linkIndexAry;
}

- (CFIndex)characterIndexAtPoint:(CGPoint)p {
    CGRect bounds = self.bounds;
    if (!CGRectContainsPoint(bounds, p)) {
        return NSNotFound;
    }
    
    CGRect textRect = [self textRectForBounds:bounds limitedToNumberOfLines:self.numberOfLines];
    textRect.size = CGSizeMake(CGFloat_ceil(textRect.size.width), CGFloat_ceil(textRect.size.height));
    //textRect的height值存在误差，值需设大一点，不然不会包含最后一行lines
    CGRect pathRect = CGRectMake(textRect.origin.x, textRect.origin.y, textRect.size.width, textRect.size.height+ 100000);
    if (!CGRectContainsPoint(textRect, p)) {
        return NSNotFound;
    }
    
    // Offset tap coordinates by textRect origin to make them relative to the origin of frame
    p = CGPointMake(p.x - textRect.origin.x, p.y - textRect.origin.y);
    // Convert tap coordinates (start at top left) to CT coordinates (start at bottom left)
    // p.x-5 是因为测试发现x轴坐标有偏移误差
    p = CGPointMake(p.x-5, pathRect.size.height - p.y);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, pathRect);
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.attributedText);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, (CFIndex)[self.attributedText length]), path, NULL);
    
    if (frame == NULL) {
        CGPathRelease(path);
        return NSNotFound;
    }
    
    CFArrayRef lines = CTFrameGetLines(frame);
    NSInteger numberOfLines = self.numberOfLines > 0 ? MIN(self.numberOfLines, CFArrayGetCount(lines)) : CFArrayGetCount(lines);
    if (numberOfLines == 0) {
        CFRelease(frame);
        CGPathRelease(path);
        return NSNotFound;
    }
    
    CFIndex idx = NSNotFound;
    
    CGPoint lineOrigins[numberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, numberOfLines), lineOrigins);
    
    for (CFIndex lineIndex = 0; lineIndex < numberOfLines; lineIndex++) {
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        
        // Get bounding information of line
        CGFloat ascent = 0.0f, descent = 0.0f, leading = 0.0f;
        CGFloat width = (CGFloat)CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        CGFloat yMin = (CGFloat)floor(lineOrigin.y - descent);
        CGFloat yMax = (CGFloat)ceil(lineOrigin.y + ascent);
        
        // Apply penOffset using flushFactor for horizontal alignment to set lineOrigin since this is the horizontal offset from drawFramesetter
        CGFloat flushFactor = CJFlushFactorForTextAlignment(self.textAlignment);
        CGFloat penOffset = (CGFloat)CTLineGetPenOffsetForFlush(line, flushFactor, textRect.size.width);
        lineOrigin.x = penOffset;
        
        // Check if we've already passed the line
        if (p.y > yMax) {
            break;
        }
        // Check if the point is within this line vertically
        if (p.y >= yMin) {
            // Check if the point is within this line horizontally
            if (p.x >= lineOrigin.x && p.x <= lineOrigin.x + width) {
                // Convert CT coordinates to line-relative coordinates
                CGPoint relativePoint = CGPointMake(p.x - lineOrigin.x, p.y - lineOrigin.y);
                idx = CTLineGetStringIndexForPosition(line, relativePoint);
                break;
            }
        }
    }
    
    CFRelease(frame);
    CGPathRelease(path);
//    NSLog(@"点击第%ld个字符",idx);
    return idx;
}
@end

@interface CJLinkLabelModel()

@end

@implementation CJLinkLabelModel
- (instancetype)initLinkLabelModelWithString:(NSString *)linkString range:(NSRange)range linkParameter:(id)parameter block:(CJLinkLabelModelBlock)linkBlock {
    if ((self = [super init])) {
        _linkBlock = linkBlock;
        _linkString = [linkString copy];
        _range = range;
        _parameter = parameter;
    }
    return self;
}

@end
