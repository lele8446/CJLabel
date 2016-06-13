//
//  ViewController.m
//  CJLabelTest
//
//  Created by C.K.Lian on 15/12/11.
//  Copyright © 2015年 C.K.Lian. All rights reserved.
//

#import "ViewController.h"
#import "NSString+CJString.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = NSTextAlignmentLeft;
    paragraph.lineSpacing = 1.2;
//    paragraph.lineHeightMultiple = 1.1;//行间距是多少倍
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0, 1);
    
    NSDictionary *dic = @{
                          NSFontAttributeName:[UIFont systemFontOfSize:20],/*(字体)*/
//                          NSFontAttributeName:[UIFont fontWithName:@"Arial-BoldItalicMT" size:30.0],/*(字体)*/
//                          NSBackgroundColorAttributeName:[UIColor grayColor],/*(字体背景色)*/
//                          NSForegroundColorAttributeName:[UIColor blackColor],/*(字体颜色)*/
                          NSParagraphStyleAttributeName:paragraph,/*(段落)*/
//                          NSLigatureAttributeName:[NSNumber numberWithInt:1],/*(连字符)*/
//                          NSKernAttributeName:[NSNumber numberWithInt:0],/*(字间距)*/
//                          NSStrikethroughStyleAttributeName:@(NSUnderlinePatternSolid | NSUnderlineStyleSingle),/*(删除线)NSUnderlinePatternSolid(实线)*/
//                          NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle),/*(下划线)*/
//                          NSStrokeColorAttributeName:[UIColor redColor],/*(边线颜色)*/
//                          NSStrokeWidthAttributeName:@(0.5),/*(边线宽度)*/
//                          NSShadowAttributeName:shadow,/*(阴影)*/
//                          NSVerticalGlyphFormAttributeName:[NSNumber numberWithInt:0],/*(横竖排版)*/
                          };
    //设置label text
    NSMutableAttributedString *labelTitle = [NSString getNSAttributedString:@"Mac中有些View为了其实现的便捷将原点变换到左上角，像NSTableView的坐标系坐标原点就在左上角。iOS UIKit的UIView的坐标系原点在左上角。往底层看，，通过打印出来看到值为点击了链接#http://www.lcj.com#属性文的context使用的坐标系的原点是在左下角。而在iOS中的底层界面绘制就是通过Core Graphics进行的，那么坐标系列是如何变换的呢本键2啊啊生生世世生生世世很过分的a" labelDict:dic];
    
//    self.label.sameLinkEnable = NO;
    self.label.attributedText = labelTitle;
//    self.label.extendsLinkTouchArea = YES;
    
    NSDictionary *linkDic1 = @{
                               NSForegroundColorAttributeName:[UIColor colorWithRed:0.9873 green:0.1617 blue:0.1402 alpha:1.0],
                               NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)
                               };
    
    NSDictionary *linkDic2 = @{
                               NSForegroundColorAttributeName:[UIColor colorWithRed:0.2758 green:0.2585 blue:0.9705 alpha:1.0],
                               NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)
                               };
    
//    [self.label addLinkString:@"的" linkAddAttribute:linkDic1 block:^(CJLinkLabelModel *linkModel) {
//        NSLog(@"点击了链接: %@",linkModel.linkString);
//    }];
    
    [self.label addLinkString:@"的" linkAddAttribute:linkDic1 linkParameter:@{@"id":@"1",@"type":@"text"} block:^(CJLinkLabelModel *linkModel) {
        NSLog(@"点击了链接: %@",linkModel.parameter);
    }];
    
    [self.label addLinkString:@"点击了链接" linkAddAttribute:linkDic2 block:^(CJLinkLabelModel *linkModel) {
        NSLog(@"点击了链接: %@",linkModel.linkString);
    }];

    CGFloat width = [[UIScreen mainScreen] bounds].size.width-20;
    CGRect labelFrame = self.label.frame;
    
//    // TODO: 方法一
//    labelFrame.size = [NSString getStringRect:labelTitle width:width height:MAXFLOAT];
    
    // TODO: 方法二
    labelFrame.size = [NSString sizeLabelToFit:labelTitle width:width height:MAXFLOAT];
    
    self.label.frame = labelFrame;
    self.label.backgroundColor = [UIColor colorWithRed:0.8291 green:0.9203 blue:1.0 alpha:1.0];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
