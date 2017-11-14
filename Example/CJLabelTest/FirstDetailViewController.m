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
@property (nonatomic, strong) NSAttributedString *attStr;
@end

@implementation FirstDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.label = [[CJLabel alloc]initWithFrame:CGRectMake(10, 10, ScreenWidth - 20, ScreenHeight - 64 - 150)];
    self.label.backgroundColor = UIColorFromRGB(0XE3F6FF);
    self.label.numberOfLines = 0;
    [self.view addSubview:self.label];
    
    [self handleContent:self.content];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handleContent:(NSMutableAttributedString *)content {
    
    NSMutableAttributedString *attStr = content;
    
    CJLabelConfigure *configure = [CJLabel configureAttributes:nil isLink:NO activeLinkAttributes:nil parameter:nil clickLinkBlock:nil longPressBlock:nil];
    configure.isLink = NO;
    
    attStr = [CJLabel configureAttrString:attStr withString:@"CJLabel" sameStringEnable:YES configure:configure];
    self.attStr = attStr;
    
    switch (self.index) {
        case 1:
            self.navigationItem.title = @"垂直对齐";
            //设置垂直对齐方式
            self.label.verticalAlignment = CJVerticalAlignmentCenter;
            self.label.text = self.attStr;
            //支持选择复制
            self.label.enableCopy = YES;
            [self rightBarButtonItems];
            break;
        case 3:
        {
            self.navigationItem.title = @"添加不同链点";
            self.label.verticalAlignment = CJVerticalAlignmentBottom;
            
            NSArray *linkRangeArray = [CJLabel sameLinkStringRangeArray:@"CJLabel" inAttString:attStr];
            //第一个链点
            NSRange linkRange = NSRangeFromString(linkRangeArray[0]);
            configure.attributes = @{
                                     NSForegroundColorAttributeName:[UIColor blueColor],
                                     NSFontAttributeName:[UIFont boldSystemFontOfSize:15],
                                     kCJBackgroundStrokeColorAttributeName:[UIColor orangeColor],
                                     kCJBackgroundFillColorAttributeName:[UIColor lightGrayColor]
                                     };
            configure.activeLinkAttributes = @{
                                               NSForegroundColorAttributeName:[UIColor redColor],
                                               kCJActiveBackgroundStrokeColorAttributeName:[UIColor redColor],
                                               kCJActiveBackgroundFillColorAttributeName:UIRGBColor(247,231,121,1)
                                               };
            configure.isLink = YES;
            configure.clickLinkBlock = ^(CJLabelLinkModel *linkModel) {
                [self clickLink:linkModel];
            };
            configure.longPressBlock = ^(CJLabelLinkModel *linkModel) {
                [self clicklongPressLink:linkModel];
            };
            configure.parameter = @"第1个点击链点";
            attStr = [CJLabel configureAttrString:attStr atRange:linkRange configure:configure];
            
            //第二个点击链点
            linkRange = NSRangeFromString(linkRangeArray[1]);
            configure.longPressBlock = nil;
            configure.parameter = @"第2个点击链点";
            attStr = [CJLabel configureAttrString:attStr atRange:linkRange configure:configure];
            
            //第三个点击链点
            linkRange = NSRangeFromString(linkRangeArray[2]);
            configure.attributes = @{NSForegroundColorAttributeName:[UIColor redColor],
                                     NSFontAttributeName:[UIFont systemFontOfSize:15],
                                     kCJBackgroundStrokeColorAttributeName:[UIColor redColor],
                                     kCJBackgroundFillColorAttributeName:[UIColor colorWithWhite:0.7 alpha:0.7]
                                     };
            configure.activeLinkAttributes = @{NSForegroundColorAttributeName:[UIColor darkTextColor],
                                               kCJActiveBackgroundStrokeColorAttributeName:[UIColor darkTextColor],
                                               kCJActiveBackgroundFillColorAttributeName:[UIColor lightGrayColor]
                                               };
            configure.clickLinkBlock = nil;
            configure.parameter = @"第3个点击链点";
            configure.longPressBlock = ^(CJLabelLinkModel *linkModel) {
                [self clicklongPressLink:linkModel];
            };
            attStr = [CJLabel configureAttrString:attStr atRange:linkRange configure:configure];
            
            self.label.attributedText = attStr;
        }
            break;
        default:
            break;
    }
    
}

- (void)rightBarButtonItems {
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc]initWithTitle:@"居上" style:UIBarButtonItemStylePlain target:self action:@selector(itemClick:)];
    item1.tag = 100;
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc]initWithTitle:@"居中" style:UIBarButtonItemStylePlain target:self action:@selector(itemClick:)];
    item2.tag = 200;
    UIBarButtonItem *item3 = [[UIBarButtonItem alloc]initWithTitle:@"居下" style:UIBarButtonItemStylePlain target:self action:@selector(itemClick:)];
    item3.tag = 300;
    self.navigationItem.rightBarButtonItems = @[item3,item2,item1];
}

- (void)itemClick:(UIBarButtonItem *)item {
    
    if (item.tag == 100) {
        self.label.verticalAlignment = CJVerticalAlignmentTop;
    }else if (item.tag == 200) {
        self.label.verticalAlignment = CJVerticalAlignmentCenter;
    }else if (item.tag == 300) {
        self.label.verticalAlignment = CJVerticalAlignmentBottom;
    }
    
}

- (void)clickLink:(CJLabelLinkModel *)linkModel {
    NSString *title = [NSString stringWithFormat:@"点击链点 %@",linkModel.attributedString.string];
    NSString *parameter = [NSString stringWithFormat:@"自定义参数：%@",linkModel.parameter];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:parameter preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)clicklongPressLink:(CJLabelLinkModel *)linkModel {
    NSString *title = [NSString stringWithFormat:@"长按点击: %@",linkModel.parameter];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
