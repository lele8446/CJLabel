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
@property (nonatomic, strong) NSMutableArray *linkArray;
@property (nonatomic, strong) UITapGestureRecognizer *labelTapGestureRecognizer;
@end

@implementation CJLabel

- (NSMutableArray *)linkArray {
    if (!_linkArray) {
        _linkArray = [[NSMutableArray alloc]initWithCapacity:4];
    }
    return _linkArray;
}

- (void)dealloc {
    self.labelTapGestureRecognizer.delegate = nil;
    if (self.labelTapGestureRecognizer) {
        [self removeGestureRecognizer:self.labelTapGestureRecognizer];
    }
}

- (CTFrameRef )returnCTFrame {
    
    CFAttributedStringRef attributedString = (__bridge CFAttributedStringRef)self.attributedText;
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(attributedString);
    if (NULL == framesetter) {
        return NULL;
    }
    
    CGMutablePathRef path = CGPathCreateMutable();
    if (NULL == path) {
        CFRelease(framesetter);
        return NULL;
    }
    
    [self sizeToFit];
    CGRect bounds = self.bounds;
    bounds.size = CGSizeMake(ceilf(bounds.size.width), ceilf(bounds.size.height));
    CGPathAddRect(path, NULL, bounds);
    CTFrameRef linkFrame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    CTFrameRef theLinkFrame = linkFrame;
    CFRetain(theLinkFrame);
    if (linkFrame) {
        CFRelease(linkFrame);
    }
    CGPathRelease(path);
    CFRelease(framesetter);
    
    return theLinkFrame;
}

- (void)removeLinkString:(NSAttributedString *)linkString {
    __block NSUInteger index = 0;
    __block BOOL needRemove = NO;
    [self.linkArray enumerateObjectsUsingBlock:^(id num, NSUInteger idx, BOOL *stop){
        CJLinkLabelModel *linkModel = (CJLinkLabelModel *)num;
        if ([linkModel.linkString isEqualToAttributedString:linkString]) {
            index = idx;
            needRemove = YES;
            *stop = YES;
        }
    }];
    [self.linkArray removeObjectAtIndex:index];
}

- (void)addLinkString:(NSAttributedString *)linkString block:(CJLinkLabelModelBlock)linkBlock {
    CJLinkLabelModel *linkModel = [[CJLinkLabelModel alloc]initLinkLabelModelWithString:linkString range:[self getRangeWithLinkString:linkString] block:linkBlock];
    if (nil != linkModel) {
        [self.linkArray addObject:linkModel];
    }
    [self initializeLabelTapGestureRecognizer];
}

- (NSRange)getRangeWithLinkString:(NSAttributedString *)linkString {
    //点击链接的NSRange
    NSRange linkRange = [[self.attributedText string] rangeOfString:[linkString string]];
    return linkRange;
}

- (void)initializeLabelTapGestureRecognizer {
    if (!_labelTapGestureRecognizer) {
        self.userInteractionEnabled = YES;
        _labelTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(labelTouchUpInside:)];
        _labelTapGestureRecognizer.delegate = self;
        [self addGestureRecognizer:_labelTapGestureRecognizer];
    }
}

- (void)labelTouchUpInside:(UITapGestureRecognizer *)sender
{
    //获取触摸点击当前view的坐标位置
    CGPoint location = [sender locationInView:self];
//    NSLog(@"location %@",NSStringFromCGPoint(location));
    
    NSUInteger index = (NSUInteger)[self characterIndexAtPoint:location];
    if (!NSLocationInRange(index, NSMakeRange(0, self.attributedText.length))) {
        return;
    }
    
    [self.linkArray enumerateObjectsUsingBlock:^(id num, NSUInteger idx, BOOL *stop){
        CJLinkLabelModel *linkModel = (CJLinkLabelModel *)num;
        if (NSLocationInRange(index, linkModel.range)) {
            if (linkModel.linkBlock) {
                linkModel.linkBlock(linkModel);
            }
            *stop = YES;
        }
    }];
    
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

static inline CGFLOAT_TYPE CGFloat_ceil(CGFLOAT_TYPE cgfloat) {
#if CGFLOAT_IS_DOUBLE
    return ceil(cgfloat);
#else
    return ceilf(cgfloat);
#endif
}
- (CFIndex)characterIndexAtPoint:(CGPoint)p {
    [self sizeToFit];
    CGRect bounds = self.bounds;
    if (!CGRectContainsPoint(bounds, p)) {
        return NSNotFound;
    }

    CGRect textRect = [self textRectForBounds:bounds limitedToNumberOfLines:self.numberOfLines];
    textRect.size = CGSizeMake(CGFloat_ceil(textRect.size.width), CGFloat_ceil(textRect.size.height));
    if (!CGRectContainsPoint(textRect, p)) {
        return NSNotFound;
    }
    
    // Offset tap coordinates by textRect origin to make them relative to the origin of frame
    p = CGPointMake(p.x - textRect.origin.x, p.y - textRect.origin.y);
    // Convert tap coordinates (start at top left) to CT coordinates (start at bottom left)
    p = CGPointMake(p.x, textRect.size.height - p.y);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, textRect);
    
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
    NSLog(@"点击第%ld个字符",idx);
    return idx;
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

@end

@interface CJLinkLabelModel()

@end

@implementation CJLinkLabelModel

- (instancetype)initLinkLabelModelWithString:(NSAttributedString *)linkString range:(NSRange)range block:(CJLinkLabelModelBlock)linkBlock {
    if ((self = [super init])) {
        _linkBlock = linkBlock;
        _linkString = [linkString copy];
        _range = range;
    }
    return self;
}

@end

