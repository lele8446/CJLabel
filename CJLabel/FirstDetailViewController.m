//
//  SecondDetailViewController.m
//  CJLabelTest
//
//  Created by ChiJinLian on 2017/11/9.
//  Copyright © 2017年 C.K.Lian. All rights reserved.
//

#import "FirstDetailViewController.h"
#import "Common.h"
#import "CJLabel.h"

@interface FirstDetailViewController ()
@property (nonatomic, strong) CJLabel *label;

@end

@implementation FirstDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.label = [[CJLabel alloc]initWithFrame:CGRectMake(10, 10, ScreenWidth - 20, ScreenHeight - 64 - 100)];
    self.label.backgroundColor = UIColorFromRGB(0xf0f0de);
    self.label.numberOfLines = 0;
    self.label.textInsets = UIEdgeInsetsMake(10, 15, 20, 0);
    self.label.verticalAlignment = CJVerticalAlignmentBottom;
    self.label.enableCopy = YES;
    self.label.enableCopy = NO;
    [self.view addSubview:self.label];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
