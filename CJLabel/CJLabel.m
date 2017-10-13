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

#define ENABLE_COPY_FILL_COLOR  [UIColor blueColor];

NSString * const kCJBackgroundFillColorAttributeName         = @"kCJBackgroundFillColor";
NSString * const kCJBackgroundStrokeColorAttributeName       = @"kCJBackgroundStrokeColor";
NSString * const kCJBackgroundLineWidthAttributeName         = @"kCJBackgroundLineWidth";
NSString * const kCJBackgroundLineCornerRadiusAttributeName  = @"kCJBackgroundLineCornerRadius";
NSString * const kCJActiveBackgroundFillColorAttributeName   = @"kCJActiveBackgroundFillColor";
NSString * const kCJActiveBackgroundStrokeColorAttributeName = @"kCJActiveBackgroundStrokeColor";
//标记每个字符的index值
NSString * const kCJCharacterIndexAttributesName             = @"kCJCharacterIndexAttributesName";

@interface CJLabel ()<UIGestureRecognizerDelegate>

//当前显示的AttributedText
@property (nonatomic, copy) NSAttributedString *renderedAttributedText;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) CJMagnifierView *magnifierView;//放大镜
@property (nonatomic, strong) CJSelectView *selectLeftView;//复制时候左侧选中标签
@property (nonatomic, strong) CJSelectView *selectRightView;//复制时候右侧选中标签
@end

@implementation CJLabel {
@private
    BOOL _needsFramesetter;
    NSInteger _numberOfLines;
    CTFramesetterRef _framesetter;
    CTFramesetterRef _highlightFramesetter;
    CGFloat _yOffset;
    BOOL _longPress;//判断是否长按;
    BOOL _needRedrawn;//是否需要重新计算_runStrokeItemArray以及_linkStrokeItemArray数组
    NSArray <CJGlyphRunStrokeItem *>*_runStrokeItemArray;//所有需要重绘背景或边框线的StrokeItem数组
    NSArray <CJGlyphRunStrokeItem *>*_linkStrokeItemArray;//可点击链点的StrokeItem数组
    CJGlyphRunStrokeItem *_lastGlyphRunStrokeItem;//计算StrokeItem的中间变量
    CJGlyphRunStrokeItem *_currentClickRunStrokeItem;//当前点击选中的StrokeItem
    NSArray *_CTLineVerticalLayoutArray;//记录 包含插入图片的CTLine在垂直方向的对齐方式的数组
    CGFloat _translateCTMty;//坐标系统反转后的偏移量
    CGRect _insetRect;//实际绘制文本区域大小
    NSArray <CJGlyphRunStrokeItem *>*_allRunItemArray;//enableCopy=YES时，包含所有CTRun信息的数组
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

+ (NSMutableAttributedString *)initWithImageName:(NSString *)imageName
                                       imageSize:(CGSize)size
                              imagelineAlignment:(CJLabelVerticalAlignment)lineAlignment
                                       configure:(CJLabelConfigure *)configure;
{
    NSAttributedString *attStr = [[NSAttributedString alloc]init];
    BOOL isLink = configure.isLink;
    NSMutableAttributedString *result = [CJLabelConfigure configureLinkAttributedString:attStr addImageName:imageName imageSize:size atIndex:0 verticalAlignment:lineAlignment linkAttributes:configure.attributes activeLinkAttributes:configure.activeLinkAttributes parameter:configure.parameter clickLinkBlock:configure.clickLinkBlock longPressBlock:configure.longPressBlock islink:isLink];
    return result;
}

+ (NSMutableAttributedString *)insertImageAtAttrString:(NSAttributedString *)attrStr
                                             imageName:(NSString *)imageName
                                             imageSize:(CGSize)size
                                               atIndex:(NSUInteger)loc
                                    imagelineAlignment:(CJLabelVerticalAlignment)lineAlignment
                                             configure:(CJLabelConfigure *)configure
{
    BOOL isLink = configure.isLink;
    NSMutableAttributedString *result = [CJLabelConfigure configureLinkAttributedString:attrStr addImageName:imageName imageSize:size atIndex:loc verticalAlignment:lineAlignment linkAttributes:configure.attributes activeLinkAttributes:configure.activeLinkAttributes parameter:configure.parameter clickLinkBlock:configure.clickLinkBlock longPressBlock:configure.longPressBlock islink:isLink];
    return result;
}

+ (NSMutableAttributedString *)configureAttrString:(NSAttributedString *)attrStr
                                           atRange:(NSRange)range
                                         configure:(CJLabelConfigure *)configure
{
    BOOL isLink = configure.isLink;
    NSMutableAttributedString *result = [CJLabelConfigure configureLinkAttributedString:attrStr atRange:range linkAttributes:configure.attributes activeLinkAttributes:configure.activeLinkAttributes parameter:configure.parameter clickLinkBlock:configure.clickLinkBlock longPressBlock:configure.longPressBlock islink:isLink];
    return result;
}

+ (NSMutableAttributedString *)initWithString:(NSString *)string configure:(CJLabelConfigure *)configure {
    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:string];
    BOOL isLink = configure.isLink;
    NSMutableAttributedString *result = [CJLabelConfigure configureLinkAttributedString:attrStr atRange:NSMakeRange(0, attrStr.length) linkAttributes:configure.attributes activeLinkAttributes:configure.activeLinkAttributes parameter:configure.parameter clickLinkBlock:configure.clickLinkBlock longPressBlock:configure.longPressBlock islink:isLink];
    return result;
}

+ (NSMutableAttributedString *)configureAttrString:(NSAttributedString *)attrStr
                                        withString:(NSString *)string
                                  sameStringEnable:(BOOL)sameStringEnable
                                         configure:(CJLabelConfigure *)configure
{
    BOOL isLink = configure.isLink;
    NSMutableAttributedString *result = [CJLabelConfigure configureLinkAttributedString:attrStr withString:string sameStringEnable:sameStringEnable linkAttributes:configure.attributes activeLinkAttributes:configure.activeLinkAttributes parameter:configure.parameter clickLinkBlock:configure.clickLinkBlock longPressBlock:configure.longPressBlock islink:isLink];
    return result;
}

+ (NSMutableAttributedString *)initWithAttributedString:(NSAttributedString *)attributedString
                                          strIdentifier:(NSString *)strIdentifier
                                              configure:(CJLabelConfigure *)configure
{
    NSRange strRange = NSMakeRange(0, attributedString.length);
    NSDictionary *strDic = nil;
    if (strRange.length > 0) {
        strDic = [attributedString attributesAtIndex:0 effectiveRange:&strRange];
    }
    NSAttributedString *attrStr = [CJLabelConfigure linkAttStr:attributedString.string attributes:strDic identifier:strIdentifier];
    BOOL isLink = configure.isLink;
    NSMutableAttributedString *result = [CJLabelConfigure configureLinkAttributedString:attrStr atRange:NSMakeRange(0, attrStr.length) linkAttributes:configure.attributes activeLinkAttributes:configure.activeLinkAttributes parameter:configure.parameter clickLinkBlock:configure.clickLinkBlock longPressBlock:configure.longPressBlock islink:isLink];
    return result;
}

+ (NSMutableAttributedString *)configureAttrString:(NSAttributedString *)attrString
                              withAttributedString:(NSAttributedString *)attributedString
                                     strIdentifier:(NSString *)strIdentifier
                                  sameStringEnable:(BOOL)sameStringEnable
                                         configure:(CJLabelConfigure *)configure
{
    NSRange strRange = NSMakeRange(0, attributedString.length);
    NSDictionary *strDic = nil;
    if (strRange.length > 0) {
        strDic = [attributedString attributesAtIndex:0 effectiveRange:&strRange];
    }
    NSAttributedString *linkStr = [CJLabelConfigure linkAttStr:attributedString.string attributes:strDic identifier:strIdentifier];
    BOOL isLink = configure.isLink;
    NSMutableAttributedString *result = [CJLabelConfigure configureLinkAttributedString:attrString withAttString:linkStr sameStringEnable:sameStringEnable linkAttributes:configure.attributes activeLinkAttributes:configure.activeLinkAttributes parameter:configure.parameter clickLinkBlock:configure.clickLinkBlock longPressBlock:configure.longPressBlock islink:isLink];
    return result;
}

+ (NSArray <NSString *>*)sameLinkStringRangeArray:(NSString *)linkString inAttString:(NSAttributedString *)attString {
    return [CJLabelConfigure getLinkStringRangeArray:linkString inAttString:attString];
}

+ (NSArray <NSString *>*)samelinkAttStringRangeArray:(NSAttributedString *)linkAttString strIdentifier:(NSString *)strIdentifier inAttString:(NSAttributedString *)attString {
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
    self.enableCopy = NO;
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
    
    //选择复制相关视图
    self.magnifierView = [[CJMagnifierView alloc] init];
    self.magnifierView.viewToMagnify = self;
    
    self.selectLeftView = [[CJSelectView alloc]initWithDirection:YES];
    self.selectLeftView.hidden = YES;
    [self addSubview:self.selectLeftView];
    self.selectRightView = [[CJSelectView alloc]initWithDirection:NO];
    self.selectRightView.hidden = YES;
    [self addSubview:self.selectRightView];
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
    _delegate = nil;
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
        }
    }];
    
    if (self.enableCopy) {
        //给每一个字符设置index值，enableCopy=YES时用到
        __block NSInteger index = 0;
        NSMutableArray *dicArray = [NSMutableArray arrayWithCapacity:3];
        [attText.string enumerateSubstringsInRange:NSMakeRange(0, [attText length]) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
         ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
             [dicArray addObject:@{@"index":@(index),@"substringRange":NSStringFromRange(substringRange)}];
             index++;
         }];
        for (NSDictionary *dic in dicArray) {
            [attText addAttribute:kCJCharacterIndexAttributesName value:dic[@"index"] range:NSRangeFromString(dic[@"substringRange"])];
        }
    }
    
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
            //如果有设置linkAttributes，则读取并设置
            NSDictionary *linkAttributes = attrs[kCJLinkAttributesName];
            if (!CJLabelIsNull(linkAttributes)) {
                [fullString addAttributes:linkAttributes range:range];
            }
            //如果有设置activeLinkAttributes，且正在点击当前链点，则读取并设置
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
        
        //包含插入图片的CTLine在垂直方向的对齐方式的数组
        _CTLineVerticalLayoutArray = [self allCTLineVerticalLayoutArray:lines origins:origins inRect:rect context:c];
        // 获取所有需要重绘背景的StrokeItem数组；支持复制，获取所有run数组
        [self calculateRunStrokeItemsFrame:lines origins:origins inRect:rect finishBlock:^(NSArray <CJGlyphRunStrokeItem *>*runStrokeItemArray, NSArray <CJGlyphRunStrokeItem *>*allRunItemArray){
            _runStrokeItemArray = runStrokeItemArray;
            _allRunItemArray = allRunItemArray;
            
            _linkStrokeItemArray = [self getLinkStrokeItems:_runStrokeItemArray];
        }];
    }
    
    //填充背景色
    [self drawBackgroundColor:c runStrokeItems:_runStrokeItemArray isStrokeColor:NO];
#warning 选择复制颜色
    if (self.enableCopy) {
        
    }
    
    CFArrayRef lines = CTFrameGetLines(frame);
    if (_numberOfLines == -1) {
        _numberOfLines = self.numberOfLines > 0 ? MIN(self.numberOfLines, CFArrayGetCount(lines)) : CFArrayGetCount(lines);
    }
    
    BOOL truncateLastLine = (self.lineBreakMode == NSLineBreakByTruncatingHead || self.lineBreakMode == NSLineBreakByTruncatingMiddle || self.lineBreakMode == NSLineBreakByTruncatingTail);
    
    CGPoint lineOrigins[_numberOfLines];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, _numberOfLines), lineOrigins);

    for (CFIndex lineIndex = 0; lineIndex < MIN(_numberOfLines, CFArrayGetCount(lines)); lineIndex++) {
        CGPoint lineOrigin = lineOrigins[lineIndex];
        CGContextSetTextPosition(c, lineOrigin.x, lineOrigin.y);
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        
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
                [self drawCTRun:c line:truncatedLine x:penOffset y:lineOrigin.y lineIndex:lineIndex lineOrigin:lineOrigin inRect:rect];
                
                CFRelease(truncatedLine);
                CFRelease(truncationLine);
                CFRelease(truncationToken);
            } else {
                CGFloat penOffset = (CGFloat)CTLineGetPenOffsetForFlush(line, flushFactor, rect.size.width);
                [self drawCTRun:c line:line x:penOffset y:lineOrigin.y lineIndex:lineIndex lineOrigin:lineOrigin inRect:rect];
            }
        }
        else {
            CGFloat penOffset = (CGFloat)CTLineGetPenOffsetForFlush(line, flushFactor, rect.size.width);
            [self drawCTRun:c line:line x:penOffset y:lineOrigin.y lineIndex:lineIndex lineOrigin:lineOrigin inRect:rect];
        }
        
    }
    
    // 绘制描边
    [self drawBackgroundColor:c runStrokeItems:_runStrokeItemArray isStrokeColor:YES];
    
    CFRelease(frame);
    CGPathRelease(path);
}

- (CGFloat)yOffset:(CGFloat)y lineVerticalLayout:(CJCTLineVerticalLayout)lineVerticalLayout lineDescent:(CGFloat)lineDescent isImage:(BOOL)isImage runHeight:(CGFloat)runHeight imageVerticalAlignment:(CJLabelVerticalAlignment)imageVerticalAlignment
{
    CGFloat lineHeight = lineVerticalLayout.lineHeight;
    CGFloat maxRunHeight = lineVerticalLayout.maxRunHeight;
    CGFloat maxImageHeight = lineVerticalLayout.maxImageHeight;
    
    CJLabelVerticalAlignment verticalAlignment = lineVerticalLayout.verticalAlignment;
    if (isImage) {
        verticalAlignment = imageVerticalAlignment;
    }
    
    CGFloat yy = y;
    
    //如果是图片
    if (isImage) {
        if (verticalAlignment == CJVerticalAlignmentBottom) {
            yy = y - lineDescent - self.font.descender;
            if (runHeight >= maxRunHeight && runHeight >= maxImageHeight) {
                yy = y - lineDescent + (lineHeight-runHeight)/2.0;
            }
        }
        else if (verticalAlignment == CJVerticalAlignmentCenter) {
            yy = y - lineDescent + (lineHeight-runHeight)/2.0;
        }
        else if (verticalAlignment == CJVerticalAlignmentTop) {
            yy = y - lineDescent + (lineHeight-runHeight) + self.font.descender;
            if (runHeight >= maxRunHeight && runHeight >= maxImageHeight) {
                yy = y - lineDescent + (lineHeight-runHeight)/2.0;
            }
        }
        return yy;
    }
    //文字高度比图片高度大，且是最大文字
    if (runHeight == maxRunHeight && maxRunHeight > maxImageHeight) {
        yy = y - lineDescent - self.font.descender;
        return yy;
    }
    //其他文字
    if (verticalAlignment == CJVerticalAlignmentBottom) {
        yy = y - lineDescent - self.font.descender;
    }
    else if (verticalAlignment == CJVerticalAlignmentCenter) {
        yy = y - lineDescent + (lineHeight-runHeight)/2.0;
        
    }
    else if (verticalAlignment == CJVerticalAlignmentTop) {
        yy = y - lineDescent + (lineHeight-runHeight) + self.font.descender;
    }
    return yy;
}
// 绘制单个CTRun
- (void)drawCTRun:(CGContextRef)c line:(CTLineRef)line x:(CGFloat)x y:(CGFloat)y lineIndex:(CFIndex)lineIndex lineOrigin:(CGPoint)lineOrigin inRect:(CGRect)rect {
    
    CJCTLineVerticalLayout lineVerticalLayout = {0,0,0};
    CGFloat lineAscent = 0.0f, lineDescent = 0.0f, lineLeading = 0.0f;
    CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
    
    lineVerticalLayout.line = lineIndex;
    lineVerticalLayout.maxRunHeight = lineAscent + lineDescent + lineLeading;
    lineVerticalLayout.lineHeight = lineAscent + lineDescent + lineLeading;
    
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
        CGFloat runHeight = 0;
        runHeight = runAscent + runDescent;
        CJLabelVerticalAlignment imageVerticalAlignment = CJVerticalAlignmentBottom;
        if (CJLabelIsNull(imgInfoDic)) {
            isImage = NO;
        }else{
            imageVerticalAlignment = [imgInfoDic[kCJImageLineVerticalAlignment] integerValue];
        }
        
        //y轴方向的偏移
        CGFloat yy = [self yOffset:y lineVerticalLayout:lineVerticalLayout lineDescent:lineDescent isImage:isImage runHeight:runHeight imageVerticalAlignment:imageVerticalAlignment];
        
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

- (CGFloat)isnanNum:(CGFloat)num {
    return isnan(num)?0:num;
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

- (NSArray *)allCTLineVerticalLayoutArray:(NSArray *)lines origins:(CGPoint[])origins inRect:(CGRect)rect context:(CGContextRef)c {
    NSMutableArray *verticalLayoutArray = [NSMutableArray arrayWithCapacity:3];
    // 遍历所有行
    for (NSInteger i = 0; i < MIN(_numberOfLines, lines.count); i ++ ) {
        CTLineRef line = (__bridge CTLineRef)lines[i];
        
        CGFloat ascent = 0.0f, descent = 0.0f, leading = 0.0f;
        CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        //行高
        CGFloat lineHeight = ascent + descent + leading;
        //默认底部对齐
        CJLabelVerticalAlignment verticalAlignment = CJVerticalAlignmentBottom;
        
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        CGFloat maxRunHeight = 0;
        CGFloat maxImageHeight = 0;
        for (CFIndex j = 0; j < CFArrayGetCount(runs); ++j) {
            CTRunRef run = CFArrayGetValueAtIndex(runs, j);
            CGFloat runAscent = 0.0f, runDescent = 0.0f, runLeading = 0.0f;
            CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &runAscent, &runDescent, &runLeading);
            NSDictionary *attDic = (__bridge NSDictionary *)CTRunGetAttributes(run);
            NSDictionary *imgInfoDic = attDic[kCJImageAttributeName];
            if (CJLabelIsNull(imgInfoDic)) {
                maxRunHeight = MAX(maxRunHeight, runAscent + runDescent );
            }else{
                if (maxImageHeight < runAscent + runDescent) {
                    maxImageHeight = runAscent + runDescent;
                    verticalAlignment = [imgInfoDic[kCJImageLineVerticalAlignment] integerValue];
                }
            }
        }
        
        CGRect lineBounds = CTLineGetImageBounds((CTLineRef)line, c);
        //每一行的起始点（相对于context）加上相对于本身基线原点的偏移量
        lineBounds.origin.x += origins[i].x;
        lineBounds.origin.y += origins[i].y;
        lineBounds.origin.y = _insetRect.size.height - lineBounds.origin.y - lineBounds.size.height - _translateCTMty;
        lineBounds.size.width = lineBounds.size.width + self.textInsets.left + self.textInsets.right;
        
        CJCTLineVerticalLayout lineVerticalLayout;
        lineVerticalLayout.line = i;
        lineVerticalLayout.lineHeight = lineHeight;
        lineVerticalLayout.maxRunHeight = maxRunHeight;
        lineVerticalLayout.verticalAlignment = verticalAlignment;
        lineVerticalLayout.maxImageHeight = maxImageHeight;
        lineVerticalLayout.lineRect = lineBounds;
        
        NSValue *value = [NSValue valueWithBytes:&lineVerticalLayout objCType:@encode(CJCTLineVerticalLayout)];
        [verticalLayoutArray addObject:value];
    }
    
    return verticalLayoutArray;
}

// 计算可点击链点，以及需要填充背景或边框线的run数组；如果支持复制，则同时计算所有run数组
- (void)calculateRunStrokeItemsFrame:(NSArray *)lines origins:(CGPoint[])origins inRect:(CGRect)rect finishBlock:(void (^)(NSArray <CJGlyphRunStrokeItem *>*runStrokeItemArray, NSArray <CJGlyphRunStrokeItem *>*allRunItemArray))finishBlock {
    NSMutableArray *allStrokePathItems = [NSMutableArray arrayWithCapacity:3];
    NSMutableArray *allRunItemArray = [NSMutableArray arrayWithCapacity:3];
    
    CJCTLineVerticalLayout lineVerticalLayout = {0,0,0};
    // 遍历所有行
    for (NSInteger i = 0; i < MIN(_numberOfLines, lines.count); i ++ ) {
        id line = lines[i];
        _lastGlyphRunStrokeItem = nil;
        
        CGFloat ascent = 0.0f, descent = 0.0f, leading = 0.0f;
        CGFloat width = (CGFloat)CTLineGetTypographicBounds((__bridge CTLineRef)line, &ascent, &descent, &leading);
        CGFloat ascentAndDescent = ascent + descent;
        
        lineVerticalLayout.line = i;
        lineVerticalLayout.maxRunHeight = ascentAndDescent + leading;
        lineVerticalLayout.lineHeight = ascentAndDescent + leading;
        
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
            //当前run相对于self的CGRect
            CGRect runBounds = [self getRunStrokeItemlocRunBoundsFromGlyphRun:glyphRun
                                                                         line:line
                                                                      origins:origins
                                                                    lineIndex:i
                                                                       inRect:rect
                                                                        width:width
                                                              moreThanOneLine:(_numberOfLines > 1)
                                                           lineVerticalLayout:lineVerticalLayout
                                                                      isImage:!CJLabelIsNull(imgInfoDic)
                                                       imageVerticalAlignment:imageVerticalAlignment
                                                                  lineDescent:descent
                                                                  lineLeading:leading];
            //转换为UIKit坐标系统
            CGRect locBounds = [self convertRectFromLoc:runBounds moreThanOneLine:(_numberOfLines > 1)];
            
            CJGlyphRunStrokeItem *runStrokeItem = [[CJGlyphRunStrokeItem alloc]init];
            runStrokeItem.runBounds = runBounds;
            runStrokeItem.locBounds = locBounds;
            runStrokeItem.lineVerticalLayout = lineVerticalLayout;
            runStrokeItem.fillCopyColor = ENABLE_COPY_FILL_COLOR;
            
            if (self.enableCopy) {
                runStrokeItem.isSelect = NO;
                [allRunItemArray addObject:runStrokeItem];
            }
            
            // 当前glyphRun是一个可点击链点
            if (isLink) {
                
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
            }
            else{
                //不是可点击链点。但存在自定义边框线或背景色
                if (isNotClearColor(strokeColor) || isNotClearColor(fillColor) || isNotClearColor(activeStrokeColor) || isNotClearColor(activeFillColor)) {
                    
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
    
    finishBlock(allStrokePathItems,allRunItemArray);
}

- (CGRect )getRunStrokeItemlocRunBoundsFromGlyphRun:(id)glyphRun
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
                                        lineLeading:(CGFloat)lineLeading
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
    CGFloat yy = [self yOffset:y lineVerticalLayout:lineVerticalLayout lineDescent:lineDescent isImage:isImage runHeight:runAscent + runDescent imageVerticalAlignment:imageVerticalAlignment];
    //文字对应的runBounds 微调
    if (!isImage) {
        yy = yy - self.font.descender/2;
    }
    runBounds.origin.y = yy;
    
    if (CGRectGetWidth(runBounds) > width) {
        runBounds.size.width = width;
    }
    
    return runBounds;
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

- (void)showCJSelectViewWithPoint:(CGPoint)point selectType:(NSInteger)type {
    
    BOOL needUpdateCopyFrame = NO;
    CJCTLineVerticalLayout lineVerticalLayout;
    CGRect itemRect = CGRectZero;
    for (CJGlyphRunStrokeItem *item in _allRunItemArray) {
        if (CGRectContainsPoint(item.locBounds, point)) {
            item.isSelect = YES;
            lineVerticalLayout = item.lineVerticalLayout;
            needUpdateCopyFrame = YES;
            itemRect = item.locBounds;
            break;
        }
    }
    if (needUpdateCopyFrame) {
        CGPoint selectPoint = CGPointMake(point.x, lineVerticalLayout.lineRect.origin.y);
        CGPoint pointToMagnify = CGPointMake(point.x, lineVerticalLayout.lineRect.origin.y + lineVerticalLayout.lineRect.size.height/2);
        CGPoint showMagnifierViewPoint = [self convertPoint:selectPoint toView:self.window];
        [self.magnifierView makeKeyAndVisible];
        self.magnifierView.hidden = NO;
        [self.magnifierView updateMagnifyPoint:pointToMagnify showMagnifyViewIn:showMagnifierViewPoint];
        
        self.selectLeftView.hidden = self.selectRightView.hidden = NO;
        [self bringSubviewToFront:self.selectLeftView];
        [self bringSubviewToFront:self.selectRightView];
        
        if (type == 0 || type == 1) {
            [self.selectLeftView updateCJSelectViewHeight:lineVerticalLayout.lineRect.size.height showCJSelectViewIn:CGPointMake(itemRect.origin.x, selectPoint.y)];
        }
        if (type == 0 || type == 2) {
            [self.selectRightView updateCJSelectViewHeight:lineVerticalLayout.lineRect.size.height showCJSelectViewIn:CGPointMake(itemRect.origin.x+itemRect.size.width, selectPoint.y)];
        }
        
        [self setNeedsDisplay];
        //立即刷新界面
        [CATransaction flush];
        
    }
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
    if (self.enableCopy && self.selectLeftView.hidden == NO && self.selectRightView.hidden == NO) {
        CGPoint point = [[touches anyObject] locationInView:self];
        //点击拖动selectLeftView
        if (CGRectContainsPoint(CGRectInset(self.selectLeftView.frame, -2.f, -2.f), point)) {
            CGPoint selectPoint = CGPointMake(point.x, (self.selectLeftView.frame.size.height/2)+self.selectLeftView.frame.origin.y);
            [self showCJSelectViewWithPoint:selectPoint selectType:1];
        }
        //点击拖动selectRightView
        if (CGRectContainsPoint(CGRectInset(self.selectRightView.frame, -2.f, -2.f), point)) {
            CGPoint selectPoint = CGPointMake(point.x, (self.selectRightView.frame.size.height)/2+self.selectRightView.frame.origin.y);
            [self showCJSelectViewWithPoint:selectPoint selectType:2];
        }
        
    }
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
    [self.magnifierView setHidden:YES];
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
    [self.magnifierView setHidden:YES];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    objc_setAssociatedObject(self.longPressGestureRecognizer, "UITouch", touch, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return YES;
}

#pragma mark - UILongPressGestureRecognizer
- (void)longPressGestureDidFire:(UILongPressGestureRecognizer *)sender {
    
    UITouch *touch = objc_getAssociatedObject(self.longPressGestureRecognizer, "UITouch");
    BOOL isLinkItem = [self containslinkAtPoint:[touch locationInView:self]];
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            if (isLinkItem) {
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
            }
            else{
                
            }
            break;
        }
        case UIGestureRecognizerStateEnded:{
            if (isLinkItem) {
                _longPress = NO;
                if (_currentClickRunStrokeItem) {
                    _needRedrawn = _currentClickRunStrokeItem.needRedrawn;
                    _currentClickRunStrokeItem = nil;
                    [self setNeedsFramesetter];
                    [self setNeedsDisplay];
                    [CATransaction flush];
                }
            }else {
                [self.magnifierView setHidden:YES];
            }
            
            break;
        }
        case UIGestureRecognizerStateChanged:{
            if (self.enableCopy) {
                for (CJGlyphRunStrokeItem *item in _allRunItemArray) {
                    item.isSelect = NO;
                }
                CGPoint point = [touch locationInView:self];
                [self showCJSelectViewWithPoint:point selectType:0];
            }
        }
        default:
            break;
    }
}

@end


