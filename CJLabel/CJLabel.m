//
//  CJLabel.m
//  CJLabelTest
//
//  Created by ChiJinLian on 17/3/31.
//  Copyright © 2017年 ChiJinLian. All rights reserved.
//

#import "CJLabel.h"
#import "CJLabelUtilities.h"

@class CJGlyphRunStrokeItem;

NSString * const kCJBackgroundFillColorAttributeName         = @"kCJBackgroundFillColor";
NSString * const kCJBackgroundStrokeColorAttributeName       = @"kCJBackgroundStrokeColor";
NSString * const kCJBackgroundLineWidthAttributeName         = @"kCJBackgroundLineWidth";
NSString * const kCJBackgroundLineCornerRadiusAttributeName  = @"kCJBackgroundLineCornerRadius";
NSString * const kCJActiveBackgroundFillColorAttributeName   = @"kCJActiveBackgroundFillColor";
NSString * const kCJActiveBackgroundStrokeColorAttributeName = @"kCJActiveBackgroundStrokeColor";

static CGFloat const CJFLOAT_MAX = 100000;

static inline CGFLOAT_TYPE CGFloat_ceil(CGFLOAT_TYPE cgfloat) {
#if CGFLOAT_IS_DOUBLE
    return ceil(cgfloat);
#else
    return ceilf(cgfloat);
#endif
}

static inline CGFLOAT_TYPE CGFloat_floor(CGFLOAT_TYPE cgfloat) {
#if CGFLOAT_IS_DOUBLE
    return floor(cgfloat);
#else
    return floorf(cgfloat);
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

static inline CGColorRef CGColorRefFromColor(id color) {
    return [color isKindOfClass:[UIColor class]] ? [color CGColor] : (__bridge CGColorRef)color;
}

static inline NSAttributedString * NSAttributedStringByScalingFontSize(NSAttributedString *attributedString, CGFloat scale) {
    NSMutableAttributedString *mutableAttributedString = [attributedString mutableCopy];
    [mutableAttributedString enumerateAttribute:(NSString *)kCTFontAttributeName inRange:NSMakeRange(0, [mutableAttributedString length]) options:0 usingBlock:^(id value, NSRange range, BOOL * __unused stop) {
        UIFont *font = (UIFont *)value;
        if (font) {
            NSString *fontName;
            CGFloat pointSize;
            
            if ([font isKindOfClass:[UIFont class]]) {
                fontName = font.fontName;
                pointSize = font.pointSize;
            } else {
                fontName = (NSString *)CFBridgingRelease(CTFontCopyName((__bridge CTFontRef)font, kCTFontPostScriptNameKey));
                pointSize = CTFontGetSize((__bridge CTFontRef)font);
            }
            
            [mutableAttributedString removeAttribute:(NSString *)kCTFontAttributeName range:range];
            CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)fontName, CGFloat_floor(pointSize * scale), NULL);
            [mutableAttributedString addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)fontRef range:range];
            CFRelease(fontRef);
        }
    }];
    
    return mutableAttributedString;
}

static inline CGSize CTFramesetterSuggestFrameSizeForAttributedStringWithConstraints(CTFramesetterRef framesetter, NSAttributedString *attributedString, CGSize size, NSUInteger numberOfLines) {
    CFRange rangeToSize = CFRangeMake(0, (CFIndex)[attributedString length]);
    CGSize constraints = CGSizeMake(size.width, CJFLOAT_MAX);
    
    if (numberOfLines == 1) {
        constraints = CGSizeMake(CJFLOAT_MAX, CJFLOAT_MAX);
    } else if (numberOfLines > 0) {
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
};

static inline CGFloat compareMaxNum(CGFloat firstNum, CGFloat secondNum, BOOL max){
    CGFloat result = firstNum;
    if (max) {
        result = (firstNum >= secondNum)?firstNum:secondNum;
    }else{
        result = (firstNum <= secondNum)?firstNum:secondNum;
    }
    return result;
}

static inline UIColor * colorWithAttributeName(NSDictionary *dic, NSString *key){
    UIColor *color = nil;
    if (dic[key] && nil != dic[key]) {
        color = dic[key];
    }
    return color;
}

static inline BOOL isNotClearColor(UIColor *color){
    if (CJLabelIsNull(color)) {
        return NO;
    }
    BOOL notClearColor = YES;
    if (CGColorEqualToColor(color.CGColor, [UIColor clearColor].CGColor)) {
        notClearColor = NO;
    }
    return notClearColor;
}

static inline BOOL isSameColor(UIColor *color1, UIColor *color2){
    BOOL same = YES;
    if (!CGColorEqualToColor(color1.CGColor, color2.CGColor)) {
        same = NO;
    }
    return same;
}

/**
 当CTLine包含插入图片时，描述当前行文字在垂直方向的对齐方式
 */
struct CJCTLineVerticalLayout {
    CFIndex line;//第几行
    CGFloat maxRunHight;//当前行run的最大高度（不包括图片）
    CGFloat lineHight;//行高
    CGFloat maxImageHight;//行高
    CJLabelVerticalAlignment verticalAlignment;//对齐方式（默认底部对齐）
};
typedef struct CJCTLineVerticalLayout CJCTLineVerticalLayout;


@interface CJLabel ()<UIGestureRecognizerDelegate>

//当前显示的AttributedText
@property (readwrite, nonatomic, copy) NSAttributedString *renderedAttributedText;
@property (readonly, nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@end

@implementation CJLabel {
@private
    BOOL _needsFramesetter;
    NSInteger _numberOfLines;
    CTFramesetterRef _framesetter;
    CTFramesetterRef _highlightFramesetter;
    CGFloat _yOffset;
    NSDictionary *_normalAttDic;
    BOOL _longPress;//判断是否长按;
    BOOL _needRedrawn;//是否需要重新计算_runStrokeItemArray以及_linkStrokeItemArray数组
    NSArray <CJGlyphRunStrokeItem *>*_runStrokeItemArray;//所有需要重绘背景或边框线的StrokeItem数组
    NSArray <CJGlyphRunStrokeItem *>*_linkStrokeItemArray;//可点击链点的StrokeItem数组
    CJGlyphRunStrokeItem *_lastGlyphRunStrokeItem;//计算StrokeItem的中间变量
    CJGlyphRunStrokeItem *_currentClickRunStrokeItem;//当前点击选中的StrokeItem
    NSArray *_CTLineVerticalLayoutArray;//记录 包含插入图片的CTLine在垂直方向的对齐方式的数组
}


@synthesize text = _text;
@synthesize attributedText = _attributedText;

#pragma mark - Public Method
+ (CGSize)sizeWithAttributedString:(NSAttributedString *)attributedString
                   withConstraints:(CGSize)size
            limitedToNumberOfLines:(NSUInteger)numberOfLines
{
    if (!attributedString || attributedString.length == 0) {
        return CGSizeZero;
    }
    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);
    
    CGSize calculatedSize = CTFramesetterSuggestFrameSizeForAttributedStringWithConstraints(framesetter, attributedString, size, numberOfLines);
    
    CFRelease(framesetter);
    
    return calculatedSize;
}

+ (NSMutableAttributedString *)configureAttributedString:(NSAttributedString *)attrStr
                                            addImageName:(NSString *)imageName
                                               imageSize:(CGSize)size
                                                 atIndex:(NSUInteger)loc
                                              attributes:(NSDictionary *)attributes
{
    return [self configureAttributedString:attrStr addImageName:imageName imageSize:size atIndex:loc verticalAlignment:CJVerticalAlignmentBottom attributes:attributes];
}

+ (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
                                                addImageName:(NSString *)imageName
                                                   imageSize:(CGSize)size
                                                     atIndex:(NSUInteger)loc
                                              linkAttributes:(NSDictionary *)linkAttributes
                                        activeLinkAttributes:(NSDictionary *)activeLinkAttributes
                                                   parameter:(id)parameter
                                              clickLinkBlock:(CJLabelLinkModelBlock)clickLinkBlock
                                              longPressBlock:(CJLabelLinkModelBlock)longPressBlock
{
    return [self configureLinkAttributedString:attrStr addImageName:imageName imageSize:size atIndex:loc verticalAlignment:CJVerticalAlignmentBottom linkAttributes:linkAttributes activeLinkAttributes:activeLinkAttributes parameter:parameter clickLinkBlock:clickLinkBlock longPressBlock:longPressBlock];
}

+ (NSMutableAttributedString *)configureAttributedString:(NSAttributedString *)attrStr
                                            addImageName:(NSString *)imageName
                                               imageSize:(CGSize)size
                                                 atIndex:(NSUInteger)loc
                                       verticalAlignment:(CJLabelVerticalAlignment)verticalAlignment
                                              attributes:(NSDictionary *)attributes
{
    return [CJLabelUtilities configureLinkAttributedString:attrStr addImageName:imageName imageSize:size atIndex:loc verticalAlignment:verticalAlignment linkAttributes:attributes activeLinkAttributes:nil parameter:nil clickLinkBlock:nil longPressBlock:nil islink:NO];
}

+ (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
                                                addImageName:(NSString *)imageName
                                                   imageSize:(CGSize)size
                                                     atIndex:(NSUInteger)loc
                                           verticalAlignment:(CJLabelVerticalAlignment)verticalAlignment
                                              linkAttributes:(NSDictionary *)linkAttributes
                                        activeLinkAttributes:(NSDictionary *)activeLinkAttributes
                                                   parameter:(id)parameter
                                              clickLinkBlock:(CJLabelLinkModelBlock)clickLinkBlock
                                              longPressBlock:(CJLabelLinkModelBlock)longPressBlock
{
    return [CJLabelUtilities configureLinkAttributedString:attrStr addImageName:imageName imageSize:size atIndex:loc verticalAlignment:verticalAlignment linkAttributes:linkAttributes activeLinkAttributes:activeLinkAttributes parameter:parameter clickLinkBlock:clickLinkBlock longPressBlock:longPressBlock islink:YES];
}

+ (NSMutableAttributedString *)configureAttributedString:(NSAttributedString *)attrStr
                                                 atRange:(NSRange)range
                                              attributes:(NSDictionary *)attributes
{
    return [CJLabelUtilities configureLinkAttributedString:attrStr atRange:range linkAttributes:attributes activeLinkAttributes:nil parameter:nil clickLinkBlock:nil longPressBlock:nil islink:NO];
}

+ (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
                                                     atRange:(NSRange)range
                                              linkAttributes:(NSDictionary *)linkAttributes
                                        activeLinkAttributes:(NSDictionary *)activeLinkAttributes
                                                   parameter:(id)parameter
                                              clickLinkBlock:(CJLabelLinkModelBlock)clickLinkBlock
                                              longPressBlock:(CJLabelLinkModelBlock)longPressBlock
{
    return [CJLabelUtilities configureLinkAttributedString:attrStr atRange:range linkAttributes:linkAttributes activeLinkAttributes:activeLinkAttributes parameter:parameter clickLinkBlock:clickLinkBlock longPressBlock:longPressBlock islink:YES];
}

+ (NSMutableAttributedString *)configureAttributedString:(NSAttributedString *)attrStr
                                              withString:(NSString *)withString
                                        sameStringEnable:(BOOL)sameStringEnable
                                              attributes:(NSDictionary *)attributes
{
    return [CJLabelUtilities configureLinkAttributedString:attrStr withString:withString sameStringEnable:sameStringEnable linkAttributes:attributes activeLinkAttributes:nil parameter:nil clickLinkBlock:nil longPressBlock:nil islink:NO];
}

+ (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
                                                  withString:(NSString *)withString
                                            sameStringEnable:(BOOL)sameStringEnable
                                              linkAttributes:(NSDictionary *)linkAttributes
                                        activeLinkAttributes:(NSDictionary *)activeLinkAttributes
                                                   parameter:(id)parameter
                                              clickLinkBlock:(CJLabelLinkModelBlock)clickLinkBlock
                                              longPressBlock:(CJLabelLinkModelBlock)longPressBlock
{
    return [CJLabelUtilities configureLinkAttributedString:attrStr withString:withString sameStringEnable:sameStringEnable linkAttributes:linkAttributes activeLinkAttributes:activeLinkAttributes parameter:parameter clickLinkBlock:clickLinkBlock longPressBlock:longPressBlock islink:YES];
}

- (NSAttributedString *)removeLinkAtRange:(NSRange)linkRange {
    NSParameterAssert((linkRange.location + linkRange.length) <= self.attributedText.length);
    
    NSMutableAttributedString *attText = [[NSMutableAttributedString alloc]initWithAttributedString:self.attributedText];
    [attText enumerateAttributesInRange:NSMakeRange(0, attText.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary<NSString *, id> *attrs, NSRange range, BOOL *stop){
        BOOL isLink = [attrs[kCJIsLinkAttributesName] boolValue];
        if (isLink &&
            (linkRange.location >= range.location) &&
            (linkRange.location <= range.location+range.length) &&
            (linkRange.location+linkRange.length <= range.location + range.length))
        {
            [attText removeAttribute:kCJLinkAttributesName range:linkRange];
            [attText removeAttribute:kCJActiveLinkAttributesName range:linkRange];
            [attText removeAttribute:kCJIsLinkAttributesName range:linkRange];
            [attText removeAttribute:kCJLinkRangeAttributesName range:linkRange];
            [attText removeAttribute:kCJLinkNeedRedrawnAttributesName range:linkRange];
            
            [attText removeAttribute:kCJBackgroundFillColorAttributeName range:linkRange];
            [attText removeAttribute:kCJBackgroundStrokeColorAttributeName range:linkRange];
            [attText removeAttribute:kCJBackgroundLineWidthAttributeName range:linkRange];
            [attText removeAttribute:kCJBackgroundLineCornerRadiusAttributeName range:linkRange];
            [attText removeAttribute:kCJActiveBackgroundFillColorAttributeName range:linkRange];
            [attText removeAttribute:kCJActiveBackgroundStrokeColorAttributeName range:linkRange];
            
        }
    }];
    
//    _runStrokeItemArray = nil;
//    _linkStrokeItemArray = nil;
//    _CTLineVerticalLayoutArray = nil;
//    _numberOfLines = -1;
//    _needRedrawn = YES;
    
    
    [self setNeedsFramesetter];
    self.attributedText = attText;
//    [self setNeedsDisplay];
    //立即刷新界面
    [CATransaction flush];
    return self.attributedText;
}

- (NSAttributedString *)removeAllLink{
    
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
    
//    _runStrokeItemArray = nil;
//    _linkStrokeItemArray = nil;
//    _CTLineVerticalLayoutArray = nil;
//    _numberOfLines = -1;
//    _needRedrawn = YES;
    
    [self setNeedsFramesetter];
    self.attributedText = newAttributedText;
    
    
//    [self setNeedsDisplay];
    //立即刷新界面
    [CATransaction flush];
    return self.attributedText;
}

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
    self.textInsets = UIEdgeInsetsZero;
    self.verticalAlignment = CJVerticalAlignmentCenter;
    _numberOfLines = -1;
    _needRedrawn = YES;
    _longPress = NO;
    _extendsLinkTouchArea = NO;
    _lastGlyphRunStrokeItem = nil;
    _linkStrokeItemArray = nil;
    _runStrokeItemArray = nil;
    _currentClickRunStrokeItem = nil;
    _CTLineVerticalLayoutArray = nil;
    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(longPressGestureDidFire:)];
    self.longPressGestureRecognizer.delegate = self;
    [self addGestureRecognizer:self.longPressGestureRecognizer];
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
    self.delegate = nil;
}

- (void)setText:(id)text {
    NSParameterAssert(!text || [text isKindOfClass:[NSAttributedString class]] || [text isKindOfClass:[NSString class]]);
    
    NSMutableAttributedString *mutableAttributedString = nil;
    if ([text isKindOfClass:[NSString class]]) {
        NSMutableDictionary *mutableAttributes = [NSMutableDictionary dictionary];
        [mutableAttributes setObject:self.font forKey:(NSString *)kCTFontAttributeName];
        [mutableAttributes setObject:self.textColor forKey:(NSString *)kCTForegroundColorAttributeName];
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.alignment = self.textAlignment;
        if (self.numberOfLines == 1) {
            paragraphStyle.lineBreakMode = self.lineBreakMode;
        } else {
            paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        }
        [mutableAttributes setObject:paragraphStyle forKey:(NSString *)kCTParagraphStyleAttributeName];
        mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:mutableAttributes];
    }else{
        mutableAttributedString = text;
    }
    self.attributedText = mutableAttributedString;
}

- (void)setAttributedText:(NSAttributedString *)text {
    if ([text isEqualToAttributedString:_attributedText]) {
        return;
    }
    
    _needRedrawn = YES;
    _longPress = NO;
    _runStrokeItemArray = nil;
    _linkStrokeItemArray = nil;
    _CTLineVerticalLayoutArray = nil;
    _currentClickRunStrokeItem = nil;
    
    //获取点击链点的NSRange
    NSMutableAttributedString *attText = [[NSMutableAttributedString alloc]initWithAttributedString:text];

    [attText enumerateAttributesInRange:NSMakeRange(0, attText.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary<NSString *, id> *attrs, NSRange range, BOOL *stop){
        BOOL isLink = [attrs[kCJIsLinkAttributesName] boolValue];
        if (isLink) {
            [attText addAttribute:kCJLinkRangeAttributesName value:NSStringFromRange(range) range:range];
        }else{
            [attText removeAttribute:kCJLinkRangeAttributesName range:range];
            if (!_normalAttDic &&
                CJLabelIsNull(attrs[kCJBackgroundFillColorAttributeName]) &&
                CJLabelIsNull(attrs[kCJBackgroundStrokeColorAttributeName]) &&
                CJLabelIsNull(attrs[kCJBackgroundLineWidthAttributeName]) &&
                CJLabelIsNull(attrs[kCJBackgroundLineCornerRadiusAttributeName]) &&
                CJLabelIsNull(attrs[kCJActiveBackgroundFillColorAttributeName]) &&
                CJLabelIsNull(attrs[kCJActiveBackgroundStrokeColorAttributeName])
                              ) {
                _normalAttDic = attrs;
            }
        }
    }];
    
    _attributedText = [attText copy];
    
    [self setNeedsFramesetter];
    [self setNeedsDisplay];
    
    if ([self respondsToSelector:@selector(invalidateIntrinsicContentSize)]) {
        [self invalidateIntrinsicContentSize];
    }
    
    [super setText:[self.attributedText string]];
}

- (NSAttributedString *)renderedAttributedText {
    if (!_renderedAttributedText) {
        NSMutableAttributedString *fullString = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
        
        [fullString enumerateAttributesInRange:NSMakeRange(0, fullString.length) options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired usingBlock:^(NSDictionary<NSString *, id> *attrs, NSRange range, BOOL *stop){
            
            NSDictionary *linkAttributes = attrs[kCJLinkAttributesName];
            if (!CJLabelIsNull(linkAttributes)) {
                [fullString addAttributes:linkAttributes range:range];
            }
            
            NSDictionary *activeLinkAttributes = attrs[kCJActiveLinkAttributesName];
            if (!CJLabelIsNull(activeLinkAttributes)) {
                //设置当前点击链点的activeLinkAttributes属性
                if (_currentClickRunStrokeItem && NSEqualRanges(_currentClickRunStrokeItem.range,range)) {
                    [fullString addAttributes:activeLinkAttributes range:range];
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
        }];
        
        NSAttributedString *string = [[NSAttributedString alloc] initWithAttributedString:fullString];
        self.renderedAttributedText = string;
    }
    
    return _renderedAttributedText;
}

- (void)setNeedsFramesetter {
    self.renderedAttributedText = nil;
    _needsFramesetter = YES;
    
    _runStrokeItemArray = nil;
    _linkStrokeItemArray = nil;
    _CTLineVerticalLayoutArray = nil;
    _numberOfLines = -1;
    _needRedrawn = YES;
    
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


#pragma mark - UILabel
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

- (CGRect)textRectForBounds:(CGRect)bounds
     limitedToNumberOfLines:(NSInteger)numberOfLines
{
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
        // CTM 坐标移到左下角
        CGContextTranslateCTM(c, insetRect.origin.x, insetRect.size.height - textRect.origin.y - textRect.size.height);
        
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
}

#pragma mark - Draw Method
- (void)drawFramesetter:(CTFramesetterRef)framesetter
       attributedString:(NSAttributedString *)attributedString
              textRange:(CFRange)textRange
                 inRect:(CGRect)rect
                context:(CGContextRef)c
{
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, rect);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, textRange, path, NULL);
    
    if (_needRedrawn) {
        
        NSArray *lines = (__bridge NSArray *)CTFrameGetLines(frame);
        CGPoint origins[[lines count]];
        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), origins);
        
        if (_numberOfLines == -1) {
            _numberOfLines = self.numberOfLines > 0 ? MIN(self.numberOfLines, lines.count) : lines.count;
        }
        
        _CTLineVerticalLayoutArray = [self allCTLineVerticalLayoutArray:lines origins:origins inRect:rect];
        // 获取所有需要重绘背景的StrokeItem数组
        _runStrokeItemArray = [self calculateRunStrokeItemsFrame:lines origins:origins inRect:rect];
        _linkStrokeItemArray = [self getLinkStrokeItems:_runStrokeItemArray];
    }
//    if (!_runStrokeItemArray) {
//        _CTLineVerticalLayoutArray = [self allCTLineVerticalLayoutArray:frame inRect:rect];
//        // 获取所有需要重绘背景的StrokeItem数组
//        _runStrokeItemArray = [self calculateRunStrokeItemsFrame:frame inRect:rect];
//        _linkStrokeItemArray = [self getLinkStrokeItems:_runStrokeItemArray];
//    }
    [self drawBackgroundColor:c runStrokeItems:_runStrokeItemArray isStrokeColor:NO];
    
    
    CFArrayRef lines = CTFrameGetLines(frame);
    if (_numberOfLines == -1) {
        _numberOfLines = self.numberOfLines > 0 ? MIN(self.numberOfLines, CFArrayGetCount(lines)) : CFArrayGetCount(lines);
    }
    
    BOOL truncateLastLine = (self.lineBreakMode == NSLineBreakByTruncatingHead || self.lineBreakMode == NSLineBreakByTruncatingMiddle || self.lineBreakMode == NSLineBreakByTruncatingTail);
    
    CGPoint lineOrigins[_numberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, _numberOfLines), lineOrigins);

    for (CFIndex lineIndex = 0; lineIndex < _numberOfLines; lineIndex++) {
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CGContextSetTextPosition(c, lineOrigin.x, lineOrigin.y);
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        
//        CGFloat ascent = 0.0f, descent = 0.0f, leading = 0.0f;
//        CTLineGetTypographicBounds((CTLineRef)line, &ascent, &descent, &leading);
        
        // 根据水平对齐方式调整偏移量
        CGFloat flushFactor = CJFlushFactorForTextAlignment(self.textAlignment);
        
        if (lineIndex == _numberOfLines - 1 && truncateLastLine) {
            // 判断最后一行是否占满整行
            CFRange lastLineRange = CTLineGetStringRange(line);
            
            if (!(lastLineRange.length == 0 && lastLineRange.location == 0) && lastLineRange.location + lastLineRange.length < textRange.location + textRange.length) {

                CTLineTruncationType truncationType;
                CFIndex truncationAttributePosition = lastLineRange.location;
                NSLineBreakMode lineBreakMode = self.lineBreakMode;
                
                // 多行时lineBreakMode默认为NSLineBreakByTruncatingTail
                if (_numberOfLines != 1) {
                    lineBreakMode = NSLineBreakByTruncatingTail;
                }
                
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
                
                NSString *truncationTokenString = @"\u2026"; // \u2026 对应"..."的Unicode编码
                
                NSDictionary *truncationTokenStringAttributes = truncationTokenStringAttributes = [attributedString attributesAtIndex:(NSUInteger)truncationAttributePosition effectiveRange:NULL];
                
                NSAttributedString *attributedTruncationString = [[NSAttributedString alloc] initWithString:truncationTokenString attributes:truncationTokenStringAttributes];
                
                CTLineRef truncationToken = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attributedTruncationString);
                
                // 获取最后一行的NSAttributedString
                NSMutableAttributedString *truncationString = [[NSMutableAttributedString alloc] initWithAttributedString:
                                                               [attributedString attributedSubstringFromRange:
                                                                NSMakeRange((NSUInteger)lastLineRange.location,
                                                                            (NSUInteger)lastLineRange.length)]];
                if (lastLineRange.length > 0) {
                    // 判断最后一行的最后是不是完整单词，避免出现 "..." 前十不完整单词的情况
                    unichar lastCharacter = [[truncationString string] characterAtIndex:(NSUInteger)(lastLineRange.length - 1)];
                    if ([[NSCharacterSet newlineCharacterSet] characterIsMember:lastCharacter]) {
                        [truncationString deleteCharactersInRange:NSMakeRange((NSUInteger)(lastLineRange.length - 1), 1)];
                    }
                }
                [truncationString appendAttributedString:attributedTruncationString];
                CTLineRef truncationLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncationString);
                
                // 截取CTLine，以防其过长
                CTLineRef truncatedLine = CTLineCreateTruncatedLine(truncationLine, rect.size.width, truncationType, truncationToken);
                if (!truncatedLine) {
                    // 不存在，则取truncationToken
                    truncatedLine = CFRetain(truncationToken);
                }
                
                CGFloat penOffset = (CGFloat)CTLineGetPenOffsetForFlush(truncatedLine, flushFactor, rect.size.width);
//                CGContextSetTextPosition(c, penOffset, y );
//                CTLineDraw(truncatedLine, c);
                [self drawCTRun:c line:truncatedLine x:penOffset y:lineOrigin.y lineIndex:lineIndex lineOrigin:lineOrigin inRect:rect];
                
                CFRelease(truncatedLine);
                CFRelease(truncationLine);
                CFRelease(truncationToken);
            } else {
                CGFloat penOffset = (CGFloat)CTLineGetPenOffsetForFlush(line, flushFactor, rect.size.width);
//                CGContextSetTextPosition(c, penOffset, y );
//                CTLineDraw(line, c);
                [self drawCTRun:c line:line x:penOffset y:lineOrigin.y lineIndex:lineIndex lineOrigin:lineOrigin inRect:rect];
            }
        }
        else {
            CGFloat penOffset = (CGFloat)CTLineGetPenOffsetForFlush(line, flushFactor, rect.size.width);
//            CGContextSetTextPosition(c, penOffset, y );
//            CTLineDraw(line, c);
            [self drawCTRun:c line:line x:penOffset y:lineOrigin.y lineIndex:lineIndex lineOrigin:lineOrigin inRect:rect];
        }
        
    }
    
    // 绘制描边
    [self drawBackgroundColor:c runStrokeItems:_runStrokeItemArray isStrokeColor:YES];
    
    CFRelease(frame);
    CGPathRelease(path);
}

- (CGFloat)yOffset:(CGFloat)y lineVerticalLayout:(CJCTLineVerticalLayout)lineVerticalLayout lineDescent:(CGFloat)lineDescent isImage:(BOOL)isImage imageHight:(CGFloat)imageHight imageVerticalAlignment:(CJLabelVerticalAlignment)imageVerticalAlignment {
    CGFloat lineHight = lineVerticalLayout.lineHight;
    CGFloat maxRunHight = lineVerticalLayout.maxRunHight;
    CGFloat maxImageHight = lineVerticalLayout.maxImageHight;
    
    CJLabelVerticalAlignment verticalAlignment = lineVerticalLayout.verticalAlignment;
    if (isImage) {
        verticalAlignment = imageVerticalAlignment;
    }
    
    CGFloat yy = y;
    if (verticalAlignment == CJVerticalAlignmentBottom) {
        if (isImage) {
            yy = y - lineDescent - self.font.descender;
            if (imageHight >= maxRunHight && imageHight >= maxImageHight) {
                yy = y - lineDescent + (lineHight-imageHight)/2.0;
            }
        }
    }
    else if (verticalAlignment == CJVerticalAlignmentCenter) {
        if (isImage) {
            yy = y - lineDescent + (lineHight-imageHight)/2.0;
        }else{
            if (maxImageHight >= maxRunHight) {
                yy = y + (lineHight-maxRunHight)/2.0;
            }
        }
    }
    else if (verticalAlignment == CJVerticalAlignmentTop) {
        if (isImage) {
            yy = y - lineDescent + (lineHight-imageHight) + self.font.descender;
            if (imageHight >= maxRunHight && imageHight >= maxImageHight) {
                yy = y - lineDescent + (lineHight-imageHight)/2.0;
            }
        }else{
            if (maxImageHight >= maxRunHight) {
                yy = y + (lineHight-maxRunHight);
            }
        }
    }
    return yy;
}

- (void)drawCTRun:(CGContextRef)c line:(CTLineRef)line x:(CGFloat)x y:(CGFloat)y lineIndex:(CFIndex)lineIndex lineOrigin:(CGPoint)lineOrigin inRect:(CGRect)rect {
    
    CJCTLineVerticalLayout lineVerticalLayout = {0,0,0};
    CGFloat lineAscent = 0.0f, lineDescent = 0.0f, lineLeading = 0.0f;
    CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
    
    lineVerticalLayout.line = lineIndex;
    lineVerticalLayout.maxRunHight = lineAscent + lineDescent + lineLeading;
    lineVerticalLayout.lineHight = lineAscent + lineDescent + lineLeading;
    
    for (NSValue *value in _CTLineVerticalLayoutArray) {
        CJCTLineVerticalLayout themLineVerticalLayout;
        [value getValue:&themLineVerticalLayout];
        if (themLineVerticalLayout.line == lineIndex) {
            lineVerticalLayout = themLineVerticalLayout;
            break;
        }
    }
    
    CFArrayRef runs = CTLineGetGlyphRuns(line);
    for (CFIndex j = 0; j < CFArrayGetCount(runs); ++j) {
        CTRunRef run = CFArrayGetValueAtIndex(runs, j);
        NSDictionary *attributes = (__bridge NSDictionary *)CTRunGetAttributes(run);
        NSDictionary *imgInfoDic = attributes[kCJImageAttributeName];
        
        CGRect runRect;
        CGFloat runAscent = 0, runDescent = 0;
        //调整CTRun的rect
        runRect.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0,0), &runAscent, &runDescent, NULL);
        
        BOOL isImage = YES;
        CGFloat imageHight = 0;
        CJLabelVerticalAlignment imageVerticalAlignment = CJVerticalAlignmentBottom;
        if (CJLabelIsNull(imgInfoDic)) {
            isImage = NO;
        }else{
            imageHight = runAscent + runDescent;
            imageVerticalAlignment = [imgInfoDic[kCJImageLineVerticalAlignment] integerValue];
        }
        
        CGFloat yy = [self yOffset:y lineVerticalLayout:lineVerticalLayout lineDescent:lineDescent isImage:isImage imageHight:imageHight imageVerticalAlignment:imageVerticalAlignment];
        
        //绘制图片
        if (imgInfoDic[kCJImageName]) {
            UIImage *image = [UIImage imageNamed:imgInfoDic[kCJImageName]];
            if (image) {
                runRect = CGRectMake(lineOrigin.x + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL), lineOrigin.y - runDescent, runRect.size.width, runAscent + runDescent);
                CGRect imageDrawRect;
                CGFloat imageSizeWidth = runRect.size.width;
                CGFloat imageSizeHeight = runRect.size.height;
                imageDrawRect.size = CGSizeMake(imageSizeWidth, imageSizeHeight);
                imageDrawRect.origin.x = runRect.origin.x + x;
                imageDrawRect.origin.y = yy;
                CGContextDrawImage(c, imageDrawRect, image.CGImage);
            }
        }
        else{//绘制文字
            CGContextSetTextPosition(c, x, yy );
            CTRunDraw(run, c, CFRangeMake(0, 0));
        }

    }
}

- (void)drawBackgroundColor:(CGContextRef)c
             runStrokeItems:(NSArray <CJGlyphRunStrokeItem *>*)runStrokeItems
              isStrokeColor:(BOOL)isStrokeColor
{
    if (runStrokeItems.count > 0) {
        for (CJGlyphRunStrokeItem *item in runStrokeItems) {
            if (_currentClickRunStrokeItem && NSEqualRanges(_currentClickRunStrokeItem.range,item.range)) {
                [self drawBackgroundColor:c runStrokeItem:item isStrokeColor:isStrokeColor active:YES];
            }
            else{
                [self drawBackgroundColor:c runStrokeItem:item isStrokeColor:isStrokeColor active:NO];
            }
        }
    }
}

- (void)drawBackgroundColor:(CGContextRef)c
              runStrokeItem:(CJGlyphRunStrokeItem *)runStrokeItem
              isStrokeColor:(BOOL)isStrokeColor
                     active:(BOOL)active
{
    CGContextSetLineJoin(c, kCGLineJoinRound);
    CGFloat x = runStrokeItem.runBounds.origin.x-self.textInsets.left;
    CGFloat y = runStrokeItem.runBounds.origin.y+self.font.descender;
    if (runStrokeItem.isImage) {
        y = runStrokeItem.runBounds.origin.y;
    }
    
    CGRect roundedRect = CGRectMake(x,y,runStrokeItem.runBounds.size.width,runStrokeItem.runBounds.size.height);
    CGPathRef glyphRunpath = [[UIBezierPath bezierPathWithRoundedRect:roundedRect cornerRadius:runStrokeItem.cornerRadius] CGPath];
    CGContextAddPath(c, glyphRunpath);
    
    if (isStrokeColor) {
        UIColor *color = (active?runStrokeItem.activeStrokeColor:runStrokeItem.strokeColor);
        if (CJLabelIsNull(color)) {
            color = [UIColor clearColor];
        }
        CGContextSetStrokeColorWithColor(c, CGColorRefFromColor(color));
        CGContextSetLineWidth(c, runStrokeItem.lineWidth);
        CGContextStrokePath(c);
    }
    else {
        UIColor *color = (active?runStrokeItem.activeFillColor:runStrokeItem.fillColor);
        if (CJLabelIsNull(color)) {
            color = [UIColor clearColor];
        }
        CGContextSetFillColorWithColor(c, CGColorRefFromColor(color));
        CGContextFillPath(c);
    }
}

- (NSArray *)allCTLineVerticalLayoutArray:(NSArray *)lines origins:(CGPoint[])origins inRect:(CGRect)rect {
    NSMutableArray *verticalLayoutArray = [NSMutableArray arrayWithCapacity:3];
    // 遍历所有行
    for (NSInteger i = 0; i < _numberOfLines; i ++ ) {
        CTLineRef line = (__bridge CTLineRef)lines[i];
        
        CGFloat ascent = 0.0f, descent = 0.0f, leading = 0.0f;
        CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        //行高
        CGFloat lineHeight = ascent + descent + leading;
        //默认底部对齐
        CJLabelVerticalAlignment verticalAlignment = CJVerticalAlignmentBottom;
        
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        CGFloat maxRunHight = 0;
        CGFloat maxImageHight = 0;
        for (CFIndex j = 0; j < CFArrayGetCount(runs); ++j) {
            CTRunRef run = CFArrayGetValueAtIndex(runs, j);
            CGFloat runAscent = 0.0f, runDescent = 0.0f, runLeading = 0.0f;
            CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &runAscent, &runDescent, &runLeading);
            NSDictionary *attDic = (__bridge NSDictionary *)CTRunGetAttributes(run);
            NSDictionary *imgInfoDic = attDic[kCJImageAttributeName];
            if (CJLabelIsNull(imgInfoDic)) {
                maxRunHight = MAX(maxRunHight, runAscent + runDescent + runLeading);
            }else{
                if (maxImageHight < runAscent + runDescent) {
                    maxImageHight = runAscent + runDescent;
                    verticalAlignment = [imgInfoDic[kCJImageLineVerticalAlignment] integerValue];
                }
            }
        }
        CJCTLineVerticalLayout lineVerticalLayout;
        lineVerticalLayout.line = i;
        lineVerticalLayout.lineHight = lineHeight;
        lineVerticalLayout.maxRunHight = maxRunHight;
        lineVerticalLayout.verticalAlignment = verticalAlignment;
        lineVerticalLayout.maxImageHight = maxImageHight;
        
        NSValue *value = [NSValue valueWithBytes:&lineVerticalLayout objCType:@encode(CJCTLineVerticalLayout)];
        [verticalLayoutArray addObject:value];
    }
    return verticalLayoutArray;
}

// 计算可点击链点，以及需要填充背景或边框线的run数组
- (NSArray <CJGlyphRunStrokeItem *>*)calculateRunStrokeItemsFrame:(NSArray *)lines origins:(CGPoint[])origins inRect:(CGRect)rect {
    NSMutableArray *allStrokePathItems = [NSMutableArray arrayWithCapacity:3];
    
    CJCTLineVerticalLayout lineVerticalLayout = {0,0,0};
    // 遍历所有行
    for (NSInteger i = 0; i < _numberOfLines; i ++ ) {
        id line = lines[i];
        _lastGlyphRunStrokeItem = nil;
        
        CGFloat ascent = 0.0f, descent = 0.0f, leading = 0.0f;
        CGFloat width = (CGFloat)CTLineGetTypographicBounds((__bridge CTLineRef)line, &ascent, &descent, &leading);
        CGFloat ascentAndDescent = ascent + descent;
        
        lineVerticalLayout.line = i;
        lineVerticalLayout.maxRunHight = ascentAndDescent + leading;
        lineVerticalLayout.lineHight = ascentAndDescent + leading;
        
        for (NSValue *value in _CTLineVerticalLayoutArray) {
            CJCTLineVerticalLayout themLineVerticalLayout;
            [value getValue:&themLineVerticalLayout];
            if (themLineVerticalLayout.line == i) {
                lineVerticalLayout = themLineVerticalLayout;
                break;
            }
        }
        
        // 先获取每一行所有的runStrokeItems数组
        NSMutableArray *strokePathItems = [NSMutableArray arrayWithCapacity:3];
        
        //遍历每一行的所有glyphRun
        for (id glyphRun in (__bridge NSArray *)CTLineGetGlyphRuns((__bridge CTLineRef)line)) {
            
            NSDictionary *attributes = (__bridge NSDictionary *)CTRunGetAttributes((__bridge CTRunRef) glyphRun);
            
            UIColor *strokeColor = colorWithAttributeName(attributes, kCJBackgroundStrokeColorAttributeName);
            if (!CJLabelIsNull(attributes[kCJLinkAttributesName]) && !isNotClearColor(strokeColor)) {
                strokeColor = colorWithAttributeName(attributes[kCJLinkAttributesName], kCJBackgroundStrokeColorAttributeName);
            }
            UIColor *fillColor = colorWithAttributeName(attributes, kCJBackgroundFillColorAttributeName);
            if (!CJLabelIsNull(attributes[kCJLinkAttributesName]) && !isNotClearColor(fillColor)) {
                fillColor = colorWithAttributeName(attributes[kCJLinkAttributesName], kCJBackgroundFillColorAttributeName);
            }
            
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
            
            CGFloat lineWidth = [[attributes objectForKey:kCJBackgroundLineWidthAttributeName] floatValue];
            if (!CJLabelIsNull(attributes[kCJActiveLinkAttributesName]) && lineWidth == 0) {
                lineWidth = [[attributes[kCJActiveLinkAttributesName] objectForKey:kCJBackgroundLineCornerRadiusAttributeName] floatValue];
            }
            CGFloat cornerRadius = [[attributes objectForKey:kCJBackgroundLineCornerRadiusAttributeName] floatValue];
            if (!CJLabelIsNull(attributes[kCJActiveLinkAttributesName]) && cornerRadius == 0) {
                cornerRadius = [[attributes[kCJActiveLinkAttributesName] objectForKey:kCJBackgroundLineCornerRadiusAttributeName] floatValue];
            }
            lineWidth = lineWidth == 0?1:lineWidth;
            cornerRadius = cornerRadius == 0?5:cornerRadius;
            
            BOOL isLink = [attributes[kCJIsLinkAttributesName] boolValue];
            
            //点击链点的range（当isLink == YES才存在）
            NSString *linkRangeStr = [attributes objectForKey:kCJLinkRangeAttributesName];
            //点击链点是否需要重绘
            BOOL needRedrawn = [attributes[kCJLinkNeedRedrawnAttributesName] boolValue];
            
            NSDictionary *imgInfoDic = attributes[kCJImageAttributeName];
            CJLabelVerticalAlignment imageVerticalAlignment = CJVerticalAlignmentBottom;
            if (!CJLabelIsNull(imgInfoDic)) {
                imageVerticalAlignment = [imgInfoDic[kCJImageLineVerticalAlignment] integerValue];
            }
            
            // 当前glyphRun是一个可点击链点
            if (isLink) {
                CJGlyphRunStrokeItem *runStrokeItem = [self runStrokeItemFromGlyphRun:glyphRun
                                                                                 line:line
                                                                              origins:origins
                                                                            lineIndex:i
                                                                               inRect:rect
                                                                                width:width
                                                                      moreThanOneLine:(_numberOfLines > 1)
                                                                   lineVerticalLayout:lineVerticalLayout
                                                                              isImage:!CJLabelIsNull(imgInfoDic)
                                                               imageVerticalAlignment:imageVerticalAlignment
                                                                          lineDescent:descent];
                runStrokeItem.strokeColor = strokeColor;
                runStrokeItem.fillColor = fillColor;
                runStrokeItem.lineWidth = lineWidth;
                runStrokeItem.cornerRadius = cornerRadius;
                runStrokeItem.activeStrokeColor = activeStrokeColor;
                runStrokeItem.activeFillColor = activeFillColor;
                runStrokeItem.range = NSRangeFromString(linkRangeStr);
                runStrokeItem.isLink = YES;
                runStrokeItem.needRedrawn = needRedrawn;
                
                if (imgInfoDic[kCJImageName]) {
                    runStrokeItem.imageName = imgInfoDic[kCJImageName];
                    runStrokeItem.isImage = YES;
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
                
                [strokePathItems addObject:runStrokeItem];
            }else{
                //不是可点击链点。但存在自定义边框线或背景色
                if (isNotClearColor(strokeColor) || isNotClearColor(fillColor) || isNotClearColor(activeStrokeColor) || isNotClearColor(activeFillColor)) {
                    CJGlyphRunStrokeItem *runStrokeItem = [self runStrokeItemFromGlyphRun:glyphRun
                                                                                     line:line
                                                                                  origins:origins
                                                                                lineIndex:i
                                                                                   inRect:rect
                                                                                    width:width
                                                                          moreThanOneLine:(_numberOfLines > 1)
                                                                       lineVerticalLayout:lineVerticalLayout
                                                                                  isImage:!CJLabelIsNull(imgInfoDic)
                                                                   imageVerticalAlignment:imageVerticalAlignment
                                                                              lineDescent:descent];
                    runStrokeItem.strokeColor = strokeColor;
                    runStrokeItem.fillColor = fillColor;
                    runStrokeItem.lineWidth = lineWidth;
                    runStrokeItem.cornerRadius = cornerRadius;
                    runStrokeItem.activeStrokeColor = activeStrokeColor;
                    runStrokeItem.activeFillColor = activeFillColor;
                    runStrokeItem.isLink = NO;
                    if (imgInfoDic[kCJImageName]) {
                        runStrokeItem.imageName = imgInfoDic[kCJImageName];
                        runStrokeItem.isImage = YES;
                    }
                    
                    [strokePathItems addObject:runStrokeItem];
                }
            }
            
        }
        
        // 再判断是否有需要合并的runStrokeItems
        [allStrokePathItems addObjectsFromArray:[self mergeLineSameStrokePathItems:strokePathItems ascentAndDescent:ascentAndDescent moreThanOneLine:(_numberOfLines > 1)]];
    }
    
    return allStrokePathItems;
}

- (CJGlyphRunStrokeItem *)runStrokeItemFromGlyphRun:(id)glyphRun
                                               line:(id)line
                                            origins:(CGPoint[])origins
                                          lineIndex:(CFIndex)lineIndex
                                             inRect:(CGRect)rect
                                              width:(CGFloat)width
                                    moreThanOneLine:(BOOL)more
                                 lineVerticalLayout:(CJCTLineVerticalLayout)lineVerticalLayout
                                            isImage:(BOOL)isImage
                             imageVerticalAlignment:(CJLabelVerticalAlignment)imageVerticalAlignment
                                        lineDescent:(CGFloat)lineDescent
{
    CGRect runBounds = CGRectZero;
    CGFloat runAscent = 0.0f;
    CGFloat runDescent = 0.0f;
    runBounds.size.width = (CGFloat)CTRunGetTypographicBounds((__bridge CTRunRef)glyphRun, CFRangeMake(0, 0), &runAscent, &runDescent, NULL);
    runBounds.size.height = runAscent + runDescent;
    
    CGFloat xOffset = 0.0f;
    CFRange glyphRange = CTRunGetStringRange((__bridge CTRunRef)glyphRun);
    switch (CTRunGetStatus((__bridge CTRunRef)glyphRun)) {
        case kCTRunStatusRightToLeft:
            xOffset = CTLineGetOffsetForStringIndex((__bridge CTLineRef)line, glyphRange.location + glyphRange.length, NULL);
            break;
        default:
            xOffset = CTLineGetOffsetForStringIndex((__bridge CTLineRef)line, glyphRange.location, NULL);
            break;
    }
    
    runBounds.origin.x = origins[lineIndex].x + rect.origin.x + xOffset;
    CGFloat y = origins[lineIndex].y;
    CGFloat yy = [self yOffset:y lineVerticalLayout:lineVerticalLayout lineDescent:lineDescent isImage:isImage imageHight:runAscent + runDescent imageVerticalAlignment:imageVerticalAlignment];;
    
    runBounds.origin.y = yy;

    if (CGRectGetWidth(runBounds) > width) {
        runBounds.size.width = width;
    }

    //转换为UIKit坐标系统
    CGRect locBounds = [self convertRectFromLoc:runBounds moreThanOneLine:more];
    CJGlyphRunStrokeItem *runStrokeItem = [[CJGlyphRunStrokeItem alloc]init];
    runStrokeItem.runBounds = runBounds;
    runStrokeItem.locBounds = locBounds;
    
    return runStrokeItem;
}
//判断是否有需要合并的runStrokeItems
- (NSMutableArray <CJGlyphRunStrokeItem *>*)mergeLineSameStrokePathItems:(NSArray <CJGlyphRunStrokeItem *>*)lineStrokePathItems
                                             ascentAndDescent:(CGFloat)ascentAndDescent
                                                         moreThanOneLine:(BOOL)more
{
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
                UIColor *strokeColor = item.strokeColor;
                UIColor *fillColor = item.fillColor;
                UIColor *activeStrokeColor = item.activeStrokeColor;
                UIColor *activeFillColor = item.activeFillColor;
                CGFloat lineWidth = item.lineWidth;
                CGFloat cornerRadius = item.cornerRadius;
                
                CGRect lastRunBounds = _lastGlyphRunStrokeItem.runBounds;
                UIColor *lastStrokeColor = _lastGlyphRunStrokeItem.strokeColor;
                UIColor *lastFillColor = _lastGlyphRunStrokeItem.fillColor;
                UIColor *lastActiveStrokeColor = _lastGlyphRunStrokeItem.activeStrokeColor;
                UIColor *lastActiveFillColor = _lastGlyphRunStrokeItem.activeFillColor;
                CGFloat lastLineWidth = _lastGlyphRunStrokeItem.lineWidth;
                CGFloat lastCornerRadius = _lastGlyphRunStrokeItem.cornerRadius;
                
                BOOL sameColor = ({
                    BOOL same = NO;
                    if (isSameColor(strokeColor,lastStrokeColor) &&
                        isSameColor(fillColor,lastFillColor) &&
                        isSameColor(activeStrokeColor,lastActiveStrokeColor) &&
                        isSameColor(activeFillColor,lastActiveFillColor))
                    {
                        same = YES;
                    }
                    same;
                });
                
                BOOL needMerge = NO;
                //可点击链点
                if (item.isLink && _lastGlyphRunStrokeItem.isLink) {
                    NSRange range = item.range;
                    NSRange lastRange = _lastGlyphRunStrokeItem.range;
                    //需要合并的点击链点
                    if (NSEqualRanges(range,lastRange)) {
                        needMerge = YES;
                        lastRunBounds = CGRectMake(compareMaxNum(lastRunBounds.origin.x,runBounds.origin.x,NO),
                                                   compareMaxNum(lastRunBounds.origin.y,runBounds.origin.y,NO),
                                                   lastRunBounds.size.width + runBounds.size.width,
                                                   compareMaxNum(lastRunBounds.size.height,runBounds.size.height,YES));
                        _lastGlyphRunStrokeItem.runBounds = lastRunBounds;
                        _lastGlyphRunStrokeItem.locBounds = [self convertRectFromLoc:lastRunBounds moreThanOneLine:more];
                    }
                }else if (!item.isLink && !_lastGlyphRunStrokeItem.isLink){
                    //非点击链点，但是是需要合并的连续run
                    if (sameColor && lineWidth == lastLineWidth && cornerRadius == lastCornerRadius &&
                        lastRunBounds.origin.x + lastRunBounds.size.width == runBounds.origin.x) {
                        
                        needMerge = YES;
                        lastRunBounds = CGRectMake(compareMaxNum(lastRunBounds.origin.x,runBounds.origin.x,NO),
                                                   compareMaxNum(lastRunBounds.origin.y,runBounds.origin.y,NO),
                                                   lastRunBounds.size.width + runBounds.size.width,
                                                   compareMaxNum(lastRunBounds.size.height,runBounds.size.height,YES));
                        _lastGlyphRunStrokeItem.runBounds = lastRunBounds;
                        _lastGlyphRunStrokeItem.locBounds = [self convertRectFromLoc:lastRunBounds moreThanOneLine:more];
                    }
                }
                
                //没有发生合并
                if (!needMerge) {
                    
                    _lastGlyphRunStrokeItem = [self adjustItemHeight:_lastGlyphRunStrokeItem height:ascentAndDescent moreThanOneLine:more];
                    [strokePathTempItems addObject:[_lastGlyphRunStrokeItem copy]];
                    
                    _lastGlyphRunStrokeItem = item;
                    
                    //已经是最后一个run
                    if (i == lineStrokePathItems.count - 1) {
                        _lastGlyphRunStrokeItem = [self adjustItemHeight:_lastGlyphRunStrokeItem height:ascentAndDescent moreThanOneLine:more];
                        [strokePathTempItems addObject:[_lastGlyphRunStrokeItem copy]];
                    }
                }
                //有合并
                else{
                    //已经是最后一个run
                    if (i == lineStrokePathItems.count - 1) {
                        _lastGlyphRunStrokeItem = [self adjustItemHeight:_lastGlyphRunStrokeItem height:ascentAndDescent moreThanOneLine:more];
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
            item = [self adjustItemHeight:item height:ascentAndDescent moreThanOneLine:more];
            [mergeLineStrokePathItems addObject:item];
        }
        
    }
    return mergeLineStrokePathItems;
}

- (CJGlyphRunStrokeItem *)adjustItemHeight:(CJGlyphRunStrokeItem *)item
                                    height:(CGFloat)ascentAndDescent
                           moreThanOneLine:(BOOL)more {
    // runBounds小于 ascent + Descent 时，rect扩大 1
    if (item.runBounds.size.height < ascentAndDescent) {
        item.runBounds = CGRectInset(item.runBounds,-1,-1);
        item.locBounds = [self convertRectFromLoc:item.runBounds moreThanOneLine:more];;
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

/**
 将系统坐标转换为屏幕坐标

 @param rect 坐标原点在左下角的 rect
 @return 坐标原点在左上角的 rect
 */
- (CGRect)convertRectFromLoc:(CGRect)rect moreThanOneLine:(BOOL)more {    
    if ((fabs(rect.origin.y) + fabs(rect.size.height)) <= self.bounds.size.height) {
        rect = CGRectMake(rect.origin.x ,
                          self.bounds.size.height - rect.origin.y - rect.size.height,
                          rect.size.width,
                          rect.size.height);
    }else{
        if (more) {
            rect = CGRectMake(rect.origin.x ,
                              self.bounds.size.height - rect.origin.y - rect.size.height,
                              rect.size.width,
                              rect.size.height);
        }else{
            rect = CGRectMake(rect.origin.x ,
                              (self.bounds.size.height - rect.size.height)/2.0,
                              rect.size.width,
                              rect.size.height);
        }
    }
    return rect;
    
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
    if (![self linkAtPoint:point] || !self.userInteractionEnabled || self.hidden || self.alpha < 0.01) {
        return [super hitTest:point withEvent:event];
    }
    
    return self;
}

#pragma mark - UIResponder
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)containslinkAtPoint:(CGPoint)point {
    return [self linkAtPoint:point] != nil;
}

- (CJGlyphRunStrokeItem *)linkAtPoint:(CGPoint)point {
    
    if (!CGRectContainsPoint(CGRectInset(self.bounds, -15.f, -15.f), point) || _linkStrokeItemArray.count == 0) {
        return nil;
    }
    
    CJGlyphRunStrokeItem *resultItem = [self clickLinkItemAtRadius:0 aroundPoint:point];
    
    if (!resultItem && self.extendsLinkTouchArea) {
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
        
        CGFloat top = self.textInsets.top;
        CGFloat bottom = self.textInsets.bottom;
        bounds.origin.y = bounds.origin.y + top - bottom + _yOffset;
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
    CJGlyphRunStrokeItem *item = [self linkAtPoint:[touch locationInView:self]];
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
            CJLabelLinkModel *linkModel =
            [[CJLabelLinkModel alloc]initWithAttributedString:attributedString
                                                    imageName:_currentClickRunStrokeItem.imageName
                                                    imageRect:_currentClickRunStrokeItem.locBounds
                                                    parameter:_currentClickRunStrokeItem.parameter
                                                    linkRange:_currentClickRunStrokeItem.range];
            
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
        } else {
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

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return [self containslinkAtPoint:[touch locationInView:self]];
}

#pragma mark - UILongPressGestureRecognizer
- (void)longPressGestureDidFire:(UILongPressGestureRecognizer *)sender {
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            _longPress = YES;
            if (_currentClickRunStrokeItem) {
                
                NSAttributedString *attributedString = [self.attributedText attributedSubstringFromRange:_currentClickRunStrokeItem.range];
                CJLabelLinkModel *linkModel =
                [[CJLabelLinkModel alloc]initWithAttributedString:attributedString
                                                        imageName:_currentClickRunStrokeItem.imageName
                                                        imageRect:_currentClickRunStrokeItem.locBounds
                                                        parameter:_currentClickRunStrokeItem.parameter
                                                        linkRange:_currentClickRunStrokeItem.range];

                
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
            
            break;
        }
        case UIGestureRecognizerStateEnded:{
            _longPress = NO;
            if (_currentClickRunStrokeItem) {
                _needRedrawn = _currentClickRunStrokeItem.needRedrawn;
                _currentClickRunStrokeItem = nil;
                [self setNeedsFramesetter];
                [self setNeedsDisplay];
                [CATransaction flush];
            }
            break;
        }
        default:
            break;
    }
}

@end


@implementation CJLabelLinkModel
- (instancetype)initWithAttributedString:(NSAttributedString *)attributedString
                               imageName:(NSString *)imageName
                               imageRect:(CGRect )imageRect
                               parameter:(id)parameter
                               linkRange:(NSRange)linkRange
{
    self = [super init];
    if (self) {
        _attributedString = attributedString;
        _imageName = imageName;
        _imageRect = imageRect;
        _parameter = parameter;
        _linkRange = linkRange;
    }
    return self;
}
@end
