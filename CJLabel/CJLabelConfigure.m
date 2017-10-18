//
//  CJLabelConfigure.m
//  CJLabelTest
//
//  Created by ChiJinLian on 2017/4/13.
//  Copyright © 2017年 ChiJinLian. All rights reserved.
//

#import "CJLabelConfigure.h"
#import "CJLabel.h"
#import <objc/runtime.h>

NSString * const kCJImageAttributeName                       = @"kCJImageAttributeName";
NSString * const kCJImageName                                = @"kCJImageName";
NSString * const kCJImageHeight                              = @"kCJImageHeight";
NSString * const kCJImageWidth                               = @"kCJImageWidth";
NSString * const kCJImageLineVerticalAlignment               = @"kCJImageLineVerticalAlignment";

NSString * const kCJLinkStringKeyAttributesName              = @"kCJLinkStringKeyAttributesName";

NSString * const kCJLinkAttributesName                       = @"kCJLinkAttributesName";
NSString * const kCJActiveLinkAttributesName                 = @"kCJActiveLinkAttributesName";
NSString * const kCJIsLinkAttributesName                     = @"kCJIsLinkAttributesName";
NSString * const kCJLinkRangeAttributesName                  = @"kCJLinkRangeAttributesName";
NSString * const kCJLinkParameterAttributesName              = @"kCJLinkParameterAttributesName";
NSString * const kCJClickLinkBlockAttributesName             = @"kCJClickLinkBlockAttributesName";
NSString * const kCJLongPressBlockAttributesName             = @"kCJLongPressBlockAttributesName";
NSString * const kCJLinkNeedRedrawnAttributesName            = @"kCJLinkNeedRedrawnAttributesName";

//插入图片 占位符
NSString * const kAddImagePlaceholderString                  = @" ";


void RunDelegateDeallocCallback(void * refCon) {
    
}

//获取图片高度
CGFloat RunDelegateGetAscentCallback(void * refCon) {
    return [(NSNumber *)[(__bridge NSDictionary *)refCon objectForKey:kCJImageHeight] floatValue];
}

CGFloat RunDelegateGetDescentCallback(void * refCon) {
    return 0;
}
//获取图片宽度
CGFloat RunDelegateGetWidthCallback(void * refCon) {
    return [(NSNumber *)[(__bridge NSDictionary *)refCon objectForKey:kCJImageWidth] floatValue];
}

UIWindow * keyWindow(){
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    return window;
}

@implementation CJLabelConfigure
+ (instancetype)configureAttributes:(NSDictionary<NSAttributedStringKey, id> *)attributes
                             isLink:(BOOL)isLink
               activeLinkAttributes:(NSDictionary<NSAttributedStringKey, id> *)activeLinkAttributes
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
                                                      islink:(BOOL)isLink
{
    NSParameterAssert((loc <= attrStr.length) && (!CJLabelIsNull(imageName) && imageName.length != 0));
    
    NSDictionary *imgInfoDic = @{kCJImageName:imageName,
                                 kCJImageWidth:@(size.width),
                                 kCJImageHeight:@(size.height),
                                 kCJImageLineVerticalAlignment:@(verticalAlignment)};
    
    //创建CTRunDelegateRef并设置回调函数
    CTRunDelegateCallbacks imageCallbacks;
    imageCallbacks.version = kCTRunDelegateVersion1;
    imageCallbacks.dealloc = RunDelegateDeallocCallback;
    imageCallbacks.getWidth = RunDelegateGetWidthCallback;
    imageCallbacks.getAscent = RunDelegateGetAscentCallback;
    imageCallbacks.getDescent = RunDelegateGetDescentCallback;
    CTRunDelegateRef runDelegate = CTRunDelegateCreate(&imageCallbacks, (__bridge void *)imgInfoDic);
    
    //插入图片 空白占位符
    NSMutableString *imgPlaceholderStr = [[NSMutableString alloc]initWithCapacity:3];
    [imgPlaceholderStr appendString:kAddImagePlaceholderString];
    NSRange imgRange = NSMakeRange(0, imgPlaceholderStr.length);
    NSMutableAttributedString *imageAttributedString = [[NSMutableAttributedString alloc] initWithString:imgPlaceholderStr];
    [imageAttributedString addAttribute:(NSString *)kCTRunDelegateAttributeName value:(__bridge id)runDelegate range:imgRange];
    [imageAttributedString addAttribute:kCJImageAttributeName value:imgInfoDic range:imgRange];
    
    if (!CJLabelIsNull(linkAttributes) && linkAttributes.count > 0) {
        [imageAttributedString addAttribute:kCJLinkAttributesName value:linkAttributes range:imgRange];
    }
    if (!CJLabelIsNull(activeLinkAttributes) && activeLinkAttributes.count > 0) {
        [imageAttributedString addAttribute:kCJActiveLinkAttributesName value:activeLinkAttributes range:imgRange];
    }
    if (!CJLabelIsNull(parameter)) {
        [imageAttributedString addAttribute:kCJLinkParameterAttributesName value:parameter range:imgRange];
    }
    if (!CJLabelIsNull(clickLinkBlock)) {
        [imageAttributedString addAttribute:kCJClickLinkBlockAttributesName value:clickLinkBlock range:imgRange];
    }
    if (!CJLabelIsNull(longPressBlock)) {
        [imageAttributedString addAttribute:kCJLongPressBlockAttributesName value:longPressBlock range:imgRange];
    }
    if (isLink) {
        [imageAttributedString addAttribute:kCJIsLinkAttributesName value:@(YES) range:imgRange];
    }else{
        [imageAttributedString addAttribute:kCJIsLinkAttributesName value:@(NO) range:imgRange];
    }
    NSRange range = NSMakeRange(loc, imgPlaceholderStr.length);
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithAttributedString:attrStr];
    
    /* 设置默认换行模式为：NSLineBreakByCharWrapping
     * 当Label的宽度不够显示内容或图片的时候就自动换行, 不自动换行, 部分图片将会看不见
     */
    NSRange attributedStringRange = NSMakeRange(0, attributedString.length);
    NSDictionary *dic = nil;
    if (attributedStringRange.length > 0) {
        dic = [attributedString attributesAtIndex:0 effectiveRange:&attributedStringRange];
    }
    //判断是否有设置NSParagraphStyleAttributeName属性
    NSMutableParagraphStyle *paragraph = dic[NSParagraphStyleAttributeName];
    //判断linkAttributes中是否有设置NSParagraphStyleAttributeName属性
    if (CJLabelIsNull(paragraph)) {
        paragraph = linkAttributes[NSParagraphStyleAttributeName];
    }
    //都没有设置，取默认值
    if (CJLabelIsNull(paragraph)) {
        paragraph = [[NSMutableParagraphStyle alloc] init];
        paragraph.lineBreakMode = NSLineBreakByCharWrapping;
    }
    
    [attributedString insertAttributedString:imageAttributedString atIndex:range.location];
    if (!CJLabelIsNull(paragraph)) {
        [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, attributedString.length)];
    }
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
    NSParameterAssert(attrStr.length > 0);
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
    }else{
        [attributedString addAttribute:kCJLinkNeedRedrawnAttributesName value:@(NO) range:range];
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
    }else{
        [attributedString addAttribute:kCJIsLinkAttributesName value:@(NO) range:range];
    }
    return attributedString;
}

+ (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
                                                  withString:(NSString *)withString
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
        NSRange range = [self getFirstRangeWithString:withString inAttString:attrStr];
        if (range.location != NSNotFound) {
            attributedString = [self configureLinkAttributedString:attributedString atRange:range linkAttributes:linkAttributes activeLinkAttributes:activeLinkAttributes parameter:parameter clickLinkBlock:clickLinkBlock longPressBlock:longPressBlock islink:isLink];
        }
    }else{
        NSArray *rangeAry = [self getLinkStringRangeArray:withString inAttString:attrStr];
        if (rangeAry.count > 0) {
            for (NSString *strRange in rangeAry) {
                attributedString = [self configureLinkAttributedString:attributedString atRange:NSRangeFromString(strRange) linkAttributes:linkAttributes activeLinkAttributes:activeLinkAttributes parameter:parameter clickLinkBlock:clickLinkBlock longPressBlock:longPressBlock islink:isLink];
            }
        }
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
        NSArray *rangeAry = [self getLinkAttStringRangeArray:withAttString inAttString:attrStr];
        if (rangeAry.count > 0) {
            for (NSString *strRange in rangeAry) {
                attributedString = [self configureLinkAttributedString:attributedString atRange:NSRangeFromString(strRange) linkAttributes:linkAttributes activeLinkAttributes:activeLinkAttributes parameter:parameter clickLinkBlock:clickLinkBlock longPressBlock:longPressBlock islink:isLink];
            }
        }
    }
    return attributedString;
}

+ (NSMutableAttributedString *)linkAttStr:(NSString *)string
                               attributes:(NSDictionary <NSString *,id>*)attrs
                               identifier:(NSString *)identifier
{
    NSParameterAssert(string);
    NSParameterAssert(identifier);
    
    NSDictionary *dic = CJLabelIsNull(attrs)?[[NSDictionary alloc] init]:[[NSDictionary alloc]initWithDictionary:attrs];
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc]initWithString:string attributes:dic];
    [attStr addAttribute:kCJLinkStringKeyAttributesName value:identifier range:NSMakeRange(0, attStr.length)];
    
    return attStr;
}

#pragma mark -

+ (NSRange)getFirstRangeWithString:(NSString *)withString inAttString:(NSAttributedString *)attString {
    NSRange range = [attString.string rangeOfString:withString];
    if (range.location == NSNotFound) {
        return range;
    }
    return range;
}

+ (NSArray <NSString *>*)getLinkStringRangeArray:(NSString *)linkString inAttString:(NSAttributedString *)attString {
    NSArray *strRanges = [self getRangeArrayWithString:linkString inString:attString.string lastRange:NSMakeRange(0, 0) rangeArray:[NSMutableArray array]];
    return strRanges;
}

+ (NSRange)getFirstRangeWithAttString:(NSAttributedString *)withAttString inAttString:(NSAttributedString *)attString {
    NSRange range = [attString.string rangeOfString:withAttString.string];
    if (range.location == NSNotFound) {
        return range;
    }
    
    NSAttributedString *str = [attString attributedSubstringFromRange:range];
    NSRange strRange = NSMakeRange(0, str.length);
    NSDictionary *strDic = nil;
    if (strRange.length > 0) {
        strDic = [str attributesAtIndex:0 effectiveRange:&strRange];
    }
    NSString *key = strDic[kCJLinkStringKeyAttributesName];
    
    NSRange withStrRange = NSMakeRange(0, withAttString.length);
    NSDictionary *withStrDic = nil;
    if (withStrRange.length > 0) {
        withStrDic = [withAttString attributesAtIndex:0 effectiveRange:&withStrRange];
    }
    NSString *withKey = withStrDic[kCJLinkStringKeyAttributesName];
    
    if (!key || !withKey || ![key isEqualToString:withKey]) {
        range = NSMakeRange(NSNotFound, 0);
    }
    return range;
}

+ (NSArray <NSString *>*)getLinkAttStringRangeArray:(NSAttributedString *)linkAttString inAttString:(NSAttributedString *)attString {
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:3];
    NSArray *strRanges = [self getRangeArrayWithString:linkAttString.string inString:attString.string lastRange:NSMakeRange(0, 0) rangeArray:[NSMutableArray array]];
    
    if (strRanges.count > 0) {
        
        NSRange withStrRange = NSMakeRange(0, linkAttString.length);
        NSDictionary *withStrDic = nil;
        if (withStrRange.length > 0) {
            withStrDic = [linkAttString attributesAtIndex:0 effectiveRange:&withStrRange];
        }
        NSString *withKey = withStrDic[kCJLinkStringKeyAttributesName];
        
        for (NSString *rangeStr in strRanges) {
            
            NSRange range = NSRangeFromString(rangeStr);
            NSAttributedString *str = [attString attributedSubstringFromRange:range];
            NSRange strRange = NSMakeRange(0, str.length);
            NSDictionary *strDic = nil;
            if (strRange.length > 0) {
                strDic = [str attributesAtIndex:0 effectiveRange:&strRange];
            }
            NSString *key = strDic[kCJLinkStringKeyAttributesName];
            
            
            if (key && withKey && [key isEqualToString:withKey]) {
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

@implementation CJGlyphRunStrokeItem

- (id)copyWithZone:(NSZone *)zone {
    CJGlyphRunStrokeItem *item = [[[self class] allocWithZone:zone] init];
    item.strokeColor = self.strokeColor;
    item.fillColor = self.fillColor;
    item.lineWidth = self.lineWidth;
    item.runBounds = self.runBounds;
    item.locBounds = self.locBounds;
    item.withOutMergeBounds = self.withOutMergeBounds;
    item.cornerRadius = self.cornerRadius;
    item.activeFillColor = self.activeFillColor;
    item.activeStrokeColor = self.activeStrokeColor;
    item.imageName = self.imageName;
    item.isImage = self.isImage;
    item.range = self.range;
    item.parameter = self.parameter;
    item.lineVerticalLayout = self.lineVerticalLayout;
    item.linkBlock = self.linkBlock;
    item.longPressBlock = self.longPressBlock;
    item.isLink = self.isLink;
    item.needRedrawn = self.needRedrawn;
    item.characterIndex = self.characterIndex;
    item.characterRange = self.characterRange;
    return item;
}

@end

@interface CJMagnifierView ()
@property (strong, nonatomic) CALayer *contentLayer;
@end
@implementation CJMagnifierView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.windowLevel = UIWindowLevelAlert;
        
        //白色背景
        CALayer *backLayer = [CALayer layer];
        backLayer.frame = CGRectMake(0, 0, 120, 30);
        backLayer.backgroundColor = [UIColor whiteColor].CGColor;
        backLayer.cornerRadius = 5;
        backLayer.borderWidth = 1/[[UIScreen mainScreen] scale];
        backLayer.borderColor = [[UIColor lightGrayColor] CGColor];
        //masksToBounds开启会影响阴影效果
        //        backLayer.masksToBounds = YES;
        backLayer.shadowColor = [UIColor lightGrayColor].CGColor;
        backLayer.shadowOffset = CGSizeMake(0,0.5);
        backLayer.shadowOpacity = 0.75;
        backLayer.shadowRadius = 0.75;
        [self.layer addSublayer:backLayer];
        
        //底部白色小三角
        CALayer *whiteLayer = [CALayer layer];
        whiteLayer.frame = CGRectMake(51, 21.5, 18, 18);
        whiteLayer.backgroundColor = [UIColor whiteColor].CGColor;
        whiteLayer.contentsScale = [[UIScreen mainScreen] scale];
        whiteLayer.shadowColor = [UIColor lightGrayColor].CGColor;
        whiteLayer.shadowOffset = CGSizeMake(0.6,0.6);
        whiteLayer.shadowOpacity = 0.85;
        whiteLayer.shadowRadius = 0.85;
        [self.layer addSublayer:whiteLayer];
        CATransform3D transform = CATransform3DMakeRotation(M_PI/4, 0, 0, 1);
        whiteLayer.transform = transform;
        CALayer *whiteTriangleLayer = [CALayer layer];
        whiteTriangleLayer.frame = CGRectMake(50, 20, 20, 20);
        whiteTriangleLayer.backgroundColor = [UIColor whiteColor].CGColor;
        whiteTriangleLayer.contentsScale = [[UIScreen mainScreen] scale];
        [self.layer addSublayer:whiteTriangleLayer];
        whiteTriangleLayer.transform = transform;
        
        //放大绘制layer
        self.contentLayer = [CALayer layer];
        self.contentLayer.frame = CGRectMake(0, 0, 120, 30);
        self.contentLayer.cornerRadius = 5;
        self.contentLayer.masksToBounds = YES;
        self.contentLayer.delegate = self;
        self.contentLayer.contentsScale = [[UIScreen mainScreen] scale];
        [self.layer addSublayer:self.contentLayer];
    }
    return self;
}

- (void)setPointToMagnify:(CGPoint)pointToMagnify {
    _pointToMagnify = pointToMagnify;
    [self.contentLayer setNeedsDisplay];
}

- (void)updateMagnifyPoint:(CGPoint)pointToMagnify showMagnifyViewIn:(CGPoint)showPoint {
    CGPoint center = CGPointMake(showPoint.x, self.center.y);
    if (showPoint.y > CGRectGetHeight(self.bounds) * 0.5) {
        center.y = showPoint.y -  CGRectGetHeight(self.bounds) / 2;
    }
    self.center = CGPointMake(center.x, center.y);
    self.pointToMagnify = pointToMagnify;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    CGContextTranslateCTM(ctx, self.frame.size.width * 0.5, self.frame.size.height * 0.5-17);
    CGContextScaleCTM(ctx, 1.35, 1.35);
    CGContextTranslateCTM(ctx, -1 * self.pointToMagnify.x, -1 * self.pointToMagnify.y);
    [self.viewToMagnify.layer renderInContext:ctx];

}

@end

@interface CJSelectView ()
@property (nonatomic, assign) BOOL isLeft;
@property (nonatomic, strong) CALayer *lineLayer;
@property (nonatomic, strong) CALayer *roundLayer;

@end
@implementation CJSelectView

- (CJSelectView *)initWithDirection:(BOOL)isLeft {
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, 10, 30);
        self.autoresizingMask = UIViewAutoresizingNone;
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = NO;
        
        UIColor *color = [UIColor colorWithRed:0/255.0
                                         green:128/255.0
                                          blue:255/255.0
                                         alpha:1.0];
        
        self.lineLayer = [CALayer layer];
        self.lineLayer.frame = CGRectMake(4, isLeft?10:0, 2, 20);
        self.lineLayer.backgroundColor = color.CGColor;
        self.lineLayer.contentsScale = [[UIScreen mainScreen] scale];
        [self.layer addSublayer:self.lineLayer];
        
        self.roundLayer = [CALayer layer];
        self.roundLayer.frame = CGRectMake(0, isLeft?0:20, 10, 10);
        self.roundLayer.backgroundColor = color.CGColor;
        self.roundLayer.contentsScale = [[UIScreen mainScreen] scale];
        self.roundLayer.cornerRadius = 5;
        self.roundLayer.masksToBounds = YES;
        [self.layer addSublayer:self.roundLayer];
        self.isLeft = isLeft;
    }
    return self;
}

- (void)updateCJSelectViewHeight:(CGFloat)height showCJSelectViewIn:(CGPoint)showPoint {
    //高度限定为20
//    if (height > 20) {
        height = 20;
//    }
    if (self.isLeft) {
        self.frame = CGRectMake(showPoint.x-5, showPoint.y-10, 10, height+10);
        self.lineLayer.frame = CGRectMake(4, 10, 2, height);
        self.roundLayer.frame = CGRectMake(0, 0, 10, 10);
    }else{
        self.frame = CGRectMake(showPoint.x-5, showPoint.y-height, 10, height+10);
        self.lineLayer.frame = CGRectMake(4, 0, 2, height);
        self.roundLayer.frame = CGRectMake(0, height, 10, 10);
    }
}

@end

@implementation CJSelectTextRangeView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.opaque = NO;
    }
    return self;
}

- (void)updateFrame:(CGRect)frame headRect:(CGRect)headRect middleRect:(CGRect)middleRect tailRect:(CGRect)tailRect differentLine:(BOOL)differentLine {
    self.differentLine = differentLine;
    self.frame = frame;
    self.headRect = headRect;
    self.middleRect = middleRect;
    self.tailRect = tailRect;
    
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {

    CGContextRef ctx = UIGraphicsGetCurrentContext();

    //背景色
    UIColor *backColor = CJUIRGBColor(0,84,166,0.2);
    [backColor set];

    if (self.differentLine) {
        CGContextAddRect(ctx, self.headRect);
        if (!CGRectEqualToRect(self.middleRect,CGRectNull)) {
            CGContextAddRect(ctx, self.middleRect);
        }
        CGContextAddRect(ctx, self.tailRect);
        CGContextFillPath(ctx);
    }else{
        CGContextAddRect(ctx, self.middleRect);
        CGContextFillPath(ctx);
    }
}

@end



@interface CJSelectBackView()<UIGestureRecognizerDelegate>
{
    CGFloat _lineVerticalMaxWidth;//每一行文字中的最大宽度
    NSArray *_CTLineVerticalLayoutArray;//记录 所有CTLine在垂直方向的对齐方式的数组
    NSArray <CJGlyphRunStrokeItem *>*_allRunItemArray;//CJLabel包含所有CTRun信息的数组
    CJGlyphRunStrokeItem *_firstRunItem;//最后一个StrokeItem
    CJGlyphRunStrokeItem *_lastRunItem;//最后一个StrokeItem
    CJGlyphRunStrokeItem *_startCopyRunItem;//选中复制的第一个StrokeItem
    CGFloat _startCopyRunItemY;//_startCopyRunItem Y坐标 显示Menu（选择、全选、复制菜单时用到）
    CJGlyphRunStrokeItem *_endCopyRunItem;//选中复制的最后一个StrokeItem
}
@property (nonatomic, strong) UITapGestureRecognizer *singleTapGes;//单击手势
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGes;//双击手势
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;//长按手势
@end
@implementation CJSelectBackView
+ (instancetype)instance {
    static CJSelectBackView *manager = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        manager = [[CJSelectBackView alloc] initWithFrame:CGRectZero];
        manager.backgroundColor = [UIColor clearColor];

        //选择复制相关视图
//        manager.magnifierView = [[CJMagnifierView alloc] initWithFrame:CGRectMake(0, 0, 120, 65)];
        
        manager.selectLeftView = [[CJSelectView alloc]initWithDirection:YES];
        manager.selectLeftView.hidden = YES;
        [manager addSubview:manager.selectLeftView];
        manager.selectRightView = [[CJSelectView alloc]initWithDirection:NO];
        manager.selectRightView.hidden = YES;
        [manager addSubview:manager.selectRightView];
        
        manager.textRangeView = [[CJSelectTextRangeView alloc]init];
        manager.textRangeView.hidden = YES;
        [manager addSubview:manager.textRangeView];
        
        manager.singleTapGes =[[UITapGestureRecognizer alloc] initWithTarget:manager action:@selector(tapOneAct:)];
        [manager addGestureRecognizer:manager.singleTapGes];
        
        manager.doubleTapGes =[[UITapGestureRecognizer alloc] initWithTarget:manager action:@selector(tapTwoAct:)];
        //几次点击时触发事件 ,默认值为1
        manager.doubleTapGes.numberOfTapsRequired = 2;
        manager.doubleTapGes.delegate = manager;
        [manager addGestureRecognizer:manager.doubleTapGes];
        //当单击操作遇到了 双击 操作时，单击失效
        [manager.singleTapGes requireGestureRecognizerToFail:manager.doubleTapGes];
        
        manager.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:manager
                                                                                    action:@selector(longPressGestureDidFire:)];
        manager.longPressGestureRecognizer.delegate = manager;
//        [manager addGestureRecognizer:manager.longPressGestureRecognizer];
        
    });
    return manager;
}

- (void)setLabel:(CJLabel *)label {
    _label = label;
    self.magnifierView.viewToMagnify = self;
}

#pragma mark - UIResponder
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if ( (action == @selector(select:) && self.label.attributedText) // 需要有文字才能支持选择复制
        || (action == @selector(selectAll:) && self.label.attributedText)
        || (action == @selector(copy:) && self.label.attributedText))
    {
        return YES;
    }
    return NO;
}

- (void)select:(nullable id)sender {
    _endCopyRunItem = [_startCopyRunItem copy];
    CGPoint point = CGPointMake(_startCopyRunItem.withOutMergeBounds.origin.x, _startCopyRunItem.withOutMergeBounds.origin.y);
    [self showCJSelectViewWithPoint:point
                         selectType:ShowAllSelectView
                               item:_startCopyRunItem
                   startCopyRunItem:_startCopyRunItem
                     endCopyRunItem:_endCopyRunItem
             allCTLineVerticalArray:_CTLineVerticalLayoutArray];
    self.magnifierView.hidden = YES;
    [self showMenuView];
}
- (void)selectAll:(nullable id)sender {
    _startCopyRunItem = [_firstRunItem copy];
    _endCopyRunItem = [_lastRunItem copy];
    CGPoint point = CGPointMake(_startCopyRunItem.withOutMergeBounds.origin.x, _startCopyRunItem.withOutMergeBounds.origin.y);
    [self showCJSelectViewWithPoint:point
                         selectType:ShowAllSelectView
                               item:_startCopyRunItem
                   startCopyRunItem:_startCopyRunItem
                     endCopyRunItem:_endCopyRunItem
             allCTLineVerticalArray:_CTLineVerticalLayoutArray];
    self.magnifierView.hidden = YES;
    [self showMenuView];
}
- (void)copy:(nullable id)sender {
    if (_startCopyRunItem && _endCopyRunItem) {
        
        NSUInteger loc = _startCopyRunItem.characterRange.location;
        loc = loc<=0?0:loc;
        
        NSUInteger length = _endCopyRunItem.characterRange.location+_endCopyRunItem.characterRange.length - loc;
        
        if (length >= self.label.attributedText.string.length-loc) {
            length = self.label.attributedText.string.length-loc;
        }
        
        NSRange rangeCopy = NSMakeRange(loc,length);
        NSString *str = [self.label.attributedText.string substringWithRange:rangeCopy];
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = str;
    }
    [self hideView];
}

- (void)showMenuView {
//    if (self.magnifierView.hidden && !self.selectRightView.hidden && !self.selectLeftView.hidden) {
    if (!self.selectRightView.hidden && !self.selectLeftView.hidden) {
        [self becomeFirstResponder];
        CGRect rect = CGRectMake((self.bounds.origin.x - (_lineVerticalMaxWidth/2 - _startCopyRunItem.withOutMergeBounds.origin.x)),
                                 _startCopyRunItemY-5,
                                 _lineVerticalMaxWidth,
                                 _endCopyRunItem.withOutMergeBounds.origin.y + _endCopyRunItem.withOutMergeBounds.size.height + 16);
        [[UIMenuController sharedMenuController] setTargetRect:rect inView:self];
        [[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
    }
}

- (void)showSelectViewInCJLabel:(CJLabel *)label
                        atPoint:(CGPoint)point
                        runItem:(CJGlyphRunStrokeItem *)item
                   maxLineWidth:(CGFloat)maxLineWidth
         allCTLineVerticalArray:(NSArray *)allCTLineVerticalArray
                allRunItemArray:(NSArray <CJGlyphRunStrokeItem *>*)allRunItemArray
{
    self.label = label;
    CGRect labelFrame = [label.superview convertRect:self.label.frame toView:keyWindow()];
    self.frame = labelFrame;
    _lineVerticalMaxWidth = maxLineWidth;
    _CTLineVerticalLayoutArray = allCTLineVerticalArray;
    _allRunItemArray = allRunItemArray;
    _firstRunItem = [[allRunItemArray firstObject] copy];
    _lastRunItem = [[allRunItemArray lastObject] copy];
    
    _startCopyRunItem = [item copy];
    _endCopyRunItem = _startCopyRunItem;
    [self showCJSelectViewWithPoint:point selectType:ShowAllSelectView item:_startCopyRunItem startCopyRunItem:_startCopyRunItem endCopyRunItem:_startCopyRunItem allCTLineVerticalArray:_CTLineVerticalLayoutArray];
    
    [keyWindow() addSubview:self];
    [keyWindow() bringSubviewToFront:self];
    
    [self showMenuView];
}

- (void)showCJSelectViewWithPoint:(CGPoint)point
                       selectType:(CJSelectViewAction)type
                             item:(CJGlyphRunStrokeItem *)item
                 startCopyRunItem:(CJGlyphRunStrokeItem *)startCopyRunItem
                   endCopyRunItem:(CJGlyphRunStrokeItem *)endCopyRunItem
           allCTLineVerticalArray:(NSArray *)allCTLineVerticalArray
{
    [[UIMenuController sharedMenuController] setMenuVisible:NO];
    
    CJCTLineVerticalLayout lineVerticalLayout = item.lineVerticalLayout;
    
    CGPoint selectPoint = CGPointMake(point.x, lineVerticalLayout.lineRect.origin.y);
    CGPoint pointToMagnify = CGPointMake(point.x, lineVerticalLayout.lineRect.origin.y + lineVerticalLayout.lineRect.size.height/2);
    //更新放大镜的位置
    CGPoint showMagnifierViewPoint = [self convertPoint:selectPoint toView:self.window];
    [self.magnifierView makeKeyAndVisible];
    self.magnifierView.hidden = NO;
    [self.magnifierView updateMagnifyPoint:pointToMagnify showMagnifyViewIn:showMagnifierViewPoint];
    
    
    [self updateSelectTextRangeViewStartCopyRunItem:startCopyRunItem endCopyRunItem:endCopyRunItem allCTLineVerticalArray:allCTLineVerticalArray finishBlock:^(CGFloat leftViewHeight, CGPoint leftViewPoint, CGFloat rightViewHeight, CGPoint rightViewPoint) {
        self.selectLeftView.hidden = self.selectRightView.hidden = NO;
        [self bringSubviewToFront:self.selectLeftView];
        [self bringSubviewToFront:self.selectRightView];
        
        if (type == ShowAllSelectView) {
            [self.selectLeftView updateCJSelectViewHeight:leftViewHeight showCJSelectViewIn:leftViewPoint];
            [self.selectRightView updateCJSelectViewHeight:rightViewHeight showCJSelectViewIn:rightViewPoint];
        }
        else if (type == MoveLeftSelectView) {
            [self.selectLeftView updateCJSelectViewHeight:leftViewHeight showCJSelectViewIn:leftViewPoint];
        }
        else if (type == MoveRightSelectView) {
            [self.selectRightView updateCJSelectViewHeight:rightViewHeight showCJSelectViewIn:rightViewPoint];
        }
    }];
}

/**
 更新选中复制的背景填充色
 */
- (void)updateSelectTextRangeViewStartCopyRunItem:(CJGlyphRunStrokeItem *)startCopyRunItem
                                   endCopyRunItem:(CJGlyphRunStrokeItem *)endCopyRunItem
                           allCTLineVerticalArray:(NSArray *)allCTLineVerticalArray
                                      finishBlock:(void(^)(CGFloat leftViewHeight, CGPoint leftViewPoint, CGFloat rightViewHeight, CGPoint rightViewPoint))finishBlock {
    
    CGRect frame = self.bounds;
    CGRect headRect = CGRectNull;
    CGRect middleRect = CGRectNull;
    CGRect tailRect = CGRectNull;
    
    CGFloat maxWidth = _lineVerticalMaxWidth;
    
    //headRect 坐标
    CGFloat startCopyRunItemY = startCopyRunItem.lineVerticalLayout.lineRect.origin.y;
    CGFloat startCopyLintHeight = startCopyRunItem.lineVerticalLayout.lineRect.size.height;
    CGFloat headHeight = ({
        CGFloat height = startCopyRunItem.lineVerticalLayout.lineRect.size.height;
        height = MAX(height, startCopyRunItem.lineVerticalLayout.maxRunHeight);
        height = MAX(height, startCopyRunItem.lineVerticalLayout.maxImageHeight);
        height;
    });
    startCopyRunItemY = startCopyRunItemY - (headHeight - startCopyLintHeight);
    _startCopyRunItemY = startCopyRunItemY;
    CGFloat headWidth = maxWidth - startCopyRunItem.withOutMergeBounds.origin.x;
    headRect = CGRectMake(startCopyRunItem.withOutMergeBounds.origin.x, startCopyRunItemY, headWidth, headHeight);
    
    CGFloat maxHeight = endCopyRunItem.lineVerticalLayout.lineRect.origin.y + endCopyRunItem.lineVerticalLayout.lineRect.size.height - startCopyRunItemY - self.label.font.descender;
    
    //tailRect 坐标
    CGFloat tailWidth = endCopyRunItem.withOutMergeBounds.origin.x+endCopyRunItem.withOutMergeBounds.size.width;
    CGFloat tailHeight = endCopyRunItem.lineVerticalLayout.lineRect.size.height - self.label.font.descender;
    CGFloat endCopyRunItemY = endCopyRunItem.lineVerticalLayout.lineRect.origin.y;
    CGFloat tailY = ({
        CGFloat yy = endCopyRunItem.lineVerticalLayout.lineRect.origin.y;
        for (NSValue *value in allCTLineVerticalArray) {
            CJCTLineVerticalLayout themLineVerticalLayout;
            [value getValue:&themLineVerticalLayout];
            if (themLineVerticalLayout.line+1 == endCopyRunItem.lineVerticalLayout.line) {
                yy = themLineVerticalLayout.lineRect.origin.y + themLineVerticalLayout.lineRect.size.height;
                break;
            }
        }
        yy;
    });
    tailHeight = tailHeight + (endCopyRunItemY - tailY);
    tailRect = CGRectMake(0, tailY, tailWidth, tailHeight);
    
    BOOL differentLine = YES;
    if (startCopyRunItem.lineVerticalLayout.line == endCopyRunItem.lineVerticalLayout.line) {
        differentLine = NO;
        headRect = CGRectNull;
        middleRect = CGRectMake(startCopyRunItem.withOutMergeBounds.origin.x,
                                startCopyRunItemY,
                                endCopyRunItem.withOutMergeBounds.origin.x+endCopyRunItem.withOutMergeBounds.size.width-startCopyRunItem.withOutMergeBounds.origin.x,
                                headHeight);
        tailRect = CGRectNull;
    }else{
        //相差一行
        if (startCopyRunItem.lineVerticalLayout.line + 1 == endCopyRunItem.lineVerticalLayout.line) {
            middleRect = CGRectNull;
        }else{
            middleRect = CGRectMake(0, startCopyRunItemY+headHeight, maxWidth, maxHeight-headHeight-tailHeight);
        }
    }
    
    [self.textRangeView updateFrame:frame headRect:headRect middleRect:middleRect tailRect:tailRect differentLine:differentLine];
    
    self.textRangeView.hidden = NO;
    [self bringSubviewToFront:self.textRangeView];
    
    finishBlock(headHeight,
                CGPointMake(startCopyRunItem.withOutMergeBounds.origin.x, startCopyRunItemY),
                tailHeight,
                CGPointMake(tailWidth,tailY+tailHeight));
}

- (CJSelectView *)choseSelectView:(CGPoint)point {
    if (self.selectLeftView.hidden && self.selectRightView.hidden) {
        return nil;
    }
    CJSelectView *selectView = [self choseSelectView:point inset:1];
    return selectView;
}

- (CJSelectView *)choseSelectView:(CGPoint)point inset:(CGFloat)inset {
    CJSelectView *selectView = nil;
    
    BOOL inLeftView = CGRectContainsPoint(CGRectInset(self.selectLeftView.frame, inset, inset), point);
    BOOL inRightView = CGRectContainsPoint(CGRectInset(self.selectRightView.frame, inset, inset), point);
    
    if (!inLeftView && !inRightView) {
        return [self choseSelectView:point inset:inset+(-0.15)];
    }
    else if (inLeftView && !inRightView) {
        selectView = self.selectLeftView;
        return selectView;
    }
    else if (!inLeftView && inRightView) {
        selectView = self.selectRightView;
        return selectView;
    }
    else if (inLeftView && inRightView) {
        return [self choseSelectView:point inset:inset+(0.25)];
    }else{
        return selectView;
    }
}

- (void)hideView {
    [self hideAllCopySelectView];
    [self removeFromSuperview];
}

/**
 隐藏所有与选择复制相关的视图
 */
- (void)hideAllCopySelectView {
    _startCopyRunItem = nil;
    _endCopyRunItem = nil;
    self.selectLeftView.hidden = YES;
    self.selectRightView.hidden = YES;
    self.textRangeView.hidden = YES;
    self.magnifierView.hidden = YES;
    [[UIMenuController sharedMenuController] setMenuVisible:NO];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event {
    //接收任意视图的点击响应
    return YES;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (CGRectContainsPoint(self.bounds, point)) {
        return self;
    }else{
        [self hideView];
        return nil;
    }
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([gestureRecognizer isKindOfClass:[UISwipeGestureRecognizer class]]) {
        objc_setAssociatedObject(gestureRecognizer, "UITouch", touch, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    else if (gestureRecognizer == self.doubleTapGes) {
        objc_setAssociatedObject(self.doubleTapGes, "UITouch", touch, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return YES;
}

- (void)tapOneAct:(UITapGestureRecognizer *)sender {
    [self hideView];
}

- (void)tapTwoAct:(UITapGestureRecognizer *)sender {
    UITouch *touch = objc_getAssociatedObject(self.doubleTapGes, "UITouch");
    CGPoint point = [touch locationInView:self];
    CJGlyphRunStrokeItem *currentItem = nil;
    for (CJGlyphRunStrokeItem *item in _allRunItemArray) {
        if (CGRectContainsPoint(item.withOutMergeBounds, point)) {
            currentItem = [item copy];
            break;
        }
    }
    if (currentItem) {
        _startCopyRunItem = currentItem;
        _endCopyRunItem = currentItem;
        [self showCJSelectViewWithPoint:point selectType:ShowAllSelectView item:currentItem startCopyRunItem:currentItem endCopyRunItem:currentItem allCTLineVerticalArray:_CTLineVerticalLayoutArray];
        [self showMenuView];
    }
}

#pragma mark - UILongPressGestureRecognizer
- (void)longPressGestureDidFire:(UILongPressGestureRecognizer *)sender {
    
    UITouch *touch = objc_getAssociatedObject(self.longPressGestureRecognizer, "UITouch");
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            //发生长按，隐藏选择相关的视图
            [self hideAllCopySelectView];
            break;
        }
        case UIGestureRecognizerStateEnded:{
            //隐藏放大镜，显示菜单
            [self.magnifierView setHidden:YES];
            [self showMenuView];
            break;
        }
        case UIGestureRecognizerStateChanged:{
            CGPoint point = [touch locationInView:self];
            CJGlyphRunStrokeItem *currentItem = nil;
            for (CJGlyphRunStrokeItem *item in _allRunItemArray) {
                if (CGRectContainsPoint(item.withOutMergeBounds, point)) {
                    currentItem = [item copy];
                    break;
                }
            }
            if (currentItem) {
                _startCopyRunItem = currentItem;
                _endCopyRunItem = currentItem;
                [self showCJSelectViewWithPoint:point selectType:ShowAllSelectView item:currentItem startCopyRunItem:currentItem endCopyRunItem:currentItem allCTLineVerticalArray:_CTLineVerticalLayoutArray];
                [self showMenuView];
            }
        }
        default:
            break;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint point = [[touches anyObject] locationInView:self];
    //复制选择正在移动的大头针(用来判断selectLeftView还是selectRightView的临时视图)
    self.selectView = [self choseSelectView:point];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.selectLeftView.hidden && !self.selectRightView.hidden) {
        [self showMenuView];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint point = [[touches anyObject] locationInView:self];
    
    CJGlyphRunStrokeItem *currentItem = nil;
    
    //第一个CTRun选中判断
//    CGFloat firstRunItemX = _firstRunItem.withOutMergeBounds.origin.x;
//    CGFloat firstRunItemY = _firstRunItem.withOutMergeBounds.origin.y;
//    CGFloat firstRunItemHeight = _firstRunItem.withOutMergeBounds.size.height;
//    if (point.y < firstRunItemY - 1) {
//        currentItem = [_firstRunItem copy];
//    }
//    else if (point.x <= firstRunItemX && (point.y < firstRunItemY + firstRunItemHeight - 1) && (point.y > firstRunItemY - 1)){
//        currentItem = [_firstRunItem copy];
//    }
    //最后一个CTRun选中判断
    CGFloat lastRunItemX = _lastRunItem.withOutMergeBounds.origin.x;
    CGFloat lastRunItemY = _lastRunItem.withOutMergeBounds.origin.y;
    CGFloat lastRunItemHeight = _lastRunItem.withOutMergeBounds.size.height;
    CGFloat lastRunItemWidth = _lastRunItem.withOutMergeBounds.size.width;
    
    if ((point.x >= lastRunItemX + lastRunItemWidth) && (point.y >= lastRunItemY)) {
        currentItem = [_lastRunItem copy];
    }
    else if (point.y > lastRunItemY + lastRunItemHeight + 1) {
        currentItem = [_lastRunItem copy];
    }
    
    if (!currentItem) {
        for (CJGlyphRunStrokeItem *item in _allRunItemArray) {
            if (CGRectContainsPoint(item.withOutMergeBounds, point)) {
                currentItem = [item copy];
                break;
            }
        }
    }
    
    if (currentItem) {
        
        CJSelectView *selectView = [self choseSelectView:point];

        CGPoint selectPoint = CGPointMake(point.x, (selectView.frame.size.height/2)+selectView.frame.origin.y);
        if (self.selectView == self.selectLeftView) {
            if (currentItem.characterIndex < _endCopyRunItem.characterIndex) {
                _startCopyRunItem = currentItem;
                [self showCJSelectViewWithPoint:selectPoint
                                     selectType:MoveLeftSelectView
                                           item:currentItem
                               startCopyRunItem:_startCopyRunItem
                                 endCopyRunItem:_endCopyRunItem
                         allCTLineVerticalArray:_CTLineVerticalLayoutArray];
            }
            else if (currentItem.characterIndex == _endCopyRunItem.characterIndex){
                _startCopyRunItem = [currentItem copy];
                _endCopyRunItem = _startCopyRunItem;
                [self showCJSelectViewWithPoint:selectPoint
                                     selectType:ShowAllSelectView
                                           item:_startCopyRunItem
                               startCopyRunItem:_startCopyRunItem
                                 endCopyRunItem:_endCopyRunItem
                         allCTLineVerticalArray:_CTLineVerticalLayoutArray];
                NSLog(@"LeftView 最后");
            }
        }
        else if (self.selectView == self.selectRightView) {
            if (currentItem.characterIndex > _startCopyRunItem.characterIndex) {
                _endCopyRunItem = [currentItem copy];
                [self showCJSelectViewWithPoint:selectPoint
                                     selectType:MoveRightSelectView
                                           item:currentItem
                               startCopyRunItem:_startCopyRunItem
                                 endCopyRunItem:_endCopyRunItem
                         allCTLineVerticalArray:_CTLineVerticalLayoutArray];
            }
            else if (currentItem.characterIndex == _startCopyRunItem.characterIndex){
                _startCopyRunItem = [currentItem copy];
                _endCopyRunItem = _startCopyRunItem;
                [self showCJSelectViewWithPoint:selectPoint
                                     selectType:ShowAllSelectView
                                           item:_startCopyRunItem
                               startCopyRunItem:_startCopyRunItem
                                 endCopyRunItem:_endCopyRunItem
                         allCTLineVerticalArray:_CTLineVerticalLayoutArray];
                NSLog(@"RightView 最后");
            }
        }
    }
    else{
//        NSLog(@"没有item");
    }
}
@end


