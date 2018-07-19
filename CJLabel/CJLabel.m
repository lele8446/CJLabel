//
//  CJLabel.m
//  CJLabelTest
//
//  Created by ChiJinLian on 17/3/31.
//  Copyright © 2017年 ChiJinLian. All rights reserved.
//

#import "CJLabel.h"
#import <objc/runtime.h>

@class CJGlyphRunStrokeItem;
@class CJSelectView;

NSString * const kCJBackgroundFillColorAttributeName         = @"kCJBackgroundFillColor";
NSString * const kCJBackgroundStrokeColorAttributeName       = @"kCJBackgroundStrokeColor";
NSString * const kCJBackgroundLineWidthAttributeName         = @"kCJBackgroundLineWidth";
NSString * const kCJBackgroundLineCornerRadiusAttributeName  = @"kCJBackgroundLineCornerRadius";
NSString * const kCJActiveBackgroundFillColorAttributeName   = @"kCJActiveBackgroundFillColor";
NSString * const kCJActiveBackgroundStrokeColorAttributeName = @"kCJActiveBackgroundStrokeColor";
NSString * const kCJStrikethroughStyleAttributeName          = @"kCJStrikethroughStyleAttributeName";
NSString * const kCJStrikethroughColorAttributeName          = @"kCJStrikethroughColorAttributeName";

NSString * const kCJLinkStringIdentifierAttributesName       = @"kCJLinkStringIdentifierAttributesName";

@interface CJCTRunUrl: NSURL
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) NSValue *rangeValue;
@end

@implementation CJCTRunUrl

@end


@interface CJLabel ()<UIGestureRecognizerDelegate>

//当前显示的AttributedText
@property (nonatomic, copy) NSAttributedString *renderedAttributedText;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;//长按手势
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGes;//双击手势
/**
 是否需要计算支持复制的每个字符的frame大小
 */
@property (nonatomic, assign) BOOL caculateCopySize;
/**
 不需要显示，只是用来计算label的size
 */
@property (nonatomic, assign) BOOL caculateSizeOnly;
/**
 支持复制时计算每一个CTRun的frame完成后的block
 */
@property (nonatomic, copy) void(^caculateCTRunSizeBlock)(void);
@end

@implementation CJLabel {
@private
    id _text;
    NSAttributedString *_attributedText;
    BOOL _needsFramesetter;
    NSInteger _textNumberOfLines;
    CTFramesetterRef _framesetter;
    CTFramesetterRef _highlightFramesetter;
    CGFloat _yOffset;
    BOOL _longPress;//判断是否长按;
    BOOL _needRedrawn;//是否需要重新计算_CTLineVerticalLayoutArray以及_linkStrokeItemArray数组
    NSMutableArray <CJGlyphRunStrokeItem *>*_linkStrokeItemArray;//可点击链点的StrokeItem数组
    CJGlyphRunStrokeItem *_lastGlyphRunStrokeItem;//计算StrokeItem的中间变量
    CJGlyphRunStrokeItem *_currentClickRunStrokeItem;//当前点击选中的StrokeItem
    NSArray <CJCTLineLayoutModel *>*_CTLineVerticalLayoutArray;//记录 所有CTLine在垂直方向的对齐方式的数组
    CGFloat _translateCTMty;//坐标系统反转后的偏移量
    CGRect _insetRect;//实际绘制文本区域大小
    NSMutableArray <CJGlyphRunStrokeItem *>*_allRunItemArray;//enableCopy=YES时，包含所有CTRun信息的数组
    CGFloat _lineVerticalMaxWidth;//每一行文字中的最大宽度
    BOOL _afterLongPressEnd;//用于判断长按复制判断
}

@dynamic text;
@dynamic attributedText;
//@synthesize text = _text;
//@synthesize attributedText = _attributedText;

#pragma mark - Life cycle
- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.userInteractionEnabled = YES;
    _textInsets = UIEdgeInsetsZero;
    
    _verticalAlignment = CJVerticalAlignmentCenter;
    _textNumberOfLines = -1;
    _caculateCopySize = NO;
    _needRedrawn = YES;
    _longPress = NO;
    _extendsLinkTouchArea = NO;
    _lastGlyphRunStrokeItem = nil;
    _linkStrokeItemArray = [NSMutableArray arrayWithCapacity:3];
    _allRunItemArray = [NSMutableArray arrayWithCapacity:3];
    _currentClickRunStrokeItem = nil;
    _CTLineVerticalLayoutArray = nil;
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureDidFire:)];
    _longPressGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_longPressGestureRecognizer];
    
    _enableCopy = NO;
    _caculateCTRunSizeBlock = nil;
}

- (void)dealloc {
    if (_framesetter) {
        CFRelease(_framesetter);
    }
    
    if (_highlightFramesetter) {
        CFRelease(_highlightFramesetter);
    }
    
    if (_longPressGestureRecognizer) {
        [self removeGestureRecognizer:_longPressGestureRecognizer];
    }
    if (_doubleTapGes) {
        [self removeGestureRecognizer:_doubleTapGes];
    }
    _delegate = nil;
}

- (void)setVerticalAlignment:(CJLabelVerticalAlignment)verticalAlignment {
    _verticalAlignment = verticalAlignment;
    [self flushText];
}

- (void)setEnableCopy:(BOOL)enableCopy {
    _enableCopy = enableCopy;
    if (_enableCopy) {
        self.doubleTapGes =[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTwoAct:)];
        self.doubleTapGes.numberOfTapsRequired = 2;
        self.doubleTapGes.delegate = self;
        [self addGestureRecognizer:self.doubleTapGes];
        
        if (_allRunItemArray.count == 0) {
            self.caculateCopySize = YES;
            self.attributedText = self.attributedText;
        }
        
    }
}

- (void)setText:(id)text {
    NSParameterAssert(!text || [text isKindOfClass:[NSAttributedString class]] || [text isKindOfClass:[NSString class]]);
    
    NSMutableAttributedString *mutableAttributedString = nil;
    if ([text isKindOfClass:[NSString class]]) {
        NSMutableDictionary *mutableAttributes = [NSMutableDictionary dictionary];
        [mutableAttributes setObject:self.font?self.font:[UIFont systemFontOfSize:17] forKey:(NSString *)kCTFontAttributeName];
        [mutableAttributes setObject:self.textColor?self.textColor:[UIColor blackColor] forKey:(NSString *)kCTForegroundColorAttributeName];
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = self.textAlignment;
        [mutableAttributes setObject:paragraphStyle forKey:(NSString *)kCTParagraphStyleAttributeName];
        mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:mutableAttributes];
    }else{
        mutableAttributedString = text;
    }
    
    self.attributedText = mutableAttributedString;
    _text = mutableAttributedString.string;
}

- (id)text {
    return _text;
}

- (void)setAttributedText:(NSAttributedString *)text {
    if (text == nil) {
        return;
    }
    //不需要计算支持复制的每个字符的frame大小
    if (!self.caculateCopySize) {
        if ([text isEqualToAttributedString:_attributedText]) {
            return;
        }
    }else{
        if (![text isEqualToAttributedString:_attributedText]) {
            self.caculateCopySize = NO;
        }
    }
    
    _needRedrawn = YES;
    _longPress = NO;
    [_linkStrokeItemArray removeAllObjects];
    _CTLineVerticalLayoutArray = nil;
    _currentClickRunStrokeItem = nil;
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc]initWithAttributedString:text];
    unichar spacingChar = 0xFFFC;
    NSString *spacingCharString = [NSString stringWithCharacters:&spacingChar length:1];
    //空白占位符
    NSAttributedString *placeholderStr = [[NSAttributedString alloc]initWithString:spacingCharString];
    [str appendAttributedString:placeholderStr];
    
    NSMutableAttributedString *attText = [[NSMutableAttributedString alloc]initWithAttributedString:str];
    
    __block BOOL needEnumerateAllCharacter = NO;
    if (!self.caculateSizeOnly) {
        __block NSRange linkRange = NSMakeRange(0, 0);
        __block NSUInteger oldLinkIdentifier = 0;
        [attText enumerateAttributesInRange:NSMakeRange(0, attText.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary<NSString *, id> *attrs, NSRange range, BOOL *stop){
            
            BOOL isLink = [attrs[kCJIsLinkAttributesName] boolValue];
            if (isLink) {
                NSInteger linkLength = [attrs[kCJLinkLengthAttributesName] integerValue];
                NSUInteger linkIdentifier = [attrs[kCJLinkIdentifierAttributesName] unsignedIntegerValue];
                //不同的链点
                if (oldLinkIdentifier != linkIdentifier) {
                    oldLinkIdentifier = linkIdentifier;
                    linkRange = NSMakeRange(range.location, linkLength);
                }
                //相同的链点
                else{
                    linkRange = NSMakeRange(linkRange.location, linkLength);
                }
                [attText addAttribute:kCJLinkRangeAttributesName value:NSStringFromRange(linkRange) range:range];
            }else{
                linkRange = NSMakeRange(0, 0);
                [attText removeAttribute:kCJLinkRangeAttributesName range:range];
            }
            
            //当text包含图片，标记拆分每个CTRun，以便在绘制时候能够准确实现居中、居上、居下对齐
            NSDictionary *imgInfoDic = attrs[kCJImageAttributeName];
            if (!CJLabelIsNull(imgInfoDic)) {
                needEnumerateAllCharacter = YES;
            }
            
        }];
    }
    
    if (!self.caculateSizeOnly && self.enableCopy) {
        if (needEnumerateAllCharacter) {
            self.caculateCopySize = YES;
        }
        if (self.caculateCopySize) {
            //给每一个字符设置index值，enableCopy=YES时用到
            __block NSInteger index = 0;
            
            [attText.string enumerateSubstringsInRange:NSMakeRange(0, [attText length]) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
             ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                 CJCTRunUrl *runUrl = nil;
                 if (!runUrl) {
                     NSString *urlStr = [NSString stringWithFormat:@"https://www.CJLabel%@",@(index)];
                     runUrl = [CJCTRunUrl URLWithString:urlStr];
                 }
                 runUrl.index = index;
                 runUrl.rangeValue = [NSValue valueWithRange:substringRange];
                 [attText addAttribute:NSLinkAttributeName
                                 value:runUrl
                                 range:substringRange];
                 index++;
             }];
            [_allRunItemArray removeAllObjects];
        }
    }
    
    _attributedText = [attText copy];
    
    [self setNeedsFramesetter];
    [self setNeedsDisplay];
    if ([self respondsToSelector:@selector(invalidateIntrinsicContentSize)]) {
        [self invalidateIntrinsicContentSize];
    }
}

- (NSAttributedString *)attributedText {
    return _attributedText;
}

- (NSAttributedString *)renderedAttributedText {
    if (!_renderedAttributedText) {
        NSMutableAttributedString *fullString = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
        
        [fullString enumerateAttributesInRange:NSMakeRange(0, fullString.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary<NSString *, id> *attrs, NSRange range, BOOL *stop){
            //如果有设置linkAttributes，则读取并设置
            NSDictionary *linkAttributes = attrs[kCJLinkAttributesName];
            if (!CJLabelIsNull(linkAttributes)) {
                [fullString addAttributes:linkAttributes range:range];
            }
            
            //如果只需要计算label的size，就不用再判断activeLinkAttributes属性了
            if (!self.caculateSizeOnly) {
                //如果有设置activeLinkAttributes，且正在点击当前链点，则读取并设置
                NSDictionary *activeLinkAttributes = attrs[kCJActiveLinkAttributesName];
                if (!CJLabelIsNull(activeLinkAttributes)) {
                    //设置当前点击链点的activeLinkAttributes属性
                    if (_currentClickRunStrokeItem) {
                        NSInteger clickRunItemRange = _currentClickRunStrokeItem.range.location + _currentClickRunStrokeItem.range.length;
                        if (range.location >= _currentClickRunStrokeItem.range.location && (range.location+range.length) <= clickRunItemRange) {
                            [fullString addAttributes:activeLinkAttributes range:range];
                        }
                    }else{
                        for (NSString *key in activeLinkAttributes) {
                            [fullString removeAttribute:key range:range];
                        }
                        //防止将linkAttributes中的属性也删除了
                        if (!CJLabelIsNull(linkAttributes)) {
                            [fullString addAttributes:linkAttributes range:range];
                        }
                    }
                }
            }
            
        }];
        
        NSAttributedString *string = [[NSAttributedString alloc] initWithAttributedString:fullString];
        self.renderedAttributedText = string;
    }
    
    return _renderedAttributedText;
}

- (void)setNeedsFramesetter {
    self.renderedAttributedText = nil;
    _needsFramesetter = YES;
    
    [_linkStrokeItemArray removeAllObjects];
    _CTLineVerticalLayoutArray = nil;
    _textNumberOfLines = -1;
    _needRedrawn = YES;
    [[CJSelectCopyManagerView instance] hideView];
}

- (CTFramesetterRef)framesetter {
    if (_needsFramesetter) {
        @synchronized(self) {
            CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.renderedAttributedText);
            [self setFramesetter:framesetter];
            [self setHighlightFramesetter:nil];
            _needsFramesetter = NO;
            
            if (framesetter) {
                CFRelease(framesetter);
            }
        }
    }
    
    return _framesetter;
}

- (void)setFramesetter:(CTFramesetterRef)framesetter {
    if (framesetter) {
        CFRetain(framesetter);
    }
    
    if (_framesetter) {
        CFRelease(_framesetter);
    }
    
    _framesetter = framesetter;
}

- (CTFramesetterRef)highlightFramesetter {
    return _highlightFramesetter;
}

- (void)setHighlightFramesetter:(CTFramesetterRef)highlightFramesetter {
    if (highlightFramesetter) {
        CFRetain(highlightFramesetter);
    }
    
    if (_highlightFramesetter) {
        CFRelease(_highlightFramesetter);
    }
    
    _highlightFramesetter = highlightFramesetter;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}

- (UIColor *)textColor {
    UIColor *color = [super textColor];
    if (!color) {
        color = [UIColor blackColor];
    }
    return color;
}

- (void)setTextColor:(UIColor *)textColor {
    UIColor *oldTextColor = self.textColor;
    [super setTextColor:textColor];
    if (textColor != oldTextColor) {
        [self setNeedsFramesetter];
        [self setNeedsDisplay];
    }
}
#pragma mark - UILabel
- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines {
    bounds = UIEdgeInsetsInsetRect(bounds, self.textInsets);
    if (!self.attributedText) {
        return [super textRectForBounds:bounds limitedToNumberOfLines:numberOfLines];
    }
    
    CGRect textRect = bounds;
    
    // 确保高度至少为字体lineHeight的两倍，以确保当textRect高度不足时，CTFramesetterSuggestFrameSizeWithConstraints不返回CGSizeZero。
    textRect.size.height = MAX(self.font.lineHeight * MAX(2, numberOfLines), bounds.size.height);
    
    // 垂直方向的对齐方式
    CGSize textSize = CTFramesetterSuggestFrameSizeWithConstraints([self framesetter], CFRangeMake(0, (CFIndex)[self.attributedText length]), NULL, textRect.size, NULL);
    textSize = CGSizeMake(CGFloat_ceil(textSize.width), CGFloat_ceil(textSize.height)); // Fix for iOS 4, CTFramesetterSuggestFrameSizeWithConstraints sometimes returns fractional sizes
    
    _yOffset = 0.0f;
    if (textSize.height < bounds.size.height) {
        _yOffset = 0.0f;
        switch (self.verticalAlignment) {
            case CJVerticalAlignmentCenter:
                _yOffset = CGFloat_floor((bounds.size.height - textSize.height) / 2.0f);
                break;
            case CJVerticalAlignmentBottom:
                _yOffset = bounds.size.height - textSize.height;
                break;
            case CJVerticalAlignmentTop:
            default:
                break;
        }
        textRect.origin.y += _yOffset;
    }
    
    return textRect;
}

- (void)drawTextInRect:(CGRect)rect {
    CGRect insetRect = UIEdgeInsetsInsetRect(rect, self.textInsets);
    if (!self.attributedText) {
        [super drawTextInRect:insetRect];
        return;
    }
    
    NSAttributedString *originalAttributedText = nil;
    
    // 根据font size调整宽度
    if (self.adjustsFontSizeToFitWidth && self.numberOfLines > 0) {
        [self setNeedsFramesetter];
        [self setNeedsDisplay];
        
        if ([self respondsToSelector:@selector(invalidateIntrinsicContentSize)]) {
            [self invalidateIntrinsicContentSize];
        }
        
        //设置最大size
        CGSize maxSize = (self.numberOfLines > 1) ? CGSizeMake(CJFLOAT_MAX, CJFLOAT_MAX) : CGSizeZero;
        
        CGFloat textWidth = [self sizeThatFits:maxSize].width;
        CGFloat availableWidth = self.frame.size.width * self.numberOfLines;
        if (self.numberOfLines > 1 && self.lineBreakMode == NSLineBreakByWordWrapping) {
            textWidth *= (M_PI / M_E);
        }
        
        if (textWidth > availableWidth && textWidth > 0.0f) {
            originalAttributedText = [self.attributedText copy];
            
            CGFloat scaleFactor = availableWidth / textWidth;
            if ([self respondsToSelector:@selector(minimumScaleFactor)] && self.minimumScaleFactor > scaleFactor) {
                scaleFactor = self.minimumScaleFactor;
            }
            self.attributedText = NSAttributedStringByScalingFontSize(self.attributedText, scaleFactor);
        }
    }
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    // 先将当前图形状态推入堆栈
    CGContextSaveGState(c);
    {
        // 设置字形变换矩阵为CGAffineTransformIdentity，也就是说每一个字形都不做图形变换
        CGContextSetTextMatrix(c, CGAffineTransformIdentity);
        
        // 坐标转换，iOS 坐标原点在左上角，Mac OS 坐标原点在左下角
        CGContextTranslateCTM(c, 0.0f, insetRect.size.height);
        CGContextScaleCTM(c, 1.0f, -1.0f);
        
        CFRange textRange = CFRangeMake(0, (CFIndex)[self.attributedText length]);
        
        // 获取textRect
        CGRect textRect = [self textRectForBounds:rect limitedToNumberOfLines:self.numberOfLines];
        _insetRect = insetRect;
        // CTM 坐标移到左下角
        _translateCTMty = insetRect.size.height - textRect.origin.y - textRect.size.height;
        CGContextTranslateCTM(c, insetRect.origin.x, _translateCTMty);
        
        // 处理阴影 shadowColor
        if (self.shadowColor && !self.highlighted) {
            CGContextSetShadowWithColor(c, self.shadowOffset, self.shadowRadius, [self.shadowColor CGColor]);
        }
        
        if (self.highlightedTextColor && self.highlighted) {
            NSMutableAttributedString *highlightAttributedString = [self.renderedAttributedText mutableCopy];
            [highlightAttributedString addAttribute:(__bridge NSString *)kCTForegroundColorAttributeName value:(id)[self.highlightedTextColor CGColor] range:NSMakeRange(0, highlightAttributedString.length)];
            
            if (![self highlightFramesetter]) {
                CTFramesetterRef highlightFramesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)highlightAttributedString);
                [self setHighlightFramesetter:highlightFramesetter];
                CFRelease(highlightFramesetter);
            }
            
            [self drawFramesetter:[self highlightFramesetter] attributedString:highlightAttributedString textRange:textRange inRect:textRect context:c];
        } else {
            [self drawFramesetter:[self framesetter] attributedString:self.renderedAttributedText textRange:textRange inRect:textRect context:c];
        }
        
        // 判断是否调整了size，如果是，则还原 attributedText
        if (originalAttributedText) {
            _attributedText = originalAttributedText;
        }
    }
    
    CGContextRestoreGState(c);
    _needRedrawn = NO;
    self.caculateCopySize = NO;
    if (self.caculateCTRunSizeBlock) {
        self.caculateCTRunSizeBlock();
    }
    self.caculateCTRunSizeBlock = nil;
    
}

#pragma mark - Draw Method
- (void)drawFramesetter:(CTFramesetterRef)framesetter
       attributedString:(NSAttributedString *)attributedString
              textRange:(CFRange)textRange
                 inRect:(CGRect)rect
                context:(CGContextRef)c
{
    UIView *insertBackView = [self viewWithTag:[kCJInsertBackViewTag hash]];
    if (insertBackView) {
        [insertBackView removeFromSuperview];
    }
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rect);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, textRange, path, NULL);
    
    CFArrayRef lines = CTFrameGetLines(frame);
    if (_textNumberOfLines == -1) {
        _textNumberOfLines = self.numberOfLines > 0 ? MIN(self.numberOfLines, CFArrayGetCount(lines)) : CFArrayGetCount(lines);
    }
    
    BOOL truncateLastLine = (self.lineBreakMode == NSLineBreakByTruncatingHead || self.lineBreakMode == NSLineBreakByTruncatingMiddle || self.lineBreakMode == NSLineBreakByTruncatingTail);
    
    CGPoint lineOrigins[_textNumberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, _textNumberOfLines), lineOrigins);
    
    if (_needRedrawn) {
        //记录 所有CTLine在垂直方向的对齐方式的数组
        _CTLineVerticalLayoutArray = [self allCTLineVerticalLayoutArray:lines origins:lineOrigins inRect:rect context:c textRange:textRange attributedString:attributedString truncateLastLine:truncateLastLine];
    }
    
    // 根据水平对齐方式调整偏移量
    CGFloat flushFactor = CJFlushFactorForTextAlignment(self.textAlignment);
    
    CFIndex count =  CFArrayGetCount(lines);
    for (CFIndex lineIndex = 0; lineIndex < MIN(_textNumberOfLines,count); lineIndex++) {
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CGContextSetTextPosition(c, lineOrigin.x, lineOrigin.y);
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        
        CGFloat lineAscent = 0.0f, lineDescent = 0.0f, lineLeading = 0.0f;
        CGFloat lineWidth = CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
        
        CJCTLineLayoutModel *lineLayoutModel = _CTLineVerticalLayoutArray[lineIndex];
        
        if (lineIndex == _textNumberOfLines-1 && truncateLastLine) {
            
            CTLineRef lastLine = [self handleLastCTLine:line textRange:textRange attributedString:attributedString rect:rect context:c];
            //当前最后一行的宽度
            lineWidth = CTLineGetTypographicBounds(lastLine, &lineAscent, &lineDescent, &lineLeading);
            CGFloat penOffset = (CGFloat)CTLineGetPenOffsetForFlush(lastLine, flushFactor, rect.size.width);
            
            [self drawCTLine:lastLine lineIndex:lineIndex origin:lineOrigin context:c lineAscent:lineAscent lineDescent:lineDescent lineLeading:lineLeading lineWidth:lineWidth rect:rect penOffsetX:penOffset lineLayoutModel:lineLayoutModel];
            
            CFRelease(lastLine);
        }
        else {
            
            CGFloat penOffset = (CGFloat)CTLineGetPenOffsetForFlush(line, flushFactor, rect.size.width);
            [self drawCTLine:line lineIndex:lineIndex origin:lineOrigin context:c lineAscent:lineAscent lineDescent:lineDescent lineLeading:lineLeading lineWidth:lineWidth rect:rect penOffsetX:penOffset lineLayoutModel:lineLayoutModel];
        }
    }
    
    CFRelease(frame);
    CGPathRelease(path);
}
//处理最后一行CTLine
- (CTLineRef)handleLastCTLine:(CTLineRef)line textRange:(CFRange)textRange attributedString:(NSAttributedString *)attributedString rect:(CGRect)rect context:(CGContextRef)c {
    // 判断最后一行是否占满整行
    CFRange lastLineRange = CTLineGetStringRange(line);
    
    BOOL needTruncation = (!(lastLineRange.length == 0 && lastLineRange.location == 0) && lastLineRange.location + lastLineRange.length < textRange.location + textRange.length);
    
    if (needTruncation) {
        
        CTLineTruncationType truncationType;
        CFIndex truncationAttributePosition = lastLineRange.location;
        NSLineBreakMode lineBreakMode = self.lineBreakMode;
        
        switch (lineBreakMode) {
            case NSLineBreakByTruncatingHead:
                truncationType = kCTLineTruncationStart;
                break;
            case NSLineBreakByTruncatingMiddle:
                truncationType = kCTLineTruncationMiddle;
                truncationAttributePosition += (lastLineRange.length / 2);
                break;
            case NSLineBreakByTruncatingTail:
            default:
                truncationType = kCTLineTruncationEnd;
                truncationAttributePosition += (lastLineRange.length - 1);
                break;
        }
        
        NSDictionary *truncationTokenStringAttributes = [attributedString attributesAtIndex:(NSUInteger)truncationAttributePosition effectiveRange:NULL];
        
        NSMutableAttributedString *attributedTruncationString = [[NSMutableAttributedString alloc]init];
        if (!self.attributedTruncationToken) {
            NSString *truncationTokenString = @"\u2026"; // \u2026 对应"…"的Unicode编码
            attributedTruncationString = [[NSMutableAttributedString alloc] initWithString:truncationTokenString attributes:truncationTokenStringAttributes];
        }else{
            NSDictionary *attributedTruncationTokenAttributes = [self.attributedTruncationToken attributesAtIndex:(NSUInteger)0 effectiveRange:NULL];
            [attributedTruncationString appendAttributedString:self.attributedTruncationToken];
            if (attributedTruncationTokenAttributes.count == 0) {
                [attributedTruncationString addAttributes:truncationTokenStringAttributes range:NSMakeRange(0, attributedTruncationString.length)];
            }
        }
        
        CTLineRef truncationToken = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attributedTruncationString);
        
        NSUInteger lenght = lastLineRange.length;
        if (lineBreakMode == NSLineBreakByTruncatingHead || lineBreakMode == NSLineBreakByTruncatingMiddle) {
            lenght = attributedString.length - lastLineRange.location;
        }
        NSAttributedString *lastStr = [attributedString attributedSubstringFromRange:NSMakeRange((NSUInteger)lastLineRange.location,MIN(attributedString.length-lastLineRange.location, lenght))];
        // 获取最后一行的NSAttributedString
        NSMutableAttributedString *truncationString = [[NSMutableAttributedString alloc] initWithAttributedString:lastStr];
        if (lastLineRange.length > 0) {
            // 判断最后一行的最后是不是完整单词，避免出现 "…" 前面是一个不完整单词的情况
            unichar lastCharacter = [[truncationString string] characterAtIndex:(NSUInteger)(MIN(lastLineRange.length - 1, truncationString.length -1))];
            if ([[NSCharacterSet newlineCharacterSet] characterIsMember:lastCharacter]) {
                [truncationString deleteCharactersInRange:NSMakeRange((NSUInteger)(lastLineRange.length - 1), 1)];
            }
        }
        
        NSInteger lastLineLength = truncationString.length;
        switch (lineBreakMode) {
            case NSLineBreakByTruncatingHead:
                [truncationString insertAttributedString:attributedTruncationString atIndex:0];
                break;
            case NSLineBreakByTruncatingMiddle:
                [truncationString insertAttributedString:attributedTruncationString atIndex:lastLineLength/2.0];
                break;
            case NSLineBreakByTruncatingTail:
            default:
                [truncationString appendAttributedString:attributedTruncationString];
                break;
        }
        
        CTLineRef truncationLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncationString);
        
        // 截取CTLine，以防其过长
        CTLineRef truncatedLine = CTLineCreateTruncatedLine(truncationLine, rect.size.width, truncationType, truncationToken);
        if (!truncatedLine) {
            // 不存在，则取truncationToken
            truncatedLine = CFRetain(truncationToken);
        }
        
        CTLineRef lastLine = CFRetain(truncatedLine);
        
        CFRelease(truncatedLine);
        CFRelease(truncationLine);
        CFRelease(truncationToken);
        
        return lastLine;
    }
    else{
        CTLineRef lastLine = CFRetain(line);
        return lastLine;
    }
}
//绘制CTLine
- (void)drawCTLine:(CTLineRef)line
         lineIndex:(CFIndex)lineIndex
            origin:(CGPoint)lineOrigin
           context:(CGContextRef)c
        lineAscent:(CGFloat)lineAscent
       lineDescent:(CGFloat)lineDescent
       lineLeading:(CGFloat)lineLeading
         lineWidth:(CGFloat)lineWidth
              rect:(CGRect)rect
        penOffsetX:(CGFloat)penOffsetX
   lineLayoutModel:(CJCTLineLayoutModel *)lineLayoutModel
{
    //计算当前行的CJCTLineVerticalLayout 结构体
    CJCTLineVerticalLayout lineVerticalLayout = lineLayoutModel.lineVerticalLayout;
    
    CGFloat selectCopyBackY = lineVerticalLayout.lineRect.origin.y;
    CGFloat selectCopyBackHeight = lineVerticalLayout.lineRect.size.height;
    CGFloat selectCopyHeightDif = 0;
    
    //当前行的所有CTRunItem数组
    NSMutableArray *lineRunItems = [self lineRunItemsFromCTLineRef:line lineIndex:lineIndex lineOrigin:lineOrigin inRect:rect context:c lineAscent:lineAscent lineDescent:lineDescent lineLeading:lineLeading lineWidth:lineWidth lineVerticalLayout:lineVerticalLayout];
    
    //需要计算复制数组，则添加
    if (self.enableCopy && self.caculateCopySize) {
        [_allRunItemArray addObjectsFromArray:lineRunItems];
    }
    //当前行对 需要点击，填充背景色，添加删除线的CTRunItem合并后的数组
    NSArray *lineStrokrArray = [self mergeLineSameStrokePathItems:lineRunItems ascentAndDescent:(lineAscent + fabs(lineDescent))];
    
    //获取点击链点对应的数组
    for (CJGlyphRunStrokeItem *runItem in lineStrokrArray) {
        if (runItem.isLink) {
            [_linkStrokeItemArray addObject:runItem];
        }
    }
    
    //填充背景色
    if (!self.caculateSizeOnly) {
        [self drawBackgroundColor:c runStrokeItems:lineStrokrArray isStrokeColor:NO];
    }
    
    //绘制文字、图片
    for (CJGlyphRunStrokeItem *runItem in lineRunItems) {
        CGRect runBounds = runItem.runBounds;
        //y轴方向的偏移
        //此时在Y轴方向是以基线标准对齐的，所以忽略每个CTRun的下行高runDescent
        if (!runItem.isInsertView) {
            runBounds.origin.y = runItem.runBounds.origin.y + runItem.runDescent;
        }
        
        //绘制view
        if (runItem.isInsertView) {
            UIImage *image = nil;
            if ([runItem.insertView isKindOfClass:[UIImage class]]) {
                image = runItem.insertView;
            }else if ([runItem.insertView isKindOfClass:[NSString class]]) {
                image = [UIImage imageNamed:runItem.insertView];
            }
            else if ([runItem.insertView isKindOfClass:[UIView class]]) {
                UIView *view = (UIView *)runItem.insertView;
                view.backgroundColor = self.backgroundColor;
                runBounds.origin.x = lineOrigin.x + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(runItem.runRef).location, NULL) + penOffsetX - runItem.strokeLineWidth/2;
                view.frame = runItem.locBounds;
                view.tag = [kCJInsertBackViewTag hash];
                [self addSubview:view];
                [self bringSubviewToFront:view];
            }
            
            if (image) {
                runBounds.origin.x = lineOrigin.x + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(runItem.runRef).location, NULL) + penOffsetX - runItem.strokeLineWidth/2;
                CGContextDrawImage(c, runBounds, image.CGImage);
            }
        }
        else{//绘制文字
            if (runItem.lineVerticalLayout.verticalAlignment != CJVerticalAlignmentBottom) {
                CGContextSetTextPosition(c, penOffsetX, runBounds.origin.y);
            }else{
                CGContextSetTextPosition(c, penOffsetX, lineOrigin.y);
            }
            CTRunDraw(runItem.runRef, c, CFRangeMake(0, 0));
        }
        
        selectCopyBackY = MIN(selectCopyBackY, runItem.locBounds.origin.y);
        CGFloat heightDif = (runItem.locBounds.size.height + runItem.locBounds.origin.y) - (lineVerticalLayout.lineRect.size.height + lineVerticalLayout.lineRect.origin.y);
        selectCopyHeightDif = MAX(selectCopyHeightDif, heightDif);
    }
    
    if (!self.caculateSizeOnly) {
        //填充描边
        [self drawBackgroundColor:c runStrokeItems:lineStrokrArray isStrokeColor:YES];
        //添加删除线
        [self drawStrikethroughContext:c runStrokeItems:lineStrokrArray];
    }
    
    lineLayoutModel.selectCopyBackY = selectCopyBackY;
    lineLayoutModel.selectCopyBackHeight = (selectCopyBackHeight + selectCopyHeightDif + lineVerticalLayout.lineRect.origin.y) - selectCopyBackY;
}

//获取CTLineRef行所对应的CJGlyphRunStrokeItem数组
- (NSMutableArray <CJGlyphRunStrokeItem *>*)lineRunItemsFromCTLineRef:(CTLineRef)line
                                                            lineIndex:(CFIndex)lineIndex
                                                           lineOrigin:(CGPoint)lineOrigin
                                                               inRect:(CGRect)rect
                                                              context:(CGContextRef)c
                                                           lineAscent:(CGFloat)lineAscent
                                                          lineDescent:(CGFloat)lineDescent
                                                          lineLeading:(CGFloat)lineLeading
                                                            lineWidth:(CGFloat)lineWidth
                                                   lineVerticalLayout:(CJCTLineVerticalLayout)lineVerticalLayout
{
    // 先获取每一行所有的runStrokeItems数组
    NSMutableArray *lineRunItems = [NSMutableArray arrayWithCapacity:3];
    
    //遍历每一行的所有glyphRun
    CFArrayRef runArray = CTLineGetGlyphRuns(line);
    for (NSInteger j = 0; j < CFArrayGetCount(runArray); j ++) {
        
        CTRunRef run = CFArrayGetValueAtIndex(runArray, j);
        CJGlyphRunStrokeItem *item = [self CJGlyphRunStrokeItemFromCTRunRef:run origin:lineOrigin line:line lineIndex:lineIndex lineAscent:lineAscent lineDescent:lineDescent lineLeading:lineLeading lineWidth:lineWidth lineVerticalLayout:lineVerticalLayout inRect:rect context:c];
        
        [lineRunItems addObject:item];
    }
    return lineRunItems;
}

#pragma mark - 将系统坐标转换为屏幕坐标
/**
 将系统坐标转换为屏幕坐标
 
 @param rect 坐标原点在左下角的 rect
 @return 坐标原点在左上角的 rect
 */
- (CGRect)convertRectFromLoc:(CGRect)rect {
    
    CGRect resultRect = CGRectZero;
    CGFloat labelRectHeight = self.bounds.size.height - self.textInsets.top - self.textInsets.bottom - _translateCTMty;
    CGFloat y = labelRectHeight - rect.origin.y - rect.size.height;
    
    resultRect = CGRectMake(rect.origin.x, y, rect.size.width, rect.size.height);
    return resultRect;
}

//调整CTRun在Y轴方向的坐标
- (CGFloat)yOffset:(CGFloat)y lineVerticalLayout:(CJCTLineVerticalLayout)lineVerticalLayout isImage:(BOOL)isImage runHeight:(CGFloat)runHeight imageVerticalAlignment:(CJLabelVerticalAlignment)imageVerticalAlignment lineLeading:(CGFloat)lineLeading runAscent:(CGFloat)runAscent
{
    CJLabelVerticalAlignment verticalAlignment = lineVerticalLayout.verticalAlignment;
    if (isImage) {
        verticalAlignment = imageVerticalAlignment;
    }
    
    //底对齐不用调整
    if (verticalAlignment == CJVerticalAlignmentBottom) {
        if (isImage) {
            y = y + self.font.descender/2 - lineLeading;
        }
        return y;
    }
    
    CGFloat maxRunHeight = lineVerticalLayout.maxRunHeight;
    CGFloat maxRunAscent = lineVerticalLayout.maxRunAscent;
    CGFloat maxImageHeight = lineVerticalLayout.maxImageHeight;
    CGFloat maxImageAscent = lineVerticalLayout.maxImageAscent;
    CGFloat maxHeight = MAX(maxRunHeight, maxImageHeight);
    CGFloat ascentY = maxRunAscent - runAscent;
    if (maxRunHeight > maxImageHeight) {
        if (isImage) {
            ascentY = maxRunAscent - runAscent + self.font.descender/2 - lineLeading;
        }
    }else{
        ascentY = maxImageAscent - runAscent;
    }
    
    CGFloat yy = y;
    
    //这是当前行最大高度的CTRun
    if (runHeight >= maxHeight) {
        if (isImage) {
            yy = yy + self.font.descender/2 - lineLeading;
        }
        return yy;
    }
    
    if (verticalAlignment == CJVerticalAlignmentCenter) {
        yy = y + ascentY/2.0;
    }else if (verticalAlignment == CJVerticalAlignmentTop) {
        yy = y + ascentY;
    }
    return yy;
}

/**
 绘制删除线
 
 @param c 上下文
 @param runStrokeItems 需要绘制的CJGlyphRunStrokeItem数组
 */
- (void)drawStrikethroughContext:(CGContextRef)c runStrokeItems:(NSArray <CJGlyphRunStrokeItem *>*)runStrokeItems
{
    if (runStrokeItems.count > 0) {
        for (CJGlyphRunStrokeItem *item in runStrokeItems) {
            [self drawBackgroundColor:c runStrokeItem:item isStrokeColor:NO active:NO isStrikethrough:YES];
        }
    }
}

- (void)drawBackgroundColor:(CGContextRef)c
                    runItem:(CJGlyphRunStrokeItem *)runItem
              isStrokeColor:(BOOL)isStrokeColor
{
    if (runItem) {
        if (_currentClickRunStrokeItem && NSEqualRanges(_currentClickRunStrokeItem.range,runItem.range)) {
            [self drawBackgroundColor:c runStrokeItem:runItem isStrokeColor:isStrokeColor active:YES isStrikethrough:NO];
        }
        else{
            [self drawBackgroundColor:c runStrokeItem:runItem isStrokeColor:isStrokeColor active:NO isStrikethrough:NO];
        }
    }
}

- (void)drawBackgroundColor:(CGContextRef)c
             runStrokeItems:(NSArray <CJGlyphRunStrokeItem *>*)runStrokeItems
              isStrokeColor:(BOOL)isStrokeColor
{
    if (runStrokeItems.count > 0) {
        for (CJGlyphRunStrokeItem *item in runStrokeItems) {
            [self drawBackgroundColor:c runItem:item isStrokeColor:isStrokeColor];
        }
    }
}

- (void)drawBackgroundColor:(CGContextRef)c
              runStrokeItem:(CJGlyphRunStrokeItem *)runStrokeItem
              isStrokeColor:(BOOL)isStrokeColor
                     active:(BOOL)active
            isStrikethrough:(BOOL)isStrikethrough
{
    CGContextSetLineJoin(c, kCGLineJoinRound);
    CGFloat x = runStrokeItem.runBounds.origin.x-self.textInsets.left;
    CGFloat y = runStrokeItem.runBounds.origin.y;
    
    CGRect roundedRect = CGRectMake(x,y,runStrokeItem.runBounds.size.width,runStrokeItem.runBounds.size.height);
    if (isStrokeColor) {
        CGFloat lineWidth = runStrokeItem.strokeLineWidth/2;
        CGFloat width = runStrokeItem.runBounds.size.width + ((runStrokeItem.isInsertView)?3*lineWidth:2*lineWidth);
        roundedRect = CGRectMake(x-lineWidth,
                                 y-lineWidth,
                                 width,
                                 runStrokeItem.runBounds.size.height + 2*lineWidth);
    }
    
    //画删除线
    if (isStrikethrough) {
        if (runStrokeItem.strikethroughStyle != 0) {
            CGFloat strikethroughY = roundedRect.origin.y + runStrokeItem.runBounds.size.height/2;
            CGFloat strikethroughX = x + runStrokeItem.strikethroughStyle/2;
            CGFloat strikethroughEndX = x + roundedRect.size.width - runStrokeItem.strikethroughStyle/2;
            CGContextSetLineCap(c, kCGLineCapSquare);
            CGContextSetLineWidth(c, runStrokeItem.strikethroughStyle);
            CGContextSetStrokeColorWithColor(c, CGColorRefFromColor(runStrokeItem.strikethroughColor));
            CGContextBeginPath(c);
            CGContextMoveToPoint(c, strikethroughX, strikethroughY);
            CGContextAddLineToPoint(c, strikethroughEndX, strikethroughY);
            CGContextStrokePath(c);
        }
        return;
    }
    
    CGFloat cornerRadius = runStrokeItem.cornerRadius;
    if (!isStrokeColor && runStrokeItem.strokeLineWidth > 1) {
        if (active) {
            cornerRadius = (isNotClearColor(runStrokeItem.activeFillColor) && isNotClearColor(runStrokeItem.activeStrokeColor))?0:cornerRadius;
        }else{
            cornerRadius = (isNotClearColor(runStrokeItem.fillColor) && isNotClearColor(runStrokeItem.strokeColor))?0:cornerRadius;
        }
    }
    
    CGPathRef glyphRunpath = [[UIBezierPath bezierPathWithRoundedRect:roundedRect cornerRadius:cornerRadius] CGPath];
    CGContextAddPath(c, glyphRunpath);
    
    //边框线
    if (isStrokeColor) {
        UIColor *color = (active?runStrokeItem.activeStrokeColor:runStrokeItem.strokeColor);
        if (CJLabelIsNull(color)) {
            color = [UIColor clearColor];
        }
        CGContextSetStrokeColorWithColor(c, CGColorRefFromColor(color));
        CGContextSetLineWidth(c, runStrokeItem.strokeLineWidth);
        CGContextStrokePath(c);
    }
    //背景色
    else {
        if (runStrokeItem.isInsertView) {
            return;
        }
        UIColor *color = (active?runStrokeItem.activeFillColor:runStrokeItem.fillColor);
        if (CJLabelIsNull(color)) {
            color = [UIColor clearColor];
        }
        CGContextSetFillColorWithColor(c, CGColorRefFromColor(color));
        CGContextFillPath(c);
    }
}

- (CJCTLineVerticalLayout)CJCTLineVerticalLayoutFromLine:(CTLineRef)line
                                               lineIndex:(CFIndex)lineIndex
                                                  origin:(CGPoint)origin
                                                 context:(CGContextRef)c
                                              lineAscent:(CGFloat)lineAscent
                                             lineDescent:(CGFloat)lineDescent
                                             lineLeading:(CGFloat)lineLeading
{
    //上下行高
    CGFloat lineAscentAndDescent = lineAscent + fabs(lineDescent);
    //默认底部对齐
    CJLabelVerticalAlignment verticalAlignment = CJVerticalAlignmentBottom;
    
    CFArrayRef runs = CTLineGetGlyphRuns(line);
    CGFloat maxRunHeight = 0;
    CGFloat maxRunAscent = 0;
    CGFloat maxImageHeight = 0;
    CGFloat maxImageAscent = 0;
    for (CFIndex j = 0; j < CFArrayGetCount(runs); ++j) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, j);
        CGFloat runAscent = 0.0f, runDescent = 0.0f, runLeading = 0.0f;
        CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &runAscent, &runDescent, &runLeading);
        NSDictionary *attDic = (__bridge NSDictionary *)CTRunGetAttributes(run);
        NSDictionary *imgInfoDic = attDic[kCJImageAttributeName];
        if (CJLabelIsNull(imgInfoDic)) {
            if (maxRunHeight < runAscent + fabs(runDescent)) {
                maxRunHeight = runAscent + fabs(runDescent);
                maxRunAscent = runAscent;
            }
        }else{
            if (maxImageHeight < runAscent + fabs(runDescent)) {
                maxImageHeight = runAscent + fabs(runDescent);
                maxImageAscent = runAscent;
                verticalAlignment = [imgInfoDic[kCJImageLineVerticalAlignment] integerValue];
            }
        }
    }
    
    CGRect lineBounds = CTLineGetImageBounds(line, c);
    //每一行的起始点（相对于context）加上相对于本身基线原点的偏移量
    lineBounds.origin.x += origin.x;
    lineBounds.origin.y += origin.y;
    lineBounds.origin.y = _insetRect.size.height - lineBounds.origin.y - lineBounds.size.height - _translateCTMty;
    lineBounds.size.width = lineBounds.size.width + self.textInsets.left + self.textInsets.right;
    
    CJCTLineVerticalLayout lineVerticalLayout;
    lineVerticalLayout.line = lineIndex;
    lineVerticalLayout.lineAscentAndDescent = lineAscentAndDescent;
    lineVerticalLayout.lineRect = lineBounds;
    lineVerticalLayout.verticalAlignment = verticalAlignment;
    lineVerticalLayout.maxRunHeight = maxRunHeight;
    lineVerticalLayout.maxRunAscent = maxRunAscent;
    lineVerticalLayout.maxImageHeight = maxImageHeight;
    lineVerticalLayout.maxImageAscent = maxImageAscent;
    
    return lineVerticalLayout;
}

//记录 所有CTLine在垂直方向的对齐方式的数组
- (NSArray <CJCTLineLayoutModel *>*)allCTLineVerticalLayoutArray:(CFArrayRef)lines
                                                         origins:(CGPoint[])origins
                                                          inRect:(CGRect)rect
                                                         context:(CGContextRef)c
                                                       textRange:(CFRange)textRange
                                                attributedString:(NSAttributedString *)attributedString
                                                truncateLastLine:(BOOL)truncateLastLine
{
    NSMutableArray *verticalLayoutArray = [NSMutableArray arrayWithCapacity:3];
    
    // 遍历所有行
    for (CFIndex lineIndex = 0; lineIndex < MIN(_textNumberOfLines, CFArrayGetCount(lines)); lineIndex ++ ) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        
        CGFloat lineAscent = 0.0f, lineDescent = 0.0f, lineLeading = 0.0f;
        CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
        
        if (lineIndex == _textNumberOfLines - 1 && truncateLastLine) {
            
            CTLineRef lastLine = [self handleLastCTLine:line textRange:textRange attributedString:attributedString rect:rect context:c];
            CTLineGetTypographicBounds(lastLine, &lineAscent, &lineDescent, &lineLeading);
            
            CJCTLineVerticalLayout lineVerticalLayout = [self CJCTLineVerticalLayoutFromLine:lastLine lineIndex:lineIndex origin:origins[lineIndex] context:c lineAscent:lineAscent lineDescent:lineDescent lineLeading:lineLeading];
            
            CJCTLineLayoutModel *lineLayoutModel = [[CJCTLineLayoutModel alloc]init];
            lineLayoutModel.lineVerticalLayout = lineVerticalLayout;
            lineLayoutModel.lineIndex = lineIndex;
            [verticalLayoutArray addObject:lineLayoutModel];
            
            CFRelease(lastLine);
        }else{
            CJCTLineVerticalLayout lineVerticalLayout = [self CJCTLineVerticalLayoutFromLine:line lineIndex:lineIndex origin:origins[lineIndex] context:c lineAscent:lineAscent lineDescent:lineDescent lineLeading:lineLeading];
            
            CJCTLineLayoutModel *lineLayoutModel = [[CJCTLineLayoutModel alloc]init];
            lineLayoutModel.lineVerticalLayout = lineVerticalLayout;
            lineLayoutModel.lineIndex = lineIndex;
            [verticalLayoutArray addObject:lineLayoutModel];
        }
    }
    _lineVerticalMaxWidth = self.bounds.size.width;
    
    return verticalLayoutArray;
}

- (CJGlyphRunStrokeItem *)CJGlyphRunStrokeItemFromCTRunRef:(CTRunRef)glyphRun origin:(CGPoint)origin line:(CTLineRef)line lineIndex:(CFIndex)lineIndex lineAscent:(CGFloat)lineAscent lineDescent:(CGFloat)lineDescent lineLeading:(CGFloat)lineLeading lineWidth:(CGFloat)lineWidth lineVerticalLayout:(CJCTLineVerticalLayout)lineVerticalLayout inRect:(CGRect)rect context:(CGContextRef)c
{
    
    NSDictionary *attributes = (__bridge NSDictionary *)CTRunGetAttributes(glyphRun);
    //背景色以及描边属性
    UIColor *strokeColor = colorWithAttributeName(attributes, kCJBackgroundStrokeColorAttributeName);
    if (!CJLabelIsNull(attributes[kCJLinkAttributesName]) && !isNotClearColor(strokeColor)) {
        strokeColor = colorWithAttributeName(attributes[kCJLinkAttributesName], kCJBackgroundStrokeColorAttributeName);
    }
    UIColor *fillColor = colorWithAttributeName(attributes, kCJBackgroundFillColorAttributeName);
    if (!CJLabelIsNull(attributes[kCJLinkAttributesName]) && !isNotClearColor(fillColor)) {
        fillColor = colorWithAttributeName(attributes[kCJLinkAttributesName], kCJBackgroundFillColorAttributeName);
    }
    //点击高亮背景色以及描边属性
    UIColor *activeStrokeColor = colorWithAttributeName(attributes, kCJActiveBackgroundStrokeColorAttributeName);
    if (!CJLabelIsNull(attributes[kCJActiveLinkAttributesName]) && !isNotClearColor(activeStrokeColor)) {
        activeStrokeColor = colorWithAttributeName(attributes[kCJActiveLinkAttributesName], kCJActiveBackgroundStrokeColorAttributeName);
    }
    if (strokeColor && !activeStrokeColor) {
        activeStrokeColor = strokeColor;
    }
    
    UIColor *activeFillColor = colorWithAttributeName(attributes, kCJActiveBackgroundFillColorAttributeName);
    if (!CJLabelIsNull(attributes[kCJActiveLinkAttributesName]) && !isNotClearColor(activeFillColor)) {
        activeFillColor = colorWithAttributeName(attributes[kCJActiveLinkAttributesName], kCJActiveBackgroundFillColorAttributeName);
    }
    if (fillColor && !activeFillColor) {
        activeFillColor = fillColor;
    }
    //描边边线宽度
    CGFloat strokeLineWidth = [[attributes objectForKey:kCJBackgroundLineWidthAttributeName] floatValue];
    if (!CJLabelIsNull(attributes[kCJActiveLinkAttributesName]) && strokeLineWidth == 0) {
        strokeLineWidth = [[attributes[kCJActiveLinkAttributesName] objectForKey:kCJBackgroundLineWidthAttributeName] floatValue];
    }
    
    //是否有设置圆角
    BOOL haveCornerRadius = NO;
    if (attributes[kCJBackgroundLineCornerRadiusAttributeName] || attributes[kCJActiveLinkAttributesName][kCJBackgroundLineCornerRadiusAttributeName]) {
        haveCornerRadius = YES;
    }
    //填充背景色圆角
    CGFloat cornerRadius = [[attributes objectForKey:kCJBackgroundLineCornerRadiusAttributeName] floatValue];
    if (!CJLabelIsNull(attributes[kCJActiveLinkAttributesName]) && cornerRadius == 0) {
        cornerRadius = [[attributes[kCJActiveLinkAttributesName] objectForKey:kCJBackgroundLineCornerRadiusAttributeName] floatValue];
    }
    strokeLineWidth = strokeLineWidth == 0?1:strokeLineWidth;
    if (!haveCornerRadius) {
        cornerRadius = cornerRadius == 0?5:cornerRadius;
    }
    
    //删除线
    CGFloat strikethroughStyle = [[attributes objectForKey:kCJStrikethroughStyleAttributeName] floatValue];
    if (strikethroughStyle == 0) {
        strikethroughStyle = [[attributes[kCJLinkAttributesName]objectForKey:kCJStrikethroughStyleAttributeName] floatValue];
    }
    if (strikethroughStyle == 0) {
        strikethroughStyle = [[attributes[kCJActiveLinkAttributesName]objectForKey:kCJStrikethroughStyleAttributeName] floatValue];
    }
    //删除线颜色
    UIColor *strikethroughColor = nil;
    if (strikethroughStyle != 0) {
        strikethroughColor = colorWithAttributeName(attributes, kCJStrikethroughColorAttributeName);
        if (!CJLabelIsNull(attributes[kCJLinkAttributesName]) && !isNotClearColor(strikethroughColor)) {
            strikethroughColor = colorWithAttributeName(attributes[kCJLinkAttributesName], kCJStrikethroughColorAttributeName);
        }
        if (!CJLabelIsNull(attributes[kCJActiveLinkAttributesName]) && !isNotClearColor(strikethroughColor)) {
            strikethroughColor = colorWithAttributeName(attributes[kCJActiveLinkAttributesName], kCJStrikethroughColorAttributeName);
        }
        if (!isNotClearColor(strikethroughColor)) {
            strikethroughColor = [UIColor blackColor];
        }
    }
    
    BOOL isLink = [attributes[kCJIsLinkAttributesName] boolValue];
    
    //点击链点的range（当isLink == YES才存在）
    NSString *linkRangeStr = [attributes objectForKey:kCJLinkRangeAttributesName];
    //点击链点是否需要重绘
    BOOL needRedrawn = [attributes[kCJLinkNeedRedrawnAttributesName] boolValue];
    
    BOOL isImage = NO;
    NSDictionary *imgInfoDic = attributes[kCJImageAttributeName];
    CJLabelVerticalAlignment imageVerticalAlignment = CJVerticalAlignmentBottom;
    if (!CJLabelIsNull(imgInfoDic)) {
        imageVerticalAlignment = [imgInfoDic[kCJImageLineVerticalAlignment] integerValue];
        isImage = YES;
    }
    
    NSInteger characterIndex = 0;
    NSRange substringRange = NSMakeRange(0, 0);
    if (self.caculateCopySize) {
        CJCTRunUrl *runUrl = attributes[NSLinkAttributeName];
        if ([runUrl isKindOfClass:[CJCTRunUrl class]]) {
            characterIndex = runUrl.index;
            substringRange = [runUrl.rangeValue rangeValue];
        }
    }
    
    CGRect runBounds = CGRectZero;
    CGFloat runAscent = 0.0f, runDescent = 0.0f, runLeading = 0.0f;
    runBounds.size.width = (CGFloat)CTRunGetTypographicBounds(glyphRun, CFRangeMake(0, 0), &runAscent, &runDescent, &runLeading);
    CGFloat runHeight = runAscent + fabs(runDescent);
    runBounds.size.height = runHeight;
    
    //当前run相对于self的CGRect
    runBounds = [self getRunStrokeItemlocRunBoundsFromGlyphRun:glyphRun line:line origin:origin lineIndex:lineIndex inRect:rect width:lineWidth lineVerticalLayout:lineVerticalLayout isImage:isImage imageVerticalAlignment:imageVerticalAlignment lineDescent:lineDescent lineLeading:lineLeading runBounds:runBounds runAscent:runAscent];
    
    //转换为UIKit坐标系统
    CGRect locBounds = [self convertRectFromLoc:runBounds];
    
    CJGlyphRunStrokeItem *runStrokeItem = [[CJGlyphRunStrokeItem alloc]init];
    runStrokeItem.runBounds = runBounds;
    runStrokeItem.locBounds = locBounds;
    CGFloat withOutMergeBoundsY = lineVerticalLayout.lineRect.origin.y - (MAX(lineVerticalLayout.maxRunAscent, lineVerticalLayout.maxImageAscent) - lineVerticalLayout.lineRect.size.height);
    //    CGFloat withOutMergeBoundsY = locBounds.origin.y;
    runStrokeItem.withOutMergeBounds =
    CGRectMake(locBounds.origin.x,
               withOutMergeBoundsY,
               locBounds.size.width,
               //               locBounds.size.height);
               MAX(lineVerticalLayout.maxRunHeight, lineVerticalLayout.maxImageHeight));
    runStrokeItem.lineVerticalLayout = lineVerticalLayout;
    runStrokeItem.characterIndex = characterIndex;
    runStrokeItem.characterRange = substringRange;
    runStrokeItem.runDescent = fabs(runDescent);
    runStrokeItem.runRef = glyphRun;
    
    // 当前glyphRun是一个可点击链点
    if (isLink) {
        runStrokeItem.strokeColor = strokeColor;
        runStrokeItem.fillColor = fillColor;
        runStrokeItem.strokeLineWidth = strokeLineWidth;
        runStrokeItem.cornerRadius = cornerRadius;
        runStrokeItem.activeStrokeColor = activeStrokeColor;
        runStrokeItem.activeFillColor = activeFillColor;
        runStrokeItem.range = NSRangeFromString(linkRangeStr);
        runStrokeItem.isLink = YES;
        runStrokeItem.needRedrawn = needRedrawn;
        runStrokeItem.strikethroughStyle = strikethroughStyle;
        runStrokeItem.strikethroughColor = strikethroughColor;
        
        if (imgInfoDic[kCJImage]) {
            runStrokeItem.insertView = imgInfoDic[kCJImage];
            runStrokeItem.isInsertView = YES;
        }
        if (!CJLabelIsNull(attributes[kCJLinkParameterAttributesName])) {
            runStrokeItem.parameter = attributes[kCJLinkParameterAttributesName];
        }
        if (!CJLabelIsNull(attributes[kCJClickLinkBlockAttributesName])) {
            runStrokeItem.linkBlock = attributes[kCJClickLinkBlockAttributesName];
        }
        if (!CJLabelIsNull(attributes[kCJLongPressBlockAttributesName])) {
            runStrokeItem.longPressBlock = attributes[kCJLongPressBlockAttributesName];
        }
    }
    else{
        //不是可点击链点。但存在自定义边框线或背景色
        if (isNotClearColor(strokeColor) || isNotClearColor(fillColor) || isNotClearColor(activeStrokeColor) || isNotClearColor(activeFillColor) || strikethroughStyle != 0) {
            runStrokeItem.strokeColor = strokeColor;
            runStrokeItem.fillColor = fillColor;
            runStrokeItem.strokeLineWidth = strokeLineWidth;
            runStrokeItem.cornerRadius = cornerRadius;
            runStrokeItem.activeStrokeColor = activeStrokeColor;
            runStrokeItem.activeFillColor = activeFillColor;
            runStrokeItem.strikethroughStyle = strikethroughStyle;
            runStrokeItem.strikethroughColor = strikethroughColor;
        }
        runStrokeItem.isLink = NO;
        if (imgInfoDic[kCJImage]) {
            runStrokeItem.insertView = imgInfoDic[kCJImage];
            runStrokeItem.isInsertView = YES;
        }
    }
    return runStrokeItem;
}

//当前run相对于self的CGRect
- (CGRect)getRunStrokeItemlocRunBoundsFromGlyphRun:(CTRunRef)glyphRun line:(CTLineRef)line origin:(CGPoint)origin lineIndex:(CFIndex)lineIndex inRect:(CGRect)rect width:(CGFloat)width lineVerticalLayout:(CJCTLineVerticalLayout)lineVerticalLayout isImage:(BOOL)isImage imageVerticalAlignment:(CJLabelVerticalAlignment)imageVerticalAlignment lineDescent:(CGFloat)lineDescent lineLeading:(CGFloat)lineLeading runBounds:(CGRect)runBounds runAscent:(CGFloat)runAscent
{
    CGFloat xOffset = 0.0f;
    CFRange glyphRange = CTRunGetStringRange(glyphRun);
    switch (CTRunGetStatus(glyphRun)) {
        case kCTRunStatusRightToLeft:
            xOffset = CTLineGetOffsetForStringIndex(line, glyphRange.location + glyphRange.length, NULL);
            break;
        default:
            xOffset = CTLineGetOffsetForStringIndex(line, glyphRange.location, NULL);
            break;
    }
    
    runBounds.origin.x = origin.x + rect.origin.x + xOffset;
    CGFloat y = origin.y;
    
    CGFloat yy = [self yOffset:y lineVerticalLayout:lineVerticalLayout isImage:isImage runHeight:runBounds.size.height imageVerticalAlignment:imageVerticalAlignment lineLeading:lineLeading runAscent:runAscent];
    
    // 这里的runBounds是用于背景色填充以及计算点击位置
    // 此时应该将每个文字CTRun的下行高（runDescent）加上，而图片的runBounds = 0,所以忽略了
    runBounds.origin.y = isImage?yy:(yy - (runBounds.size.height - runAscent));
    
    if (CGRectGetWidth(runBounds) > width) {
        runBounds.size.width = width;
    }
    
    return runBounds;
}

//判断是否有需要合并的runStrokeItems
- (NSMutableArray <CJGlyphRunStrokeItem *>*)mergeLineSameStrokePathItems:(NSArray <CJGlyphRunStrokeItem *>*)lineStrokePathItems ascentAndDescent:(CGFloat)ascentAndDescent {
    
    NSMutableArray *mergeLineStrokePathItems = [[NSMutableArray alloc] initWithCapacity:3];
    
    if (lineStrokePathItems.count > 1) {
        
        NSMutableArray *strokePathTempItems = [NSMutableArray arrayWithCapacity:3];
        for (NSInteger i = 0; i < lineStrokePathItems.count; i ++) {
            CJGlyphRunStrokeItem *item = lineStrokePathItems[i];
            
            //第一个item无需判断
            if (i == 0) {
                _lastGlyphRunStrokeItem = item;
            }else{
                
                CGRect runBounds = item.runBounds;
                CGRect locBounds = item.locBounds;
                UIColor *strokeColor = item.strokeColor;
                UIColor *fillColor = item.fillColor;
                UIColor *activeStrokeColor = item.activeStrokeColor;
                UIColor *activeFillColor = item.activeFillColor;
                CGFloat lineWidth = item.strokeLineWidth;
                CGFloat cornerRadius = item.cornerRadius;
                //删除线
                CGFloat strikethroughStyle = item.strikethroughStyle;
                UIColor *strikethroughColor = item.strikethroughColor;
                
                CGRect lastRunBounds = _lastGlyphRunStrokeItem.runBounds;
                CGRect lastLocBounds = _lastGlyphRunStrokeItem.locBounds;
                UIColor *lastStrokeColor = _lastGlyphRunStrokeItem.strokeColor;
                UIColor *lastFillColor = _lastGlyphRunStrokeItem.fillColor;
                UIColor *lastActiveStrokeColor = _lastGlyphRunStrokeItem.activeStrokeColor;
                UIColor *lastActiveFillColor = _lastGlyphRunStrokeItem.activeFillColor;
                CGFloat lastLineWidth = _lastGlyphRunStrokeItem.strokeLineWidth;
                CGFloat lastCornerRadius = _lastGlyphRunStrokeItem.cornerRadius;
                //删除线
                CGFloat lastStrikethroughStyle = _lastGlyphRunStrokeItem.strikethroughStyle;
                UIColor *lastStrikethroughColor = _lastGlyphRunStrokeItem.strikethroughColor;
                
                BOOL needMerge = NO;
                //可点击链点
                if (item.isLink && _lastGlyphRunStrokeItem.isLink) {
                    NSRange range = item.range;
                    NSRange lastRange = _lastGlyphRunStrokeItem.range;
                    //需要合并的点击链点
                    if (NSEqualRanges(range,lastRange)) {
                        needMerge = YES;
                        lastRunBounds = CGRectMake(compareMaxNum(lastRunBounds.origin.x,runBounds.origin.x,NO),
                                                   compareMaxNum(lastRunBounds.origin.y,runBounds.origin.y,YES),
                                                   lastRunBounds.size.width + runBounds.size.width,
                                                   compareMaxNum(lastRunBounds.size.height,runBounds.size.height,YES));
                        _lastGlyphRunStrokeItem.runBounds = lastRunBounds;
                        _lastGlyphRunStrokeItem.locBounds =
                        CGRectMake(compareMaxNum(lastLocBounds.origin.x,locBounds.origin.x,NO),
                                   compareMaxNum(lastLocBounds.origin.y,locBounds.origin.y,NO),
                                   lastLocBounds.size.width + locBounds.size.width,
                                   compareMaxNum(lastLocBounds.size.height,locBounds.size.height,YES));
                    }
                }else if (!item.isLink && !_lastGlyphRunStrokeItem.isLink){
                    
                    BOOL sameColor = ({
                        BOOL same = NO;
                        
                        if (!strokeColor && !fillColor && !activeStrokeColor && !activeFillColor) {
                            same = NO;
                        }else{
                            if (strokeColor) {
                                same = isSameColor(strokeColor,lastStrokeColor);
                            }
                            if (same && fillColor) {
                                same = isSameColor(fillColor,lastFillColor);
                            }
                            if (same && activeStrokeColor) {
                                same = isSameColor(activeStrokeColor,lastActiveStrokeColor);
                            }
                            if (same && activeFillColor) {
                                same = isSameColor(activeFillColor,lastActiveFillColor);
                            }
                        }
                        same;
                    });
                    
                    //浮点数判断
                    BOOL nextItem = (fabs((lastRunBounds.origin.x + lastRunBounds.size.width) - runBounds.origin.x)<=1e-6)?YES:NO;
                    //非点击链点，但是是需要合并的连续run
                    if (sameColor && lineWidth == lastLineWidth && cornerRadius == lastCornerRadius && nextItem
                        ) {
                        
                        needMerge = YES;
                        lastRunBounds = CGRectMake(compareMaxNum(lastRunBounds.origin.x,runBounds.origin.x,NO),
                                                   compareMaxNum(lastRunBounds.origin.y,runBounds.origin.y,YES),
                                                   lastRunBounds.size.width + runBounds.size.width,
                                                   compareMaxNum(lastRunBounds.size.height,runBounds.size.height,YES));
                        _lastGlyphRunStrokeItem.runBounds = lastRunBounds;
                        _lastGlyphRunStrokeItem.locBounds =
                        CGRectMake(compareMaxNum(lastLocBounds.origin.x,locBounds.origin.x,NO),
                                   compareMaxNum(lastLocBounds.origin.y,locBounds.origin.y,NO),
                                   lastLocBounds.size.width + locBounds.size.width,
                                   compareMaxNum(lastLocBounds.size.height,locBounds.size.height,YES));
                    }
                }
                
                
                //没有发生合并
                if (!needMerge) {
                    
                    _lastGlyphRunStrokeItem = [self adjustItemHeight:_lastGlyphRunStrokeItem height:ascentAndDescent];
                    [strokePathTempItems addObject:[_lastGlyphRunStrokeItem copy]];
                    
                    _lastGlyphRunStrokeItem = item;
                    
                    //已经是最后一个run
                    if (i == lineStrokePathItems.count - 1) {
                        _lastGlyphRunStrokeItem = [self adjustItemHeight:_lastGlyphRunStrokeItem height:ascentAndDescent];
                        [strokePathTempItems addObject:[_lastGlyphRunStrokeItem copy]];
                    }
                }
                //有合并
                else{
                    _lastGlyphRunStrokeItem.strikethroughStyle = MAX(strikethroughStyle, lastStrikethroughStyle);
                    if (_lastGlyphRunStrokeItem.strikethroughStyle != 0) {
                        if (lastStrikethroughColor) {
                            _lastGlyphRunStrokeItem.strikethroughColor = lastStrikethroughColor;
                        }
                        if (strikethroughColor) {
                            _lastGlyphRunStrokeItem.strikethroughColor = strikethroughColor;
                        }
                        if (!_lastGlyphRunStrokeItem.strikethroughColor) {
                            _lastGlyphRunStrokeItem.strikethroughColor = [UIColor blackColor];
                        }
                    }
                    //已经是最后一个run
                    if (i == lineStrokePathItems.count - 1) {
                        _lastGlyphRunStrokeItem = [self adjustItemHeight:_lastGlyphRunStrokeItem height:ascentAndDescent];
                        [strokePathTempItems addObject:[_lastGlyphRunStrokeItem copy]];
                    }
                }
            }
        }
        [mergeLineStrokePathItems addObjectsFromArray:strokePathTempItems];
    }
    else{
        if (lineStrokePathItems.count == 1) {
            CJGlyphRunStrokeItem *item = lineStrokePathItems[0];
            item = [self adjustItemHeight:item height:ascentAndDescent];
            [mergeLineStrokePathItems addObject:item];
        }
        
    }
    return mergeLineStrokePathItems;
}

- (CJGlyphRunStrokeItem *)adjustItemHeight:(CJGlyphRunStrokeItem *)item height:(CGFloat)ascentAndDescent {
    // runBounds小于 ascent + Descent 时，rect扩大 1
    if (item.runBounds.size.height < ascentAndDescent) {
        item.runBounds = CGRectInset(item.runBounds,-1,-1);
    }
    return item;
}

- (NSArray <CJGlyphRunStrokeItem *>*)getLinkStrokeItems:(NSArray *)strokeItems {
    NSMutableArray *linkArray = [NSMutableArray arrayWithCapacity:4];
    for (CJGlyphRunStrokeItem *item in strokeItems) {
        if (item.isLink) {
            [linkArray addObject:item];
        }
    }
    return linkArray;
}

#pragma mark - UIView
- (CGSize)sizeThatFits:(CGSize)size {
    if (!self.attributedText) {
        return [super sizeThatFits:size];
    } else {
        NSAttributedString *string = [self renderedAttributedText];
        
        CGSize labelSize = CTFramesetterSuggestFrameSizeForAttributedStringWithConstraints([self framesetter], string, size, (NSUInteger)self.numberOfLines);
        labelSize.width += self.textInsets.left + self.textInsets.right;
        labelSize.height += self.textInsets.top + self.textInsets.bottom;
        
        return labelSize;
    }
}

- (CGSize)intrinsicContentSize {
    return [self sizeThatFits:[super intrinsicContentSize]];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (![self linkAtPoint:point extendsLinkTouchArea:NO] || !self.userInteractionEnabled || self.hidden || self.alpha < 0.01) {
        if (self.enableCopy) {
            return [super hitTest:point withEvent:event];
        }else{
            return nil;
        }
    }
    return self;
}

#pragma mark - UIResponder
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)containslinkAtPoint:(CGPoint)point {
    return [self linkAtPoint:point extendsLinkTouchArea:self.extendsLinkTouchArea] != nil;
}

- (CJGlyphRunStrokeItem *)linkAtPoint:(CGPoint)point extendsLinkTouchArea:(BOOL)extendsLinkTouchArea {
    if (!CGRectContainsPoint(CGRectInset(self.bounds, -15.f, -15.f), point) || _linkStrokeItemArray.count == 0) {
        return nil;
    }
    
    CJGlyphRunStrokeItem *resultItem = [self clickLinkItemAtRadius:0 aroundPoint:point];
    
    if (!resultItem && extendsLinkTouchArea) {
        resultItem = [self clickLinkItemAtRadius:0 aroundPoint:point]
        ?: [self clickLinkItemAtRadius:2.5 aroundPoint:point]
        ?: [self clickLinkItemAtRadius:5 aroundPoint:point]
        ?: [self clickLinkItemAtRadius:7.5 aroundPoint:point];
    }
    return resultItem;
}

- (CJGlyphRunStrokeItem *)clickLinkItemAtRadius:(CGFloat)radius aroundPoint:(CGPoint)point {
    CJGlyphRunStrokeItem *resultItem = nil;
    for (CJGlyphRunStrokeItem *item in _linkStrokeItemArray) {
        CGRect bounds = item.locBounds;
        if (radius > 0) {
            bounds = CGRectInset(bounds,-radius,-radius);
        }
        if (CGRectContainsPoint(bounds, point)) {
            resultItem = item;
        }
    }
    return resultItem;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    _currentClickRunStrokeItem = nil;
    CJGlyphRunStrokeItem *item = [self linkAtPoint:[touch locationInView:self] extendsLinkTouchArea:self.extendsLinkTouchArea];
    if (item) {
        _currentClickRunStrokeItem = item;
        _needRedrawn = _currentClickRunStrokeItem.needRedrawn;
        [self setNeedsFramesetter];
        [self setNeedsDisplay];
        //立即刷新界面
        [CATransaction flush];
    }
    
    if (!item) {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_longPress) {
        [super touchesEnded:touches withEvent:event];
    }else{
        if (_currentClickRunStrokeItem) {
            
            NSAttributedString *attributedString = [self.attributedText attributedSubstringFromRange:_currentClickRunStrokeItem.range];
            __weak typeof(self)wSelf = self;
            CJLabelLinkModel *linkModel =
            [[CJLabelLinkModel alloc]initWithAttributedString:attributedString
                                                   insertView:_currentClickRunStrokeItem.insertView
                                               insertViewRect:_currentClickRunStrokeItem.locBounds
                                                    parameter:_currentClickRunStrokeItem.parameter
                                                    linkRange:_currentClickRunStrokeItem.range
                                                        label:wSelf];
            
            if (_currentClickRunStrokeItem.linkBlock) {
                _currentClickRunStrokeItem.linkBlock(linkModel);
            }
            if (self.delegate && [self.delegate respondsToSelector:@selector(CJLable:didClickLink:)]) {
                [self.delegate CJLable:self didClickLink:linkModel];
            }
            
            _needRedrawn = _currentClickRunStrokeItem.needRedrawn;
            _currentClickRunStrokeItem = nil;
            [self setNeedsFramesetter];
            [self setNeedsDisplay];
        }
        else {
            [super touchesEnded:touches withEvent:event];
        }
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_longPress) {
        [super touchesCancelled:touches withEvent:event];
    }else{
        if (_currentClickRunStrokeItem) {
            _needRedrawn = NO;
            _currentClickRunStrokeItem = nil;
        } else {
            [super touchesCancelled:touches withEvent:event];
        }
    }
}

- (void)caculateCTRunCopySizeBlock:(void(^)(void))block {
    if (_allRunItemArray.count > 0) {
        block();
        return;
    }
    self.caculateCopySize = YES;
    self.caculateCTRunSizeBlock = block;
    self.attributedText = self.attributedText;
}


#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer == self.longPressGestureRecognizer) {
        objc_setAssociatedObject(self.longPressGestureRecognizer, &kAssociatedUITouchKey, touch, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    else if (gestureRecognizer == self.doubleTapGes) {
        objc_setAssociatedObject(self.doubleTapGes, &kAssociatedUITouchKey, touch, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return YES;
}

- (void)tapTwoAct:(UITapGestureRecognizer *)sender {
    UITouch *touch = objc_getAssociatedObject(self.doubleTapGes, &kAssociatedUITouchKey);
    CJGlyphRunStrokeItem *item = [self linkAtPoint:[touch locationInView:self]extendsLinkTouchArea:self.extendsLinkTouchArea];
    if (item) {
        _currentClickRunStrokeItem = nil;
        _currentClickRunStrokeItem = item;
        
        NSAttributedString *attributedString = [self.attributedText attributedSubstringFromRange:_currentClickRunStrokeItem.range];
        __weak typeof(self)wSelf = self;
        CJLabelLinkModel *linkModel =
        [[CJLabelLinkModel alloc]initWithAttributedString:attributedString
                                               insertView:_currentClickRunStrokeItem.insertView
                                           insertViewRect:_currentClickRunStrokeItem.locBounds
                                                parameter:_currentClickRunStrokeItem.parameter
                                                linkRange:_currentClickRunStrokeItem.range
                                                    label:wSelf];
        
        if (_currentClickRunStrokeItem.linkBlock) {
            _currentClickRunStrokeItem.linkBlock(linkModel);
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(CJLable:didClickLink:)]) {
            [self.delegate CJLable:self didClickLink:linkModel];
        }
        _needRedrawn = _currentClickRunStrokeItem.needRedrawn;
        _currentClickRunStrokeItem = nil;
        [self setNeedsFramesetter];
        [self setNeedsDisplay];
        //立即刷新界面
        [CATransaction flush];
    }
    else{
        if (self.enableCopy) {
            CGPoint point = [touch locationInView:self];
            [self caculateCTRunCopySizeBlock:^(){
                CJGlyphRunStrokeItem *currentItem = [CJSelectCopyManagerView currentItem:point allRunItemArray:_allRunItemArray inset:1];
                if (currentItem) {
                    
                    UIViewController *topVC = [self topViewController];
                    UINavigationController *navCtr = nil;
                    BOOL popGestureEnable = NO;
                    if (topVC.navigationController) {
                        navCtr = topVC.navigationController;
                        popGestureEnable = navCtr.interactivePopGestureRecognizer.enabled;
                        navCtr.interactivePopGestureRecognizer.enabled = NO;
                    }
                    
                    //唤起 选择复制视图
                    [[CJSelectCopyManagerView instance]showSelectViewInCJLabel:self atPoint:point runItem:[currentItem copy] maxLineWidth:_lineVerticalMaxWidth allCTLineVerticalArray:_CTLineVerticalLayoutArray allRunItemArray:_allRunItemArray hideViewBlock:^(){
                        self.caculateCopySize = NO;
                        if (navCtr) {
                            navCtr.interactivePopGestureRecognizer.enabled = popGestureEnable;
                        }
                    }];
                }
            }];
        }
    }
}

#pragma mark - UILongPressGestureRecognizer
- (void)longPressGestureDidFire:(UILongPressGestureRecognizer *)sender {
    
    UITouch *touch = objc_getAssociatedObject(self.longPressGestureRecognizer, &kAssociatedUITouchKey);
    CGPoint point = [touch locationInView:self];
    BOOL isLinkItem = [self containslinkAtPoint:[touch locationInView:self]];
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            if (isLinkItem) {
                _longPress = YES;
                if (_currentClickRunStrokeItem) {
                    
                    NSAttributedString *attributedString = [self.attributedText attributedSubstringFromRange:_currentClickRunStrokeItem.range];
                    __weak typeof(self)wSelf = self;
                    CJLabelLinkModel *linkModel =
                    [[CJLabelLinkModel alloc]initWithAttributedString:attributedString
                                                           insertView:_currentClickRunStrokeItem.insertView
                                                       insertViewRect:_currentClickRunStrokeItem.locBounds
                                                            parameter:_currentClickRunStrokeItem.parameter
                                                            linkRange:_currentClickRunStrokeItem.range
                                                                label:wSelf];
                    
                    
                    if (_currentClickRunStrokeItem.longPressBlock) {
                        _currentClickRunStrokeItem.longPressBlock(linkModel);
                    }
                    if (self.delegate && [self.delegate respondsToSelector:@selector(CJLable:didLongPressLink:)]) {
                        [self.delegate CJLable:self didLongPressLink:linkModel];
                    }
                }
                
                _longPress = NO;
                if (_currentClickRunStrokeItem) {
                    _needRedrawn = _currentClickRunStrokeItem.needRedrawn;
                    _currentClickRunStrokeItem = nil;
                    [self setNeedsFramesetter];
                    [self setNeedsDisplay];
                    [CATransaction flush];
                }
            }else{
                if (self.enableCopy) {
                    _afterLongPressEnd = NO;
                    [self caculateCTRunCopySizeBlock:^(){
                        if (!_afterLongPressEnd) {
                            //发生长按，显示放大镜
                            CJGlyphRunStrokeItem *currentItem = [CJSelectCopyManagerView currentItem:point allRunItemArray:_allRunItemArray inset:0.5];
                            if (currentItem) {
                                [[CJSelectCopyManagerView instance] showMagnifyInCJLabel:self magnifyPoint:point runItem:currentItem];
                            }else{
                                if (CGRectContainsPoint(self.bounds, point)) {
                                    [[CJSelectCopyManagerView instance] showMagnifyInCJLabel:self magnifyPoint:point runItem:nil];
                                }
                            }
                        }
                    }];
                }
            }
            
            break;
        }
        case UIGestureRecognizerStateEnded:{
            _afterLongPressEnd = YES;
            [[CJSelectCopyManagerView instance] hideView];
            if (isLinkItem) {
                _longPress = NO;
                if (_currentClickRunStrokeItem) {
                    _needRedrawn = _currentClickRunStrokeItem.needRedrawn;
                    _currentClickRunStrokeItem = nil;
                    [self setNeedsFramesetter];
                    [self setNeedsDisplay];
                    [CATransaction flush];
                }
            }
            if (self.enableCopy) {
                CJGlyphRunStrokeItem *currentItem = [CJSelectCopyManagerView currentItem:point allRunItemArray:_allRunItemArray inset:1];
                if (currentItem) {
                    
                    UIViewController *topVC = [self topViewController];
                    UINavigationController *navCtr = nil;
                    BOOL popGestureEnable = NO;
                    if (topVC.navigationController) {
                        navCtr = topVC.navigationController;
                        popGestureEnable = navCtr.interactivePopGestureRecognizer.enabled;
                        navCtr.interactivePopGestureRecognizer.enabled = NO;
                    }
                    
                    //唤起 选择复制视图
                    [[CJSelectCopyManagerView instance]showSelectViewInCJLabel:self atPoint:point runItem:[currentItem copy] maxLineWidth:_lineVerticalMaxWidth allCTLineVerticalArray:_CTLineVerticalLayoutArray allRunItemArray:_allRunItemArray hideViewBlock:^(){
                        self.caculateCopySize = NO;
                        if (navCtr) {
                            navCtr.interactivePopGestureRecognizer.enabled = popGestureEnable;
                        }
                    }];
                }else{
                    [[CJSelectCopyManagerView instance] hideView];
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            //只移动放大镜
            if (self.enableCopy && ![CJSelectCopyManagerView instance].magnifierView.hidden) {
                //发生长按，显示放大镜
                CJGlyphRunStrokeItem *currentItem = [CJSelectCopyManagerView currentItem:point allRunItemArray:_allRunItemArray inset:1];
                if (currentItem) {
                    [[CJSelectCopyManagerView instance] showMagnifyInCJLabel:self magnifyPoint:point runItem:currentItem];
                }else{
                    if (CGRectContainsPoint(self.bounds, point)) {
                        [[CJSelectCopyManagerView instance] showMagnifyInCJLabel:self magnifyPoint:point runItem:nil];
                    }
                }
            }
        }
        default:
            break;
    }
}

+ (instancetype)instance {
    static CJLabel *manager = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        manager = [[CJLabel alloc]initWithFrame:CGRectMake(0, 0, 1, 1)];
        manager.numberOfLines = 0;
    });
    [manager setValue:@(YES) forKey:@"caculateSizeOnly"];
    return manager;
}

- (UIViewController *)topViewController {
    UIViewController *resultVC = nil;
    resultVC = [self _topViewController:[CJkeyWindow() rootViewController]];
    while (resultVC.presentedViewController) {
        resultVC = [self _topViewController:resultVC.presentedViewController];
    }
    return resultVC;
}

- (UIViewController *)_topViewController:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self _topViewController:[(UINavigationController *)vc topViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self _topViewController:[(UITabBarController *)vc selectedViewController]];
    } else {
        return vc;
    }
    return nil;
}

#pragma mark - Public Method
+ (CGSize)sizeWithAttributedString:(NSAttributedString *)attributedString withConstraints:(CGSize)size limitedToNumberOfLines:(NSUInteger)numberOfLines {
    return [CJLabel sizeWithAttributedString:attributedString withConstraints:size limitedToNumberOfLines:numberOfLines textInsets:UIEdgeInsetsZero];
}

+ (CGSize)sizeWithAttributedString:(NSAttributedString *)attributedString
                   withConstraints:(CGSize)size
            limitedToNumberOfLines:(NSUInteger)numberOfLines
                        textInsets:(UIEdgeInsets)textInsets {
    if (!attributedString || attributedString.length == 0) {
        return CGSizeZero;
    }
    
    [CJLabel instance].textInsets = textInsets;
    [CJLabel instance].numberOfLines = numberOfLines;
    [CJLabel instance].attributedText = attributedString;
    CGSize labeSize = [[CJLabel instance] sizeThatFits:size];
    //还原初始状态
    [CJLabel instance].textInsets = UIEdgeInsetsZero;
    [CJLabel instance].numberOfLines = 0;
    [CJLabel instance].attributedText = nil;
    CGSize caculateSize = CGSizeMake(size.width, labeSize.height);
    return caculateSize;
}

+ (CJLabelConfigure *)configureAttributes:(NSDictionary<NSString *, id> *)attributes
                                   isLink:(BOOL)isLink
                     activeLinkAttributes:(NSDictionary<NSString *, id> *)activeLinkAttributes
                                parameter:(id)parameter
                           clickLinkBlock:(CJLabelLinkModelBlock)clickLinkBlock
                           longPressBlock:(CJLabelLinkModelBlock)longPressBlock
{
    CJLabelConfigure *configure = [[CJLabelConfigure alloc]init];
    if (configure) {
        configure.attributes = attributes;
        configure.isLink = isLink;
        configure.activeLinkAttributes = activeLinkAttributes;
        configure.parameter = parameter;
        configure.clickLinkBlock = clickLinkBlock;
        configure.longPressBlock = longPressBlock;
    }
    return configure;
}

+ (NSMutableAttributedString *)initWithImage:(id)image imageSize:(CGSize)size imagelineAlignment:(CJLabelVerticalAlignment)lineAlignment configure:(CJLabelConfigure *)configure {
    NSAttributedString *attStr = [[NSAttributedString alloc]init];
    BOOL isLink = configure.isLink;
    NSMutableAttributedString *result = [CJLabelConfigure configureLinkAttributedString:attStr addImage:image imageSize:size atIndex:0 verticalAlignment:lineAlignment linkAttributes:configure.attributes activeLinkAttributes:configure.activeLinkAttributes parameter:configure.parameter clickLinkBlock:configure.clickLinkBlock longPressBlock:configure.longPressBlock islink:isLink];
    return result;
}

+ (NSMutableAttributedString *)initWithView:(id)view viewSize:(CGSize)size lineAlignment:(CJLabelVerticalAlignment)lineAlignment configure:(CJLabelConfigure *)configure {
    NSAttributedString *attStr = [[NSAttributedString alloc]init];
    BOOL isLink = configure.isLink;
    id insertView = view;
    if ([view isKindOfClass:[UIView class]]) {
        UIView *backView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        [(UIView *)view setFrame:CGRectMake(0, 0, size.width, size.height)];
        [(UIView *)view setAutoresizingMask:UIViewAutoresizingNone];
        backView.userInteractionEnabled = YES;
        [(UIView *)view setUserInteractionEnabled:YES];
        [(UIView *)view setTag:[kCJInsertViewTag hash]];
        [backView addSubview:view];
        insertView = backView;
    }
    NSMutableAttributedString *result = [CJLabelConfigure configureLinkAttributedString:attStr addImage:insertView imageSize:size atIndex:0 verticalAlignment:lineAlignment linkAttributes:configure.attributes activeLinkAttributes:configure.activeLinkAttributes parameter:configure.parameter clickLinkBlock:configure.clickLinkBlock longPressBlock:configure.longPressBlock islink:isLink];
    return result;
}

+ (NSMutableAttributedString *)insertImageAtAttrString:(NSAttributedString *)attrStr image:(id)image imageSize:(CGSize)size atIndex:(NSUInteger)loc imagelineAlignment:(CJLabelVerticalAlignment)lineAlignment configure:(CJLabelConfigure *)configure {
    BOOL isLink = configure.isLink;
    NSMutableAttributedString *result = [CJLabelConfigure configureLinkAttributedString:attrStr addImage:image imageSize:size atIndex:loc verticalAlignment:lineAlignment linkAttributes:configure.attributes activeLinkAttributes:configure.activeLinkAttributes parameter:configure.parameter clickLinkBlock:configure.clickLinkBlock longPressBlock:configure.longPressBlock islink:isLink];
    return result;
}

+ (NSMutableAttributedString *)insertViewAtAttrString:(NSAttributedString *)attrStr view:(id)view viewSize:(CGSize)size atIndex:(NSUInteger)loc lineAlignment:(CJLabelVerticalAlignment)lineAlignment configure:(CJLabelConfigure *)configure {
    BOOL isLink = configure.isLink;
    id insertView = view;
    if ([view isKindOfClass:[UIView class]]) {
        UIView *backView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        [(UIView *)view setFrame:CGRectMake(0, 0, size.width, size.height)];
        [(UIView *)view setAutoresizingMask:UIViewAutoresizingNone];
        backView.userInteractionEnabled = YES;
        [(UIView *)view setUserInteractionEnabled:YES];
        [(UIView *)view setTag:[kCJInsertViewTag hash]];
        [backView addSubview:view];
        insertView = backView;
    }
    NSMutableAttributedString *result = [CJLabelConfigure configureLinkAttributedString:attrStr addImage:insertView imageSize:size atIndex:loc verticalAlignment:lineAlignment linkAttributes:configure.attributes activeLinkAttributes:configure.activeLinkAttributes parameter:configure.parameter clickLinkBlock:configure.clickLinkBlock longPressBlock:configure.longPressBlock islink:isLink];
    return result;
}

+ (NSMutableAttributedString *)configureAttrString:(NSAttributedString *)attrStr atRange:(NSRange)range configure:(CJLabelConfigure *)configure {
    BOOL isLink = configure.isLink;
    NSMutableAttributedString *result = [CJLabelConfigure configureLinkAttributedString:attrStr atRange:range linkAttributes:configure.attributes activeLinkAttributes:configure.activeLinkAttributes parameter:configure.parameter clickLinkBlock:configure.clickLinkBlock longPressBlock:configure.longPressBlock islink:isLink];
    return result;
}

+ (NSMutableAttributedString *)initWithString:(NSString *)string configure:(CJLabelConfigure *)configure {
    NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:string];
    if (configure.attributes && configure.attributes.count > 0) {
        [attrStr setAttributes:configure.attributes range:NSMakeRange(0, attrStr.length)];
    }
    BOOL isLink = configure.isLink;
    NSMutableAttributedString *result = [CJLabelConfigure configureLinkAttributedString:attrStr atRange:NSMakeRange(0, attrStr.length) linkAttributes:configure.attributes activeLinkAttributes:configure.activeLinkAttributes parameter:configure.parameter clickLinkBlock:configure.clickLinkBlock longPressBlock:configure.longPressBlock islink:isLink];
    return result;
}

+ (NSMutableAttributedString *)initWithNSString:(NSString *)string strIdentifier:(NSString *)strIdentifier configure:(CJLabelConfigure *)configure {
    NSMutableAttributedString *attrStr = [CJLabelConfigure linkAttStr:string attributes:configure.attributes identifier:strIdentifier];
    BOOL isLink = configure.isLink;
    NSMutableAttributedString *result = [CJLabelConfigure configureLinkAttributedString:attrStr atRange:NSMakeRange(0, attrStr.length) linkAttributes:configure.attributes activeLinkAttributes:configure.activeLinkAttributes parameter:configure.parameter clickLinkBlock:configure.clickLinkBlock longPressBlock:configure.longPressBlock islink:isLink];
    return result;
}

+ (NSMutableAttributedString *)configureAttrString:(NSAttributedString *)attrStr withString:(NSString *)string sameStringEnable:(BOOL)sameStringEnable configure:(CJLabelConfigure *)configure {
    BOOL isLink = configure.isLink;
    NSMutableAttributedString *result = [CJLabelConfigure configureLinkAttributedString:attrStr withString:string sameStringEnable:sameStringEnable linkAttributes:configure.attributes activeLinkAttributes:configure.activeLinkAttributes parameter:configure.parameter clickLinkBlock:configure.clickLinkBlock longPressBlock:configure.longPressBlock islink:isLink];
    return result;
}

+ (NSMutableAttributedString *)initWithAttributedString:(NSAttributedString *)attributedString strIdentifier:(NSString *)strIdentifier configure:(CJLabelConfigure *)configure {
    
    NSMutableDictionary *linkStrDic = [NSMutableDictionary dictionaryWithCapacity:3];
    NSRange strRange = NSMakeRange(0, attributedString.length);
    NSDictionary *strDic = nil;
    if (strRange.length > 0) {
        strDic = [attributedString attributesAtIndex:0 effectiveRange:&strRange];
        [linkStrDic addEntriesFromDictionary:strDic];
    }
    if (configure.attributes && configure.attributes.count > 0) {
        [linkStrDic addEntriesFromDictionary:configure.attributes];
    }
    
    NSMutableAttributedString *attrStr = [CJLabelConfigure linkAttStr:attributedString.string attributes:linkStrDic identifier:strIdentifier];
    
    BOOL isLink = configure.isLink;
    NSMutableAttributedString *result = [CJLabelConfigure configureLinkAttributedString:attrStr atRange:NSMakeRange(0, attrStr.length) linkAttributes:configure.attributes activeLinkAttributes:configure.activeLinkAttributes parameter:configure.parameter clickLinkBlock:configure.clickLinkBlock longPressBlock:configure.longPressBlock islink:isLink];
    return result;
}

+ (NSMutableAttributedString *)configureAttrString:(NSAttributedString *)attrString withAttributedString:(NSAttributedString *)attributedString strIdentifier:(NSString *)strIdentifier sameStringEnable:(BOOL)sameStringEnable configure:(CJLabelConfigure *)configure {
    
    NSRange strRange = NSMakeRange(0, attributedString.length);
    NSDictionary *strDic = nil;
    if (strRange.length > 0) {
        strDic = [attributedString attributesAtIndex:0 effectiveRange:&strRange];
    }
    
    NSString *linkIdentifier = strDic[kCJLinkStringIdentifierAttributesName];
    
    if (strIdentifier.length > 0) {
        NSAssert([linkIdentifier isEqualToString:strIdentifier], @"\"withAttributedString\"必须包含\"kCJLinkStringIdentifierAttributesName\"属性；并且如果属性值为\"linkIdentifier\"，则必须保证\"[linkIdentifier isEqualToString:strIdentifier]\"");
        
        NSAttributedString *linkStr = [CJLabelConfigure linkAttStr:attributedString.string attributes:strDic identifier:linkIdentifier];
        BOOL isLink = configure.isLink;
        NSMutableAttributedString *result = [CJLabelConfigure configureLinkAttributedString:attrString withAttString:linkStr sameStringEnable:sameStringEnable linkAttributes:configure.attributes activeLinkAttributes:configure.activeLinkAttributes parameter:configure.parameter clickLinkBlock:configure.clickLinkBlock longPressBlock:configure.longPressBlock islink:isLink];
        return result;
    }
    else{
        NSMutableAttributedString *result = [CJLabel configureAttrString:attrString withString:attributedString.string sameStringEnable:sameStringEnable configure:configure];
        return result;
    }
}


+ (NSArray <NSValue *>*)sameLinkStringRangeArray:(NSString *)linkString inAttString:(NSAttributedString *)attString {
    return [CJLabelConfigure getLinkStringRangeArray:linkString inAttString:attString];
}

+ (NSArray <NSValue *>*)samelinkAttStringRangeArray:(NSAttributedString *)linkAttString strIdentifier:(NSString *)strIdentifier inAttString:(NSAttributedString *)attString {
    NSRange strRange = NSMakeRange(0, linkAttString.length);
    NSDictionary *strDic = nil;
    if (strRange.length > 0) {
        strDic = [linkAttString attributesAtIndex:0 effectiveRange:&strRange];
    }
    NSAttributedString *linkStr = [CJLabelConfigure linkAttStr:linkAttString.string attributes:strDic identifier:strIdentifier];
    return [CJLabelConfigure getLinkAttStringRangeArray:linkStr inAttString:attString];
}

- (NSAttributedString *)removeLinkAtRange:(NSRange)linkRange {
    NSParameterAssert((linkRange.location + linkRange.length) <= self.attributedText.length);
    
    NSMutableAttributedString *attText = [[NSMutableAttributedString alloc]initWithAttributedString:self.attributedText];
    [attText enumerateAttributesInRange:NSMakeRange(0, attText.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary<NSString *, id> *attrs, NSRange range, BOOL *stop){
        BOOL isLink = [attrs[kCJIsLinkAttributesName] boolValue];
        if (isLink) {
            if ((linkRange.location <= range.location + range.length) &&
                (linkRange.location+linkRange.length <= range.location + range.length))
            {
                [attText removeAttribute:kCJLinkAttributesName range:linkRange];
                [attText removeAttribute:kCJActiveLinkAttributesName range:linkRange];
                [attText removeAttribute:kCJIsLinkAttributesName range:linkRange];
                [attText removeAttribute:kCJLinkRangeAttributesName range:linkRange];
                [attText removeAttribute:kCJLinkLengthAttributesName range:linkRange];
                [attText removeAttribute:kCJLinkNeedRedrawnAttributesName range:linkRange];
                
                [attText removeAttribute:kCJBackgroundFillColorAttributeName range:linkRange];
                [attText removeAttribute:kCJBackgroundStrokeColorAttributeName range:linkRange];
                [attText removeAttribute:kCJBackgroundLineWidthAttributeName range:linkRange];
                [attText removeAttribute:kCJBackgroundLineCornerRadiusAttributeName range:linkRange];
                [attText removeAttribute:kCJActiveBackgroundFillColorAttributeName range:linkRange];
                [attText removeAttribute:kCJActiveBackgroundStrokeColorAttributeName range:linkRange];
                
            }
        }
        
    }];
    
    [self setNeedsFramesetter];
    self.attributedText = attText;
    
    //立即刷新界面
    [CATransaction flush];
    return self.attributedText;
}

- (NSAttributedString *)removeAllLink {
    
    NSMutableAttributedString *newAttributedText = [[NSMutableAttributedString alloc]initWithAttributedString:self.attributedText];
    
    [newAttributedText enumerateAttributesInRange:NSMakeRange(0, newAttributedText.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary<NSString *, id> *attrs, NSRange range, BOOL *stop){
        BOOL isLink = [attrs[kCJIsLinkAttributesName] boolValue];
        if (isLink)
        {
            [newAttributedText removeAttribute:kCJLinkAttributesName range:range];
            [newAttributedText removeAttribute:kCJActiveLinkAttributesName range:range];
            [newAttributedText removeAttribute:kCJIsLinkAttributesName range:range];
            [newAttributedText removeAttribute:kCJLinkRangeAttributesName range:range];
            [newAttributedText removeAttribute:kCJLinkNeedRedrawnAttributesName range:range];
            
            [newAttributedText removeAttribute:kCJBackgroundFillColorAttributeName range:range];
            [newAttributedText removeAttribute:kCJBackgroundStrokeColorAttributeName range:range];
            [newAttributedText removeAttribute:kCJBackgroundLineWidthAttributeName range:range];
            [newAttributedText removeAttribute:kCJBackgroundLineCornerRadiusAttributeName range:range];
            [newAttributedText removeAttribute:kCJActiveBackgroundFillColorAttributeName range:range];
            [newAttributedText removeAttribute:kCJActiveBackgroundStrokeColorAttributeName range:range];
            
        }
    }];
    
    [self setNeedsFramesetter];
    self.attributedText = newAttributedText;
    
    //立即刷新界面
    [CATransaction flush];
    return self.attributedText;
}

- (void)flushText {
    [_allRunItemArray removeAllObjects];
    [self setNeedsFramesetter];
    [self setNeedsDisplay];
    //立即刷新界面
    [CATransaction flush];
}

@end
