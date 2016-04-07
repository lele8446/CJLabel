//
//  ViewController.m
//  CJLabelTest
//
//  Created by C.K.Lian on 15/12/11.
//  Copyright © 2015年 C.K.Lian. All rights reserved.
//

#import "ViewController.h"
#import "testView.h"
#import "NSString+CJString.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = NSTextAlignmentLeft;
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0, 1);
    
    NSDictionary *dic = @{
                          NSFontAttributeName:[UIFont systemFontOfSize:20],/*(字体)*/
//                          NSFontAttributeName:[UIFont fontWithName:@"Arial-BoldItalicMT" size:30.0],/*(字体)*/
//                          NSBackgroundColorAttributeName:[UIColor grayColor],/*(字体背景色)*/
                          NSForegroundColorAttributeName:[UIColor blackColor],/*(字体颜色)*/
//                          NSParagraphStyleAttributeName:paragraph,/*(段落)*/
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
    NSMutableAttributedString *labelTitle = [NSString getNSAttributedString:@"点击了手术室的大大的链接#http://www.lcj.com#属性文本键2啊啊生生世世很过分的a" labelDict:dic];
    
    //设置点击link属性
    NSAttributedString *link1 = [NSString getNSAttributedString:@"http://www.lcj.com" labelDict:dic];
    
    //设置点击link属性
    NSAttributedString *link2 = [NSString getNSAttributedString:@"生生世世很过分" labelDict:dic];
    
    [labelTitle addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.9873 green:0.1617 blue:0.1402 alpha:1.0] range:[[labelTitle string] rangeOfString:[link1 string]]];
    [labelTitle addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:[[labelTitle string] rangeOfString:[link1 string]]];
    
    [labelTitle addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.2758 green:0.2585 blue:0.9705 alpha:1.0] range:[[labelTitle string] rangeOfString:[link2 string]]];
    [labelTitle addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:[[labelTitle string] rangeOfString:[link2 string]]];
    
    self.label.attributedText = labelTitle;
    [self.label addLinkString:link1 block:^(CJLinkLabelModel *linkModel) {
        NSLog(@"点击了链接: %@",linkModel.linkString.string);
    }];
    
    [self.label addLinkString:link2 block:^(CJLinkLabelModel *linkModel) {
        NSLog(@"点击了链接: %@",linkModel.linkString.string);
    }];

    CGFloat width = [[UIScreen mainScreen] bounds].size.width-20;
    CGRect labelFrame = self.label.frame;
    labelFrame.size = [NSString getStringRect:labelTitle width:width height:MAXFLOAT];
    self.label.frame = labelFrame;
    self.label.backgroundColor = [UIColor colorWithRed:0.8291 green:0.9203 blue:1.0 alpha:1.0];
//    self.label.textAlignment = NSTextAlignmentRight;
    
    [NSString getAttributedStringHeightWithString:labelTitle width:width];
//
    //autolayout demo
//    testView *view = [[testView alloc]init];
//    view.frame = CGRectMake(0, 250, [UIScreen mainScreen].bounds.size.width, [view.label getStringRect:view.labelTitle width:[UIScreen mainScreen].bounds.size.width-40 height:MAXFLOAT labelFont:[UIFont systemFontOfSize:20]].height+20);
//    [self.view addSubview:view];
//    [self addTestLabel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addTestLabel {
    UILabel *label = [[UILabel alloc]init];
    label.backgroundColor = [UIColor colorWithRed:0.7652 green:1.0 blue:0.8742 alpha:1.0];
    label.numberOfLines = 0;
    [self.view addSubview:label];
    
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = NSTextAlignmentLeft;
    paragraph.lineSpacing = 10;
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0, 1);
    
    NSDictionary *dic = @{
                          NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue" size:12.0],/*(字体)*/
//                          NSFontAttributeName:[UIFont fontWithName:@"Arial-BoldItalicMT" size:14.0],/*(字体)*/
//                          NSBackgroundColorAttributeName:[UIColor grayColor],/*(字体背景色)*/
                          NSForegroundColorAttributeName:[UIColor redColor],/*(字体颜色)*/
//                          NSParagraphStyleAttributeName:paragraph,/*(段落)*/
//                          NSLigatureAttributeName:[NSNumber numberWithInt:1],/*(连字符)*/
//                          NSKernAttributeName:[NSNumber numberWithInt:0],/*(字间距)*/
//                          NSStrikethroughStyleAttributeName:@(NSUnderlinePatternSolid | NSUnderlineStyleSingle),/*(删除线)NSUnderlinePatternSolid(实线)*/
//                          NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle),/*(下划线)*/
//                          NSStrokeColorAttributeName:[UIColor redColor],/*(边线颜色)*/
//                          NSStrokeWidthAttributeName:@(0.5),/*(边线宽度)*/
//                          NSShadowAttributeName:shadow,/*(阴影)*/
//                          NSVerticalGlyphFormAttributeName:[NSNumber numberWithInt:0],/*(横竖排版)*/
                          };
    
    NSString *string = @"iOS 6：有些动作了：属性文本编辑被加入了UITextView。很不幸的是，它很难定制。默认的UI有粗体、斜体和下划线。用户可以设置字体大小和颜色。粗看起来相当不错，但还是没法控制布局或者提供一个便利的途径来定制文本属性。然而对于（文本编辑）开发者，有一个大的新功能：可以继承 UITextView 了，这样的话，除了以前版本提供的键盘输入外，开发者可以“免费”获得文本选择功能。必须实现一个完全自定义的文本选择功能，可能是很多对非纯文本工具开发的尝试半途而废的原因。（个人经历：我，WWDC，工程师们。我想要一个 iOS 的文本系统。回答：“嗯。吖。是的。也许？看，它只是不执行…” 所以毕竟还是有希望，对吧？）。";
    string = [string stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    NSAttributedString *text = [NSString getNSAttributedString:string labelDict:dic];
    label.attributedText = text;
    
    CGFloat width = [[UIScreen mainScreen] bounds].size.width-80;
    CGFloat height = [NSString sizeLabelToFit:text width:width height:MAXFLOAT].height;
    CGSize size = [NSString getStringRect:text width:width height:MAXFLOAT];
    
    label.frame = CGRectMake(40, 20, width,size.height);
    
    UILabel *label2 = [[UILabel alloc]init];
    label2.backgroundColor = [UIColor colorWithRed:1.0 green:0.9442 blue:0.7006 alpha:1.0];
    label2.numberOfLines = 0;
    label2.attributedText = text;
    label2.frame = CGRectMake(40, CGRectGetMaxY(label.frame)+10, width,height);
    [self.view addSubview:label2];
    
    

}

@end
