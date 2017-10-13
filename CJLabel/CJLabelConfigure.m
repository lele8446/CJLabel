//
//  CJLabelConfigure.m
//  CJLabelTest
//
//  Created by ChiJinLian on 2017/4/13.
//  Copyright © 2017年 ChiJinLian. All rights reserved.
//

#import "CJLabelConfigure.h"

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
    item.fillCopyColor = self.fillCopyColor;
    item.strokeColor = self.strokeColor;
    item.fillColor = self.fillColor;
    item.lineWidth = self.lineWidth;
    item.runBounds = self.runBounds;
    item.locBounds = self.locBounds;
    item.cornerRadius = self.cornerRadius;
    item.activeFillColor = self.activeFillColor;
    item.activeStrokeColor = self.activeStrokeColor;
    item.imageName = self.imageName;
    item.isImage = self.isImage;
    item.range = self.range;
    item.parameter = self.parameter;
    item.lineVerticalLayout = self.lineVerticalLayout;
    item.isSelect = self.isSelect;
    item.linkBlock = self.linkBlock;
    item.longPressBlock = self.longPressBlock;
    item.isLink = self.isLink;
    item.needRedrawn = self.needRedrawn;
    return item;
}

@end

@interface CJMagnifierView ()
@property (strong, nonatomic) CALayer *contentLayer;
@end
@implementation CJMagnifierView

- (id)init {
    self = [super init];
    if (self) {
        self.frame = CGRectMake(0, 0, 120, 65);
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
        self.frame = CGRectMake(0, 0, 10, 40);
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
    if (self.isLeft) {
        self.frame = CGRectMake(showPoint.x-5, showPoint.y-10-2, 10, height+10);
        self.lineLayer.frame = CGRectMake(4, 10, 2, 20);
        self.roundLayer.frame = CGRectMake(0, 0, 10, 10);
    }else{
        self.frame = CGRectMake(showPoint.x-5, showPoint.y-2, 10, height+10);
        self.lineLayer.frame = CGRectMake(4, 0, 2, 20);
        self.roundLayer.frame = CGRectMake(0, 20, 10, 10);
    }
}

@end

