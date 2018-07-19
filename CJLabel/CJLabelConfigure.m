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

NSString * const kCJInsertViewTag                            = @"kCJInsertViewTag";
NSString * const kCJInsertBackViewTag                        = @"kCJInsertBackViewTag";

NSString * const kCJImageAttributeName                       = @"kCJImageAttributeName";
NSString * const kCJImage                                    = @"kCJImage";
NSString * const kCJImageHeight                              = @"kCJImageHeight";
NSString * const kCJImageWidth                               = @"kCJImageWidth";
NSString * const kCJImageLineVerticalAlignment               = @"kCJImageLineVerticalAlignment";

NSString * const kCJLinkAttributesName                       = @"kCJLinkAttributesName";
NSString * const kCJActiveLinkAttributesName                 = @"kCJActiveLinkAttributesName";
NSString * const kCJIsLinkAttributesName                     = @"kCJIsLinkAttributesName";
NSString * const kCJLinkIdentifierAttributesName             = @"kCJLinkIdentifierAttributesName";
NSString * const kCJLinkLengthAttributesName                 = @"kCJLinkLengthAttributesName";
NSString * const kCJLinkRangeAttributesName                  = @"kCJLinkRangeAttributesName";
NSString * const kCJLinkParameterAttributesName              = @"kCJLinkParameterAttributesName";
NSString * const kCJClickLinkBlockAttributesName             = @"kCJClickLinkBlockAttributesName";
NSString * const kCJLongPressBlockAttributesName             = @"kCJLongPressBlockAttributesName";
NSString * const kCJLinkNeedRedrawnAttributesName            = @"kCJLinkNeedRedrawnAttributesName";


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
- (void)addAttributes:(id)attributes key:(NSString *)key {
    NSMutableDictionary *attributesDic = [NSMutableDictionary dictionaryWithCapacity:3];
    if (self.attributes) {
        [attributesDic addEntriesFromDictionary:self.attributes];
    }
    if (attributes && key.length > 0) {
        [attributesDic setObject:attributes forKey:key];
        self.attributes = attributesDic;
    }
}

- (void)removeAttributesForKey:(NSString *)key {
    if (self.attributes && key.length > 0) {
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:self.attributes];
        [attributes removeObjectForKey:key];
        self.attributes = attributes;
    }
}

- (void)addActiveAttributes:(id)activeAttributes key:(NSString *)key {
    NSMutableDictionary *activeAttributesDic = [NSMutableDictionary dictionaryWithCapacity:3];
    if (self.activeLinkAttributes) {
        [activeAttributesDic addEntriesFromDictionary:self.activeLinkAttributes];
    }
    if (activeAttributes && key.length > 0) {
        [activeAttributesDic setObject:activeAttributes forKey:key];
        self.activeLinkAttributes = activeAttributesDic;
    }
}

- (void)removeActiveLinkAttributesForKey:(NSString *)key {
    if (self.activeLinkAttributes && key.length > 0) {
        NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithDictionary:self.activeLinkAttributes];
        [attributes removeObjectForKey:key];
        self.activeLinkAttributes = attributes;
    }
}

+ (NSMutableAttributedString *)configureLinkAttributedString:(NSAttributedString *)attrStr
                                                    addImage:(id)image
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
    NSParameterAssert((loc <= attrStr.length) && (!CJLabelIsNull(image)));
    if ([image isKindOfClass:[NSString class]]) {
       NSParameterAssert([image length] != 0);
    }
    
    NSDictionary *imgInfoDic = @{kCJImage:image,
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
    
    unichar imgReplacementChar = 0xFFFC;
    NSString *imgReplacementString = [NSString stringWithCharacters:&imgReplacementChar length:1];
    //插入图片 空白占位符
    NSMutableString *imgPlaceholderStr = [[NSMutableString alloc]initWithCapacity:3];
    [imgPlaceholderStr appendString:imgReplacementString];
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
        [imageAttributedString addAttribute:kCJLinkIdentifierAttributesName value:@(arc4random()) range:imgRange];
        [imageAttributedString addAttribute:kCJLinkLengthAttributesName value:@(imgRange.length) range:imgRange];
    }else{
        [imageAttributedString addAttribute:kCJIsLinkAttributesName value:@(NO) range:imgRange];
        [imageAttributedString addAttribute:kCJLinkLengthAttributesName value:@(0) range:imgRange];
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
        [attributedString addAttribute:kCJLinkIdentifierAttributesName value:@(arc4random()) range:range];
        [attributedString addAttribute:kCJLinkLengthAttributesName value:@(range.length) range:range];
    }else{
        [attributedString addAttribute:kCJIsLinkAttributesName value:@(NO) range:range];
        [attributedString addAttribute:kCJLinkLengthAttributesName value:@(0) range:range];
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
            for (NSValue *rangeValue in rangeAry) {
                attributedString = [self configureLinkAttributedString:attributedString atRange:rangeValue.rangeValue linkAttributes:linkAttributes activeLinkAttributes:activeLinkAttributes parameter:parameter clickLinkBlock:clickLinkBlock longPressBlock:longPressBlock islink:isLink];
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
            for (NSValue *rangeValue in rangeAry) {
                attributedString = [self configureLinkAttributedString:attributedString atRange:rangeValue.rangeValue linkAttributes:linkAttributes activeLinkAttributes:activeLinkAttributes parameter:parameter clickLinkBlock:clickLinkBlock longPressBlock:longPressBlock islink:isLink];
            }
        }
    }
    return attributedString;
}

+ (NSMutableAttributedString *)configureAttrString:(NSAttributedString *)attrString strIdentifier:(NSString *)strIdentifier configure:(CJLabelConfigure *)configure linkRangeAry:(NSArray *)linkRangeAry {
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithAttributedString:attrString];
    if (linkRangeAry.count > 0) {
        for (NSValue *rangeValue in linkRangeAry) {
            attributedString = [self configureLinkAttributedString:attributedString atRange:rangeValue.rangeValue linkAttributes:configure.attributes activeLinkAttributes:configure.activeLinkAttributes parameter:configure.parameter clickLinkBlock:configure.clickLinkBlock longPressBlock:configure.longPressBlock islink:configure.isLink];
        }
    }
    return attributedString;
}

+ (NSMutableAttributedString *)linkAttStr:(NSString *)string
                               attributes:(NSDictionary <NSString *,id>*)attrs
                               identifier:(NSString *)identifier
{
    NSParameterAssert(string);
    if (CJLabelIsNull(identifier) || identifier.length == 0) {
        identifier = @"";
    }
    
    NSDictionary *dic = CJLabelIsNull(attrs)?[[NSDictionary alloc] init]:[[NSDictionary alloc]initWithDictionary:attrs];
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc]initWithString:string attributes:dic];
    [attStr addAttribute:kCJLinkStringIdentifierAttributesName value:identifier range:NSMakeRange(0, attStr.length)];
    
    return attStr;
}

#pragma mark - 获取链点的NSRange
+ (NSRange)getFirstRangeWithString:(NSString *)withString inAttString:(NSAttributedString *)attString {
    NSRange range = [attString.string rangeOfString:withString];
    if (range.location == NSNotFound) {
        return range;
    }
    return range;
}

+ (NSArray <NSValue *>*)getLinkStringRangeArray:(NSString *)linkString inAttString:(NSAttributedString *)attString {
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
    NSString *identifier = strDic[kCJLinkStringIdentifierAttributesName];
    
    NSRange withStrRange = NSMakeRange(0, withAttString.length);
    NSDictionary *withStrDic = nil;
    if (withStrRange.length > 0) {
        withStrDic = [withAttString attributesAtIndex:0 effectiveRange:&withStrRange];
    }
    NSString *withIdentifier = withStrDic[kCJLinkStringIdentifierAttributesName];
    
    if (!identifier || !identifier || ![identifier isEqualToString:withIdentifier]) {
        range = NSMakeRange(NSNotFound, 0);
    }
    return range;
}

+ (NSArray <NSValue *>*)getLinkAttStringRangeArray:(NSAttributedString *)linkAttString inAttString:(NSAttributedString *)attString {
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:3];
    NSArray *strRanges = [self getRangeArrayWithString:linkAttString.string inString:attString.string lastRange:NSMakeRange(0, 0) rangeArray:[NSMutableArray array]];
    
    if (strRanges.count > 0) {
        
        NSRange withStrRange = NSMakeRange(0, linkAttString.length);
        NSDictionary *withStrDic = nil;
        if (withStrRange.length > 0) {
            withStrDic = [linkAttString attributesAtIndex:0 effectiveRange:&withStrRange];
        }
        NSString *withKey = withStrDic[kCJLinkStringIdentifierAttributesName];
        
        [strRanges enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSValue *rangeValue = (NSValue *)obj;
            NSRange range = rangeValue.rangeValue;
            NSAttributedString *str = [attString attributedSubstringFromRange:range];
            NSRange strRange = NSMakeRange(0, str.length);
            NSDictionary *strDic = nil;
            if (strRange.length > 0) {
                strDic = [str attributesAtIndex:0 effectiveRange:&strRange];
            }
            NSString *key = strDic[kCJLinkStringIdentifierAttributesName];
            
            if (key.length > 0) {
                if ([key isEqualToString:withKey]) {
                    [array addObject:rangeValue];
                }
            }else{
                if (withKey.length > 0) {
                    [array addObject:rangeValue];
                }
            }
        }];
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
+ (NSArray <NSValue *>*)getRangeArrayWithString:(NSString *)withString
                                        inString:(NSString *)string
                                       lastRange:(NSRange)lastRange
                                      rangeArray:(NSMutableArray *)array
{
    NSRange range = [string rangeOfString:withString];
    if (range.location == NSNotFound){
        return array;
    }else{
        NSRange curRange = NSMakeRange(lastRange.location+lastRange.length+range.location, range.length);
        [array addObject:[NSValue valueWithRange:curRange]];
        NSString *tempString = [string substringFromIndex:(range.location+range.length)];
        [self getRangeArrayWithString:withString inString:tempString lastRange:curRange rangeArray:array];
        return array;
    }
}

@end


@implementation CJLabelLinkModel
- (instancetype)initWithAttributedString:(NSAttributedString *)attributedString
                              insertView:(id)insertView
                          insertViewRect:(CGRect)insertViewRect
                               parameter:(id)parameter
                               linkRange:(NSRange)linkRange
                                   label:(CJLabel *)label
{
    self = [super init];
    if (self) {
        _attributedString = attributedString;
        if ([insertView isKindOfClass:[UIView class]]) {
            _insertView = [(UIView *)insertView viewWithTag:[kCJInsertViewTag hash]];
        }else{
            _insertView = insertView;
        }
        _insertViewRect = insertViewRect;
        _parameter = parameter;
        _linkRange = linkRange;
        _label = label;
    }
    return self;
}
@end

@implementation CJGlyphRunStrokeItem

- (id)copyWithZone:(NSZone *)zone {
    CJGlyphRunStrokeItem *item = [[[self class] allocWithZone:zone] init];
    item.fillColor = self.fillColor;
    item.strokeColor = self.strokeColor;
    item.activeFillColor = self.activeFillColor;
    item.activeStrokeColor = self.activeStrokeColor;
    item.strokeLineWidth = self.strokeLineWidth;
    item.cornerRadius = self.cornerRadius;
    item.runBounds = self.runBounds;
    item.locBounds = self.locBounds;
    item.withOutMergeBounds = self.withOutMergeBounds;
    item.runDescent = self.runDescent;
    item.runRef = self.runRef;
    
    item.insertView = self.insertView;
    item.isInsertView = self.isInsertView;
    item.range = self.range;
    item.parameter = self.parameter;
    item.lineVerticalLayout = self.lineVerticalLayout;
    item.isLink = self.isLink;
    item.needRedrawn = self.needRedrawn;
    item.linkBlock = self.linkBlock;
    item.longPressBlock = self.longPressBlock;
    item.characterIndex = self.characterIndex;
    item.characterRange = self.characterRange;
    item.strikethroughStyle = self.strikethroughStyle;
    item.strikethroughColor = self.strikethroughColor;
    return item;
}

@end

@implementation CJCTLineLayoutModel

@end

@interface CJContentLayer : CALayer
@property (nonatomic, assign) CGPoint pointToMagnify;//放大点
@end
@implementation CJContentLayer

- (void)drawInContext:(CGContextRef)ctx {
    CGContextTranslateCTM(ctx, self.frame.size.width/2, self.frame.size.height/2);
    CGContextScaleCTM(ctx, 1.40, 1.40);
    CGContextTranslateCTM(ctx, -1 * self.pointToMagnify.x, -1 * self.pointToMagnify.y);
    [CJkeyWindow().layer renderInContext:ctx];
    CJkeyWindow().layer.contents = (id)nil;
}
@end

/**
 长按时候显示的放大镜视图
 */
@interface CJMagnifierView ()
@property (nonatomic, assign) CGPoint pointToMagnify;//放大点
@property (nonatomic, strong) CJContentLayer *contentLayer;//处理放大效果的layer层

- (void)updateMagnifyPoint:(CGPoint)pointToMagnify showMagnifyViewIn:(CGPoint)showPoint;

@end

@implementation CJMagnifierView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        //白色背景
        CALayer *backLayer = [CALayer layer];
        backLayer.frame = CGRectMake(0, 0, 120, 30);
        backLayer.backgroundColor = [UIColor whiteColor].CGColor;
        backLayer.cornerRadius = 5;
        backLayer.borderWidth = 1;
        backLayer.borderColor = [[UIColor lightGrayColor] CGColor];
        //masksToBounds开启会影响阴影效果
        //        backLayer.masksToBounds = YES;
        backLayer.shadowColor = [UIColor lightGrayColor].CGColor;
        backLayer.shadowOffset = CGSizeMake(1,0);
        backLayer.shadowOpacity = 0.75;
        backLayer.shadowRadius = 0.75;
        [self.layer addSublayer:backLayer];
        
        CALayer *backLayer2 = [CALayer layer];
        backLayer2.frame = CGRectMake(0, 0, 120, 30);
        backLayer2.backgroundColor = [UIColor whiteColor].CGColor;
        backLayer2.cornerRadius = 5;
        backLayer2.borderWidth = 1;
        backLayer2.borderColor = [[UIColor lightGrayColor] CGColor];
        //masksToBounds开启会影响阴影效果
        //        backLayer.masksToBounds = YES;
        backLayer2.shadowColor = [UIColor lightGrayColor].CGColor;
        backLayer2.shadowOffset = CGSizeMake(0,1);
        backLayer2.shadowOpacity = 1;
        backLayer2.shadowRadius = 1;
        [self.layer addSublayer:backLayer2];
        
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
        self.contentLayer = [CJContentLayer layer];
        self.contentLayer.frame = CGRectMake(0, 0, 120, 30);
        self.contentLayer.cornerRadius = 5;
        self.contentLayer.masksToBounds = YES;
        self.contentLayer.contentsScale = [[UIScreen mainScreen] scale];
        [self.layer addSublayer:self.contentLayer];
    }
    return self;
}


- (void)setPointToMagnify:(CGPoint)pointToMagnify {
    _pointToMagnify = pointToMagnify;
    self.contentLayer.pointToMagnify = pointToMagnify;
    [self.contentLayer setNeedsDisplay];
}

- (void)updateMagnifyPoint:(CGPoint)pointToMagnify showMagnifyViewIn:(CGPoint)showPoint {
    CGPoint center = CGPointMake(showPoint.x, self.center.y);
    if (showPoint.y > CGRectGetHeight(self.bounds) / 2) {
        center.y = showPoint.y -  CGRectGetHeight(self.bounds) / 2;
    }
    self.center = CGPointMake(center.x, center.y);
    self.pointToMagnify = pointToMagnify;
}

@end

/**
 大头针的显示类型
 */
typedef NS_ENUM(NSInteger, CJSelectViewAction) {
    ShowAllSelectView    = 0,//显示大头针（长按或者双击）
    MoveLeftSelectView   = 1,//移动左边大头针
    MoveRightSelectView  = 2 //移动右边大头针
};
/**
 选中复制填充背景色的view
 */
@interface CJSelectTextRangeView : UIView
/**
 前半部分选中区域
 */
@property (nonatomic, assign) CGRect headRect;
/**
 中间部分选中区域
 */
@property (nonatomic, assign) CGRect middleRect;
/**
 后半部分选中区域
 */
@property (nonatomic, assign) CGRect tailRect;
/**
 选择内容是否包含不同行
 */
@property (nonatomic, assign) BOOL differentLine;
- (void)updateFrame:(CGRect)frame headRect:(CGRect)headRect middleRect:(CGRect)middleRect tailRect:(CGRect)tailRect differentLine:(BOOL)differentLine;
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
    
    if (self.differentLine) {
        [backColor set];
        CGContextAddRect(ctx, self.headRect);
        if (!CGRectEqualToRect(self.middleRect,CGRectNull)) {
            CGContextAddRect(ctx, self.middleRect);
        }
        CGContextAddRect(ctx, self.tailRect);
        CGContextFillPath(ctx);
        
        [self updatePinLayer:ctx point:CGPointMake(self.headRect.origin.x, self.headRect.origin.y) height:self.headRect.size.height isLeft:YES];
        
        [self updatePinLayer:ctx point:CGPointMake(self.tailRect.origin.x + self.tailRect.size.width, self.tailRect.origin.y) height:self.tailRect.size.height isLeft:NO];
    }else{
        
        [backColor set];
        CGContextAddRect(ctx, self.middleRect);
        CGContextFillPath(ctx);
        
        [self updatePinLayer:ctx point:CGPointMake(self.middleRect.origin.x, self.middleRect.origin.y) height:self.middleRect.size.height isLeft:YES];
        
        [self updatePinLayer:ctx point:CGPointMake(self.middleRect.origin.x + self.middleRect.size.width, self.middleRect.origin.y) height:self.middleRect.size.height isLeft:NO];
    }
    
    CGContextStrokePath(ctx);
}

- (void)updatePinLayer:(CGContextRef)ctx point:(CGPoint)point height:(CGFloat)height isLeft:(BOOL)isLeft {
    UIColor *color = [UIColor colorWithRed:0/255.0 green:128/255.0 blue:255/255.0 alpha:1.0];
    CGRect roundRect = CGRectMake(point.x - 5,
                                  isLeft?(point.y - 10):(point.y + height),
                                  10,
                                  10);
    //画圆
    CGContextAddEllipseInRect(ctx, roundRect);
    [color set];
    CGContextFillPath(ctx);
    
    CGContextMoveToPoint(ctx, point.x, point.y);
    CGContextAddLineToPoint(ctx, point.x, point.y + height);
    CGContextSetLineWidth(ctx, 2.0);
    CGContextSetStrokeColorWithColor(ctx, color.CGColor);
    
    CGContextStrokePath(ctx);
}

@end


/**
 添加在window层的view，用来检测点击任意view时隐藏CJSelectBackView
 */
@interface CJWindowView : UIView
@property (nonatomic, copy) void(^hitTestBlock)(BOOL hide);
@end
@implementation CJWindowView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    self.backgroundColor = [UIColor clearColor];
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!CGRectContainsPoint(self.bounds, point)) {
        self.hitTestBlock(YES);
    }
    return nil;
}
@end


/**
 选择复制view
 */
@interface CJSelectCopyManagerView()<UIGestureRecognizerDelegate>
{
    CGFloat _lineVerticalMaxWidth;//每一行文字中的最大宽度
    NSArray *_CTLineVerticalLayoutArray;//记录 所有CTLine在垂直方向的对齐方式的数组
    NSArray <CJGlyphRunStrokeItem *>*_allRunItemArray;//CJLabel包含所有CTRun信息的数组
    CJGlyphRunStrokeItem *_firstRunItem;//第一个StrokeItem
    CJGlyphRunStrokeItem *_lastRunItem;//最后一个StrokeItem
    CJGlyphRunStrokeItem *_startCopyRunItem;//选中复制的第一个StrokeItem
    CGFloat _startCopyRunItemY;//_startCopyRunItem Y坐标 显示Menu（选择、全选、复制菜单时用到）
    CJGlyphRunStrokeItem *_endCopyRunItem;//选中复制的最后一个StrokeItem
    BOOL _haveMove;
}
@property (nonatomic, strong) UITapGestureRecognizer *singleTapGes;//单击手势
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGes;//双击手势
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;//长按手势

@property (nonatomic, weak) CJLabel *label;//选择复制对应的label
@property (nonatomic, strong) CJSelectTextRangeView *textRangeView;//选中复制填充背景色的view
@property (nonatomic, assign) CJSelectViewAction selectViewAction;//用于判断选中移动的是左边还是右边的大头针
@property (nonatomic, strong) CJWindowView *backWindView;//添加在window层的view，用来检测点击任意view时隐藏CJSelectBackView
@property (nonatomic, strong) NSMutableArray *scrlooViewArray;//记录CJLabel所属的superview数组

@property (nonatomic, copy) void(^hideViewBlock)(void);

@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) NSAttributedString *attributedText;
@end
@implementation CJSelectCopyManagerView
+ (instancetype)instance {
    static CJSelectCopyManagerView *manager = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        manager = [[CJSelectCopyManagerView alloc] initWithFrame:CGRectZero];
        manager.backgroundColor = [UIColor clearColor];
        
        manager.backWindView = [[CJWindowView alloc]initWithFrame:CGRectMake(0, 0, 1, 1)];
        __weak typeof(manager)wManager = manager;
        manager.backWindView.hitTestBlock = ^(BOOL hide) {
            [wManager hideView];
        };

        /*
         *选择复制填充背景色视图
         */
        manager.textRangeView = [[CJSelectTextRangeView alloc]init];
        manager.textRangeView.hidden = YES;
        [manager addSubview:manager.textRangeView];
        //放大镜
        manager.magnifierView = [[CJMagnifierView alloc] initWithFrame:CGRectMake(0, 0, 120, 44)];
        
        manager.singleTapGes =[[UITapGestureRecognizer alloc] initWithTarget:manager action:@selector(tapOneAct:)];
        [manager addGestureRecognizer:manager.singleTapGes];
        
        manager.doubleTapGes =[[UITapGestureRecognizer alloc] initWithTarget:manager action:@selector(tapTwoAct:)];
        //双击时触发事件 ,默认值为1
        manager.doubleTapGes.numberOfTapsRequired = 2;
        manager.doubleTapGes.delegate = manager;
        [manager addGestureRecognizer:manager.doubleTapGes];
        //当单击操作遇到了 双击 操作时，单击失效
        [manager.singleTapGes requireGestureRecognizerToFail:manager.doubleTapGes];
        
        manager.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:manager
                                                                                    action:@selector(longPressGestureDidFire:)];
        manager.longPressGestureRecognizer.delegate = manager;
        [manager addGestureRecognizer:manager.longPressGestureRecognizer];
        
        [[NSNotificationCenter defaultCenter] addObserver:manager selector:@selector(applicationEnterBackground) name: UIApplicationDidEnterBackgroundNotification object:nil];
        
        manager.scrlooViewArray = [NSMutableArray arrayWithCapacity:3];
    
    });
    return manager;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationEnterBackground {
    [self hideView];
}

#pragma mark - UIResponder
- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if ( (action == @selector(select:) && self.attributedText) // 需要有文字才能支持选择复制
        || (action == @selector(selectAll:) && self.attributedText)
        || (action == @selector(copy:) && self.attributedText))
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
             allCTLineVerticalArray:_CTLineVerticalLayoutArray
                needShowMagnifyView:NO];
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
             allCTLineVerticalArray:_CTLineVerticalLayoutArray
                needShowMagnifyView:NO];
    self.magnifierView.hidden = YES;
    [self showMenuView];
}
- (void)copy:(nullable id)sender {
    if (_startCopyRunItem && _endCopyRunItem) {
        
        NSUInteger loc = _startCopyRunItem.characterRange.location;
        loc = loc<=0?0:loc;
        
        NSUInteger length = _endCopyRunItem.characterRange.location+_endCopyRunItem.characterRange.length - loc;
        
        if (length >= self.attributedText.string.length-loc) {
            length = self.attributedText.string.length-loc;
        }
        
        @autoreleasepool {
            NSRange rangeCopy = NSMakeRange(loc,length);
            NSString *str = [self.attributedText.string substringWithRange:rangeCopy];
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = str;
        }
    }
    [self hideView];
}

- (void)showMenuView {
    if (self.magnifierView.hidden && !self.textRangeView.hidden) {
        [self becomeFirstResponder];
        CGRect rect = CGRectMake((self.bounds.origin.x - (_lineVerticalMaxWidth/2 - _startCopyRunItem.withOutMergeBounds.origin.x)),
                                 _startCopyRunItemY-5,
                                 _lineVerticalMaxWidth,
                                 _endCopyRunItem.withOutMergeBounds.origin.y + _endCopyRunItem.withOutMergeBounds.size.height + 16);
        [[UIMenuController sharedMenuController] setTargetRect:rect inView:self];
        [[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
    }
}

- (void)scrollViewUnable:(BOOL)unable {
    if (unable) {
        for (NSDictionary *viewDic in self.scrlooViewArray) {
            UIScrollView *view = viewDic[@"ScrollView"];
            view.delaysContentTouches = [viewDic[@"delaysContentTouches"] boolValue];
            view.canCancelContentTouches = [viewDic[@"canCancelContentTouches"] boolValue];
        }
        [self.scrlooViewArray removeAllObjects];
    }
    else{
        [self.scrlooViewArray removeAllObjects];
        [self setScrollView:self.superview scrollUnable:NO];
    }
}

- (void)setScrollView:(UIView *)view scrollUnable:(BOOL)unable {    
    if (view.superview) {
        if ([view.superview isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)view.superview;
            [self.scrlooViewArray addObject:@{@"ScrollView":scrollView,
                                              @"delaysContentTouches":@(scrollView.delaysContentTouches),
                                              @"canCancelContentTouches":@(scrollView.canCancelContentTouches)
                                              }];
            scrollView.delaysContentTouches = NO;
            scrollView.canCancelContentTouches = NO;
        }
        [self setScrollView:view.superview scrollUnable:unable];
    }else{
        return;
    }
}


#pragma mark - 显示放大镜
- (void)showMagnifyInCJLabel:(CJLabel *)label
                magnifyPoint:(CGPoint)point
                     runItem:(CJGlyphRunStrokeItem *)runItem
{
    self.label = label;
    self.attributedText = label.attributedText;
    self.font = label.font;
    CGRect labelFrame = label.bounds;
    self.frame = labelFrame;
    [label addSubview:self];
    [label bringSubviewToFront:self];
    self.magnifierView.hidden = NO;
    [CJkeyWindow() addSubview:self.magnifierView];
    [self updateMagnifyPoint:point item:runItem];
}
#pragma mark - 显示选择视图
- (void)showSelectViewInCJLabel:(CJLabel *)label
                        atPoint:(CGPoint)point
                        runItem:(CJGlyphRunStrokeItem *)item
                   maxLineWidth:(CGFloat)maxLineWidth
         allCTLineVerticalArray:(NSArray *)allCTLineVerticalArray
                allRunItemArray:(NSArray <CJGlyphRunStrokeItem *>*)allRunItemArray
                  hideViewBlock:(void(^)(void))hideViewBlock
{
    if (_startCopyRunItem && CGRectEqualToRect(_startCopyRunItem.withOutMergeBounds, item.withOutMergeBounds) ) {
        return;
    }
    [self hideView];
    self.label = label;
    self.attributedText = label.attributedText;
    self.font = label.font;
    CGRect labelFrame = label.bounds;
    self.frame = labelFrame;
    _lineVerticalMaxWidth = maxLineWidth;
    _CTLineVerticalLayoutArray = allCTLineVerticalArray;
    _allRunItemArray = allRunItemArray;
    _firstRunItem = [[allRunItemArray firstObject] copy];
    _lastRunItem = [[allRunItemArray lastObject] copy];
    
    _startCopyRunItem = [item copy];
    _endCopyRunItem = _startCopyRunItem;
    [self showCJSelectViewWithPoint:point selectType:ShowAllSelectView item:_startCopyRunItem startCopyRunItem:_startCopyRunItem endCopyRunItem:_startCopyRunItem allCTLineVerticalArray:_CTLineVerticalLayoutArray needShowMagnifyView:NO];
    
    CGRect windowFrame = [label.superview convertRect:self.label.frame toView:CJkeyWindow()];
    self.backWindView.frame = windowFrame;
    self.backWindView.hidden = NO;
    [CJkeyWindow() addSubview:self.backWindView];
    
    [label addSubview:self];
    [label bringSubviewToFront:self];
    [CJkeyWindow() addSubview:self.magnifierView];
    [self showMenuView];
    [self scrollViewUnable:NO];
    self.hideViewBlock = hideViewBlock;
}
#pragma mark - 隐藏选择视图
- (void)hideView {
    self.attributedText = nil;
    self.font = nil;
    _lineVerticalMaxWidth = 0;
    _CTLineVerticalLayoutArray = nil;
    _allRunItemArray = nil;
    _firstRunItem = nil;
    _lastRunItem = nil;
    _startCopyRunItem = nil;
    _endCopyRunItem = nil;
    [self scrollViewUnable:YES];
    [self hideAllCopySelectView];
    if (self.hideViewBlock) {
        self.hideViewBlock();
    }
    self.hideViewBlock = nil;
}

/**
 隐藏所有与选择复制相关的视图
 */
- (void)hideAllCopySelectView {
    _startCopyRunItem = nil;
    _endCopyRunItem = nil;
    self.textRangeView.hidden = YES;
    self.magnifierView.hidden = YES;
    [self.magnifierView removeFromSuperview];
    self.backWindView.hidden = YES;
    [self.backWindView removeFromSuperview];
    [self resignFirstResponder];
    [self removeFromSuperview];
    [[UIMenuController sharedMenuController] setMenuVisible:NO];
}


- (void)showCJSelectViewWithPoint:(CGPoint)point
                       selectType:(CJSelectViewAction)type
                             item:(CJGlyphRunStrokeItem *)item
                 startCopyRunItem:(CJGlyphRunStrokeItem *)startCopyRunItem
                   endCopyRunItem:(CJGlyphRunStrokeItem *)endCopyRunItem
           allCTLineVerticalArray:(NSArray *)allCTLineVerticalArray
              needShowMagnifyView:(BOOL)needShowMagnifyView
{
    //隐藏“选择、全选、复制”菜单
    [[UIMenuController sharedMenuController] setMenuVisible:NO];
    //选中部分填充背景色
    [self updateSelectTextRangeViewStartCopyRunItem:startCopyRunItem endCopyRunItem:endCopyRunItem allCTLineVerticalArray:allCTLineVerticalArray];
    
    if (needShowMagnifyView) {
        //更新放大镜的位置
        [self updateMagnifyPoint:point item:item];
    }
}

//更新放大镜的位置
- (void)updateMagnifyPoint:(CGPoint)point item:(CJGlyphRunStrokeItem *)item {
    if (item) {
        
        CJCTLineVerticalLayout lineVerticalLayout = item.lineVerticalLayout;
        
        CGFloat selectPointY = item.locBounds.origin.y - 20;
        CGFloat pointToMagnifyY = item.locBounds.origin.y + item.locBounds.size.height/2;
        
        if (lineVerticalLayout.maxImageHeight != 0) {
            CJCTLineLayoutModel *lineLayoutModel = _CTLineVerticalLayoutArray[item.lineVerticalLayout.line];
            if (lineVerticalLayout.verticalAlignment == CJVerticalAlignmentTop) {
                pointToMagnifyY = lineLayoutModel.selectCopyBackY + item.locBounds.size.height/2;
            }
            else if (lineVerticalLayout.verticalAlignment == CJVerticalAlignmentCenter) {
                pointToMagnifyY = lineLayoutModel.selectCopyBackY + (lineLayoutModel.selectCopyBackHeight - item.locBounds.size.height)/2 + item.locBounds.size.height/2;
            }
            else if (lineVerticalLayout.verticalAlignment == CJVerticalAlignmentBottom) {
                pointToMagnifyY = lineLayoutModel.selectCopyBackY + (lineLayoutModel.selectCopyBackHeight - item.locBounds.size.height) + item.locBounds.size.height/2;
            }
            selectPointY = pointToMagnifyY - 20;
        }
        
        // Y 值往上偏移20 像素
        CGPoint selectPoint = CGPointMake(point.x, selectPointY);
        CGPoint pointToMagnify = CGPointMake(point.x, pointToMagnifyY);
        selectPoint = [self convertPoint:selectPoint toView:CJkeyWindow()];
        pointToMagnify = [self convertPoint:pointToMagnify toView:CJkeyWindow()];
        self.magnifierView.hidden = NO;
        [self.magnifierView updateMagnifyPoint:pointToMagnify showMagnifyViewIn:selectPoint];
    }
    else {
        // Y 值往上偏移20 像素
        CGPoint selectPoint = CGPointMake(point.x, point.y-20);
        CGPoint pointToMagnify = CGPointMake(point.x, point.y);
        selectPoint = [self convertPoint:selectPoint toView:CJkeyWindow()];
        pointToMagnify = [self convertPoint:pointToMagnify toView:CJkeyWindow()];
        self.magnifierView.hidden = NO;
        [self.magnifierView updateMagnifyPoint:pointToMagnify showMagnifyViewIn:selectPoint];
    }
    

}

/**
 更新选中复制的背景填充色
 */
- (void)updateSelectTextRangeViewStartCopyRunItem:(CJGlyphRunStrokeItem *)startCopyRunItem
                                   endCopyRunItem:(CJGlyphRunStrokeItem *)endCopyRunItem
                           allCTLineVerticalArray:(NSArray *)allCTLineVerticalArray
{
    
    CGRect frame = self.bounds;
    CGRect headRect = CGRectNull;
    CGRect middleRect = CGRectNull;
    CGRect tailRect = CGRectNull;
    
    CJCTLineLayoutModel *lineLayoutModel = nil;
    
    CGFloat maxWidth = _lineVerticalMaxWidth;
    
    //headRect 坐标
    lineLayoutModel = allCTLineVerticalArray[startCopyRunItem.lineVerticalLayout.line];
    _startCopyRunItemY = lineLayoutModel.selectCopyBackY;
    CGFloat headWidth = maxWidth - startCopyRunItem.withOutMergeBounds.origin.x;
    CGFloat headHeight = lineLayoutModel.selectCopyBackHeight;
    headRect = CGRectMake(startCopyRunItem.withOutMergeBounds.origin.x, _startCopyRunItemY, headWidth, headHeight);
    
    //tailRect 坐标
    lineLayoutModel = allCTLineVerticalArray[endCopyRunItem.lineVerticalLayout.line];
    CGFloat tailWidth = endCopyRunItem.withOutMergeBounds.origin.x+endCopyRunItem.withOutMergeBounds.size.width;
    CGFloat tailHeight = lineLayoutModel.selectCopyBackHeight;
    CGFloat tailY = lineLayoutModel.selectCopyBackY;
    if (endCopyRunItem.lineVerticalLayout.line - 1 >= 0) {
        CJCTLineLayoutModel *endLastlineLayoutModel = allCTLineVerticalArray[endCopyRunItem.lineVerticalLayout.line-1];
        tailY = endLastlineLayoutModel.selectCopyBackY + endLastlineLayoutModel.selectCopyBackHeight;
        tailHeight = tailHeight + lineLayoutModel.selectCopyBackY - tailY;
    }
    tailRect = CGRectMake(0, tailY, tailWidth, tailHeight);
    
    CGFloat maxHeight = tailY + tailHeight - _startCopyRunItemY;
    
    BOOL differentLine = YES;
    if (startCopyRunItem.lineVerticalLayout.line == endCopyRunItem.lineVerticalLayout.line) {
        differentLine = NO;
        headRect = CGRectNull;
        middleRect = CGRectMake(startCopyRunItem.withOutMergeBounds.origin.x,
                                _startCopyRunItemY,
                                endCopyRunItem.withOutMergeBounds.origin.x+endCopyRunItem.withOutMergeBounds.size.width-startCopyRunItem.withOutMergeBounds.origin.x,
                                headHeight);
        tailRect = CGRectNull;
    }else{
        //相差一行
        if (startCopyRunItem.lineVerticalLayout.line + 1 == endCopyRunItem.lineVerticalLayout.line) {
            middleRect = CGRectNull;
        }else{
            middleRect = CGRectMake(0, _startCopyRunItemY+headHeight, maxWidth, maxHeight-headHeight-tailHeight);
        }
    }
    
    [self.textRangeView updateFrame:frame headRect:headRect middleRect:middleRect tailRect:tailRect differentLine:differentLine];
    
    self.textRangeView.hidden = NO;
    [self bringSubviewToFront:self.textRangeView];
}

- (CJSelectViewAction)choseSelectView:(CGPoint)point {
    if (self.textRangeView.hidden) {
        return ShowAllSelectView;
    }
    
    
    CJCTLineLayoutModel *lineLayoutModel = nil;
    
    //headRect 坐标
    lineLayoutModel = _CTLineVerticalLayoutArray[_startCopyRunItem.lineVerticalLayout.line];
    _startCopyRunItemY = lineLayoutModel.selectCopyBackY;
    CGFloat headHeight = lineLayoutModel.selectCopyBackHeight;
    CGRect leftRect = CGRectMake(_startCopyRunItem.withOutMergeBounds.origin.x-5, _startCopyRunItemY-10, 10, headHeight+30);
    
    
    //rightRect 坐标
    lineLayoutModel = _CTLineVerticalLayoutArray[_endCopyRunItem.lineVerticalLayout.line];
    CGFloat tailWidth = _endCopyRunItem.withOutMergeBounds.origin.x+_endCopyRunItem.withOutMergeBounds.size.width;
    CGFloat tailHeight = lineLayoutModel.selectCopyBackHeight;
    CGFloat tailY = lineLayoutModel.selectCopyBackY;
    CGRect rightRect = CGRectMake(tailWidth-5, tailY, 10, tailHeight+20);
    
    CJSelectViewAction selectView = [self choseSelectView:point inset:1 leftRect:leftRect rightRect:rightRect time:0];
    return selectView;
}

- (CJSelectViewAction)choseSelectView:(CGPoint)point inset:(CGFloat)inset leftRect:(CGRect)leftRect rightRect:(CGRect)rightRect time:(NSInteger)time {
    CJSelectViewAction selectView = ShowAllSelectView;
    if (time > 15) {
        //超过15次还判断不到，那就退出
        return selectView;
    }
    time ++;
    
    BOOL inLeftView = CGRectContainsPoint(CGRectInset(leftRect, inset, inset), point);
    BOOL inRightView = CGRectContainsPoint(CGRectInset(rightRect, inset, inset), point);
    
    if (!inLeftView && !inRightView) {
        //加大点击区域判断
        return [self choseSelectView:point inset:inset+(-0.35) leftRect:leftRect rightRect:rightRect time:time];
    }
    else if (inLeftView && !inRightView) {
        selectView = MoveLeftSelectView;
        return selectView;
    }
    else if (!inLeftView && inRightView) {
        selectView = MoveRightSelectView;
        return selectView;
    }
    else if (inLeftView && inRightView) {
        //缩小点击区域判断
        return [self choseSelectView:point inset:inset+(0.25) leftRect:leftRect rightRect:rightRect time:time];
    }else{
        return selectView;
    }
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
    if (gestureRecognizer == self.doubleTapGes) {
        objc_setAssociatedObject(self.doubleTapGes, &kAssociatedUITouchKey, touch, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    else if (gestureRecognizer == self.longPressGestureRecognizer) {
        objc_setAssociatedObject(self.longPressGestureRecognizer, &kAssociatedUITouchKey, touch, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return YES;
}

- (void)tapOneAct:(UITapGestureRecognizer *)sender {
    if (!_haveMove) {
        [self hideView];
    }
}

- (void)tapTwoAct:(UITapGestureRecognizer *)sender {
    UITouch *touch = objc_getAssociatedObject(self.doubleTapGes, &kAssociatedUITouchKey);
    CGPoint point = [touch locationInView:self];
    CJGlyphRunStrokeItem *currentItem = [CJSelectCopyManagerView currentItem:point allRunItemArray:_allRunItemArray inset:1];
    if (currentItem) {
        _startCopyRunItem = currentItem;
        _endCopyRunItem = currentItem;
        [self showCJSelectViewWithPoint:point selectType:ShowAllSelectView item:currentItem startCopyRunItem:currentItem endCopyRunItem:currentItem allCTLineVerticalArray:_CTLineVerticalLayoutArray needShowMagnifyView:NO];
        [self showMenuView];
    }
}

#pragma mark - UILongPressGestureRecognizer
- (void)longPressGestureDidFire:(UILongPressGestureRecognizer *)sender {
    
    UITouch *touch = objc_getAssociatedObject(self.longPressGestureRecognizer, &kAssociatedUITouchKey);
    CGPoint point = [touch locationInView:self];
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            //发生长按，显示放大镜
            CJGlyphRunStrokeItem *currentItem = [CJSelectCopyManagerView currentItem:point allRunItemArray:_allRunItemArray inset:0.5];
            if (currentItem) {
                //隐藏“选择、全选、复制”菜单
                [[UIMenuController sharedMenuController] setMenuVisible:NO];
                [self updateMagnifyPoint:point item:currentItem];
            }
            break;
        }
        case UIGestureRecognizerStateEnded:{
            self.magnifierView.hidden = YES;
            CJGlyphRunStrokeItem *currentItem = [CJSelectCopyManagerView currentItem:point allRunItemArray:_allRunItemArray inset:1.5];
            if (currentItem) {
                _startCopyRunItem = currentItem;
                _endCopyRunItem = currentItem;
                [self showCJSelectViewWithPoint:point selectType:ShowAllSelectView item:currentItem startCopyRunItem:currentItem endCopyRunItem:currentItem allCTLineVerticalArray:_CTLineVerticalLayoutArray needShowMagnifyView:NO];
                [self showMenuView];
            }
            break;
        }
        case UIGestureRecognizerStateChanged:{
            //长按位置改变，显示放大镜
            CJGlyphRunStrokeItem *currentItem = [CJSelectCopyManagerView currentItem:point allRunItemArray:_allRunItemArray inset:0.5];
            if (currentItem) {
                //隐藏“选择、全选、复制”菜单
                [[UIMenuController sharedMenuController] setMenuVisible:NO];
                [self updateMagnifyPoint:point item:currentItem];
            }
        }
        default:
            break;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    _haveMove = NO;
    CGPoint point = [[touches anyObject] locationInView:self];
    //复制选择正在移动的大头针
    self.selectViewAction = [self choseSelectView:point];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.magnifierView.hidden = YES;
    if (!self.textRangeView.hidden) {
        [self showMenuView];
    }
    _haveMove = NO;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    self.magnifierView.hidden = YES;
    if (!self.textRangeView.hidden) {
        [self showMenuView];
    }
    _haveMove = NO;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self becomeFirstResponder];
    _haveMove = YES;
    CGPoint point = [[touches anyObject] locationInView:self];
    
    CJGlyphRunStrokeItem *currentItem = nil;
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
        currentItem = [CJSelectCopyManagerView currentItem:point allRunItemArray:_allRunItemArray inset:0.5];
    }
    
    if (currentItem && self.selectViewAction != ShowAllSelectView) {
        CGPoint selectPoint = CGPointMake(point.x, (currentItem.lineVerticalLayout.lineRect.size.height/2)+currentItem.lineVerticalLayout.lineRect.origin.y);
        if (self.selectViewAction == MoveLeftSelectView) {
            if (currentItem.characterIndex < _endCopyRunItem.characterIndex) {
                _startCopyRunItem = currentItem;
                [self showCJSelectViewWithPoint:selectPoint
                                     selectType:MoveLeftSelectView
                                           item:currentItem
                               startCopyRunItem:_startCopyRunItem
                                 endCopyRunItem:_endCopyRunItem
                         allCTLineVerticalArray:_CTLineVerticalLayoutArray
                            needShowMagnifyView:YES];
            }
            else if (currentItem.characterIndex == _endCopyRunItem.characterIndex){
                _startCopyRunItem = [currentItem copy];
                _endCopyRunItem = _startCopyRunItem;
                [self showCJSelectViewWithPoint:selectPoint
                                     selectType:ShowAllSelectView
                                           item:_startCopyRunItem
                               startCopyRunItem:_startCopyRunItem
                                 endCopyRunItem:_endCopyRunItem
                         allCTLineVerticalArray:_CTLineVerticalLayoutArray
                            needShowMagnifyView:YES];
            }
        }
        else if (self.selectViewAction == MoveRightSelectView) {
            if (currentItem.characterIndex > _startCopyRunItem.characterIndex) {
                _endCopyRunItem = [currentItem copy];
                [self showCJSelectViewWithPoint:selectPoint
                                     selectType:MoveRightSelectView
                                           item:currentItem
                               startCopyRunItem:_startCopyRunItem
                                 endCopyRunItem:_endCopyRunItem
                         allCTLineVerticalArray:_CTLineVerticalLayoutArray
                            needShowMagnifyView:YES];
            }
            else if (currentItem.characterIndex == _startCopyRunItem.characterIndex){
                _startCopyRunItem = [currentItem copy];
                _endCopyRunItem = _startCopyRunItem;
                [self showCJSelectViewWithPoint:selectPoint
                                     selectType:ShowAllSelectView
                                           item:_startCopyRunItem
                               startCopyRunItem:_startCopyRunItem
                                 endCopyRunItem:_endCopyRunItem
                         allCTLineVerticalArray:_CTLineVerticalLayoutArray
                            needShowMagnifyView:YES];
            }
        }
    }
}

+ (CJGlyphRunStrokeItem *)currentItem:(CGPoint)point allRunItemArray:(NSArray <CJGlyphRunStrokeItem *>*)allRunItemArray inset:(CGFloat)inset {
    __block CJGlyphRunStrokeItem *currentItem = nil;
    [allRunItemArray enumerateObjectsUsingBlock:^(CJGlyphRunStrokeItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (CGRectContainsPoint(CGRectInset(obj.withOutMergeBounds, -inset, -inset), point)) {
            currentItem = [obj copy];
            *stop = YES;
        }
    }];
    return currentItem;
}
@end



