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
#import "CJLabel+UIMenu.h"

@interface FirstDetailViewController ()
@property (nonatomic, strong) CJLabel *label;
@property (nonatomic, strong) NSAttributedString *attStr;
@end

@implementation FirstDetailViewController

- (void)dealloc {
    NSLog(@"%@ dealloc",NSStringFromClass([self class]));
}

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
    
    __weak typeof(self)wSelf = self;
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
            NSRange linkRange = [linkRangeArray[0] rangeValue];
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
                [wSelf clickLink:linkModel];
            };
            configure.longPressBlock = ^(CJLabelLinkModel *linkModel) {
                [wSelf clicklongPressLink:linkModel];
            };
            configure.parameter = @"第1个点击链点";
            attStr = [CJLabel configureAttrString:attStr atRange:linkRange configure:configure];
            
            //第二个点击链点
            linkRange = [linkRangeArray[1] rangeValue];
            configure.longPressBlock = nil;
            configure.parameter = @"第2个点击链点";
            attStr = [CJLabel configureAttrString:attStr atRange:linkRange configure:configure];
            
            //第三个点击链点
            linkRange = [linkRangeArray[2] rangeValue];
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
                [wSelf clicklongPressLink:linkModel];
            };
            attStr = [CJLabel configureAttrString:attStr atRange:linkRange configure:configure];
            
            self.label.attributedText = attStr;
            [self.label showSelectAllTextWithMenus:@[@"拷贝",@"翻译",@"搜一搜"] selectTextBackColor:[UIColor lightGrayColor] colorAlpha:0.35 clickMenuCompletion:^(NSString *menuTitle, CJLabel *label) {
                NSLog(@"点击 = %@",menuTitle);
            }];
            [CJLabel respondsToSelector:@selector(initWithView:viewSize:lineAlignment:configure:)];
            [CJLabel respondsToSelector:@selector(insertViewAtAttrString:view:viewSize:atIndex:lineAlignment:configure:)];
        }
            break;
        case 5:
        {
            self.navigationItem.title = @"自定义截断字符";
            self.label.numberOfLines = 3;
            
            //配置链点属性
            configure.isLink = YES;
            configure.clickLinkBlock = ^(CJLabelLinkModel *linkModel) {
                //点击 `……全文`
                [wSelf clickTruncationToken:linkModel];
            };
            configure.attributes = @{NSForegroundColorAttributeName:[UIColor blueColor],NSFontAttributeName:[UIFont systemFontOfSize:13]};
            
            //自定义截断字符为："……全文"
            NSAttributedString *truncationToken = [CJLabel initWithAttributedString:[[NSAttributedString alloc]initWithString:@"……全文"] strIdentifier:@"TruncationToken" configure:configure];
            //设置行尾截断
            self.label.lineBreakMode = NSLineBreakByTruncatingTail;
            self.label.attributedTruncationToken = truncationToken;
            //设置点击链点
            attStr = [CJLabel configureAttrString:attStr withAttributedString:truncationToken strIdentifier:@"TruncationToken" sameStringEnable:NO configure:configure];
            
            UIImageView *imgView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 100, 80)];
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1576752448623&di=42bd4f5d4a9f8f35eb8eade57484fde0&imgtype=0&src=http%3A%2F%2Faliyunzixunbucket.oss-cn-beijing.aliyuncs.com%2Fjpg%2Fb651212dd7b9019275ccc0266f7919ad.jpg%3Fx-oss-process%3Dimage%2Fresize%2Cp_100%2Fauto-orient%2C1%2Fquality%2Cq_90%2Fformat%2Cjpg%2Fwatermark%2Cimage_eXVuY2VzaGk%3D%2Ct_100"]];
            imgView.image = [UIImage imageWithData:data];
            attStr = [CJLabel insertViewAtAttrString:attStr view:imgView viewSize:CGSizeMake(100, 80) atIndex:attStr.length-12 lineAlignment:CJVerticalAlignmentBottom configure:nil];
            
            UISwitch *mySwitch = [[UISwitch alloc]initWithFrame:CGRectMake(40, 10, 50, 31)];
            mySwitch.on = YES;
            attStr = [CJLabel insertViewAtAttrString:attStr view:mySwitch viewSize:CGSizeMake(50, 31) atIndex:attStr.length-6 lineAlignment:CJVerticalAlignmentBottom configure:nil];
            
            self.label.attributedText = attStr;
            //支持选择复制
//            self.label.enableCopy = YES;
            CGFloat height = [CJLabel sizeWithAttributedString:attStr withConstraints:CGSizeMake(ScreenWidth-20, CGFLOAT_MAX) limitedToNumberOfLines:3].height;
            self.label.frame = CGRectMake(10, 10, ScreenWidth - 20, height);
        }
        default:
            break;
    }
}

- (void)clickTruncationToken:(CJLabelLinkModel *)linkModel {
    NSLog(@"点击了 `……全文`");
    [self truncationTokenRightBarButtonItem:YES];
    NSAttributedString *text = linkModel.label.attributedText;
    linkModel.label.numberOfLines = 0;
    CGFloat height = [CJLabel sizeWithAttributedString:text withConstraints:CGSizeMake(ScreenWidth-20, CGFLOAT_MAX) limitedToNumberOfLines:0].height;
    linkModel.label.frame = CGRectMake(10, 10, ScreenWidth - 20, height);
    [linkModel.label flushText];
}

- (void)truncationTokenRightBarButtonItem:(BOOL)show {
    if (show) {
        UIBarButtonItem *item = [[UIBarButtonItem alloc]initWithTitle:@"收起" style:UIBarButtonItemStylePlain target:self action:@selector(itemClick:)];
        item.tag = 400;
        self.navigationItem.rightBarButtonItem = item;
    }else{
        self.navigationItem.rightBarButtonItem = nil;
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
    }else if (item.tag == 400) {
        self.label.numberOfLines = 3;
        CGFloat height = [CJLabel sizeWithAttributedString:self.label.attributedText withConstraints:CGSizeMake(ScreenWidth-20, CGFLOAT_MAX) limitedToNumberOfLines:3].height;
        self.label.frame = CGRectMake(10, 10, ScreenWidth - 20, height);
        [self.label flushText];
        [self truncationTokenRightBarButtonItem:NO];
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
