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
    
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0, 1);
    
    NSDictionary *dic = @{
                          NSFontAttributeName:[UIFont systemFontOfSize:20],/*(字体)*/
//                          NSFontAttributeName:[UIFont fontWithName:@"Arial-BoldItalicMT" size:30.0],/*(字体)*/
//                          NSBackgroundColorAttributeName:[UIColor grayColor],/*(字体背景色)*/
//                          NSForegroundColorAttributeName:[UIColor blackColor],/*(字体颜色)*/
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
    NSMutableAttributedString *labelTitle = [NSString getNSAttributedString:@"点击了链接#http://www.lcj.com#属性文本键2啊啊生生世世生生世世很过分的a" labelDict:dic];
    
    //设置点击link属性
    NSAttributedString *link1 = [NSString getNSAttributedString:@"http://www.lcj.com" labelDict:dic];
    
    //设置点击link属性
    NSAttributedString *link2 = [NSString getNSAttributedString:@"生生世世生生世世很过分" labelDict:dic];
    
    [labelTitle addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.9873 green:0.1617 blue:0.1402 alpha:1.0] range:[[labelTitle string] rangeOfString:[link1 string]]];
    [labelTitle addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:[[labelTitle string] rangeOfString:[link1 string]]];
    
    [labelTitle addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.2758 green:0.2585 blue:0.9705 alpha:1.0] range:[[labelTitle string] rangeOfString:[link2 string]]];
    [labelTitle addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:[[labelTitle string] rangeOfString:[link2 string]]];
    
    self.label.attributedText = labelTitle;
//    self.label.extendsLinkTouchArea = YES;
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
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
