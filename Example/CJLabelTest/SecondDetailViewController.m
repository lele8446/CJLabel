//
//  DetailViewController.m
//  CJLabelTest
//
//  Created by ChiJinLian on 2017/4/28.
//  Copyright © 2017年 C.K.Lian. All rights reserved.
//

#import "SecondDetailViewController.h"
#import "CJLabel.h"
#import "Common.h"


@interface SecondDetailViewController ()
@property (nonatomic, weak) IBOutlet CJLabel *label;
@property (nonatomic, strong) CJLabel *secondLabel;
@property (nonatomic, strong) NSMutableAttributedString *attStr;
@property (nonatomic, strong) CJLabelConfigure *configure;

@property (nonatomic, weak) IBOutlet UILabel *label2;
@end

@implementation SecondDetailViewController

- (void)dealloc {
    NSLog(@"%@ dealloc",NSStringFromClass([self class]));
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.label.numberOfLines = 0;

    [self handleContent:self.content];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)handleContent:(NSMutableAttributedString *)content {
    NSMutableAttributedString *attStr = content;
    
    CJLabelConfigure *configure = [CJLabel configureAttributes:nil isLink:NO activeLinkAttributes:nil parameter:nil clickLinkBlock:nil longPressBlock:nil];
    
    switch (self.index) {
        case 0:
        {
            self.navigationItem.title = @"富文本展示";
            self.label.enableCopy = YES;
            //初始化配置
            CJLabelConfigure *configure = [CJLabel configureAttributes:nil isLink:NO activeLinkAttributes:nil parameter:nil clickLinkBlock:nil longPressBlock:nil];
            //设置 'CJLabel' 字符不可点击
            configure.isLink = NO;
            attStr = [CJLabel configureAttrString:attStr withString:@"CJLabel" sameStringEnable:YES configure:configure];
            //设置 `不同字体` 显示为粗体17的字号
            configure.attributes = @{NSFontAttributeName:[UIFont boldSystemFontOfSize:18]};
            attStr = [CJLabel configureAttrString:attStr withString:@"不同字体" sameStringEnable:NO configure:configure];
            //设置 `字体背景色` 填充背景色，以及填充区域圆角
            configure.attributes = @{kCJBackgroundFillColorAttributeName:[UIColor colorWithWhite:0.5 alpha:1],kCJBackgroundLineCornerRadiusAttributeName:@(0)};
            attStr = [CJLabel configureAttrString:attStr withString:@"字体背景色" sameStringEnable:NO configure:configure];
            //设置 `字体边框线` 边框线
            configure.attributes = @{kCJBackgroundStrokeColorAttributeName:[UIColor orangeColor]};
            attStr = [CJLabel configureAttrString:attStr withString:@"字体边框线" sameStringEnable:NO configure:configure];
            //指定文本添加删除线
            configure.attributes = @{kCJStrikethroughStyleAttributeName:@(1),
                                     kCJStrikethroughColorAttributeName:[UIColor redColor]};
            attStr = [CJLabel configureAttrString:attStr withString:@"对指定文本添加删除线" sameStringEnable:NO configure:configure];
            //指定位置插入图片
            NSRange imgRange = [attStr.string rangeOfString:@"插入图片"];
            [configure removeAttributesForKey:kCJBackgroundStrokeColorAttributeName];
            [configure removeAttributesForKey:kCJStrikethroughStyleAttributeName];
            [configure removeAttributesForKey:kCJStrikethroughColorAttributeName];

            attStr = [CJLabel insertViewAtAttrString:attStr view:@"CJLabel.png" viewSize:CGSizeMake(55, 45) atIndex:(imgRange.location+imgRange.length) lineAlignment:CJVerticalAlignmentBottom configure:configure];
            //设置内边距
            self.label.textInsets = UIEdgeInsetsMake(10, 10, 10, 0);
            self.label.attributedText = attStr;
            self.attStr = attStr;
        }
            break;
            
        case 2:
        {
            self.navigationItem.title = @"点击链点";
            UIBarButtonItem *item = [[UIBarButtonItem alloc]initWithTitle:@"删除链点" style:UIBarButtonItemStylePlain target:self action:@selector(itemClick:)];
            item.tag = 100;
            self.navigationItem.rightBarButtonItem = item;
            
            attStr = [self configureLabelContent:attStr configure:configure];
            self.label.attributedText = attStr;
            self.label.enableCopy = YES;
            self.attStr = attStr;
        }
            break;
            
        case 4:
        {
            self.navigationItem.title = @"图文混排";
            
            UIBarButtonItem *item = [[UIBarButtonItem alloc]initWithTitle:@"···" style:UIBarButtonItemStylePlain target:self action:@selector(itemClick:)];
            item.tag = 200;
            self.navigationItem.rightBarButtonItem = item;
            
            self.attStr = attStr;
            self.configure = configure;
            
            [self configureLabelContent:attStr verticalAlignment:CJVerticalAlignmentBottom configure:configure];
            self.label.enableCopy = YES;
            break;
        }
            
        case 6:
            {
                self.navigationItem.title = @"指定文字不换行";
                
                self.attStr = attStr;
                self.configure = configure;
                
                NSMutableAttributedString *resultStr = [[NSMutableAttributedString alloc]init];

                NSRange lastRange = NSMakeRange(0, 0);
                NSArray *ary = [CJLabel sameLinkStringRangeArray:@"#CJLabel#" inAttString:attStr];
                for (NSValue *value in ary) {
                    NSRange range = [value rangeValue];
                    
                    if (resultStr.length != range.location) {
                        NSInteger length = range.location - (lastRange.location+lastRange.length);
                        NSAttributedString *str = [attStr attributedSubstringFromRange:NSMakeRange(lastRange.location+lastRange.length, length)];
                        [resultStr appendAttributedString:str];
                        
                        configure.attributes = @{NSForegroundColorAttributeName:[UIColor blueColor],
                            NSFontAttributeName:[UIFont boldSystemFontOfSize:13]};
                        configure.activeLinkAttributes = @{NSForegroundColorAttributeName:[UIColor redColor],
                        NSFontAttributeName:[UIFont boldSystemFontOfSize:13]};
                        configure.isLink = YES;
                        NSAttributedString *label = [[NSAttributedString alloc]initWithString:@"#CJLabel#"];
                        NSMutableAttributedString *labelStr = [CJLabel initWithNonLineWrapAttributedString:label textInsets:UIEdgeInsetsZero configure:configure];
                        [resultStr appendAttributedString:labelStr];
                        lastRange = range;
                        
                    }
                }
                self.label.textInsets = UIEdgeInsetsMake(10, 10, 10, 10);
                self.label.enableCopy = YES;
                self.label.attributedText = resultStr;
                break;
            }
            
        default:
            break;
    }
}

- (NSMutableAttributedString *)configureLabelContent:(NSMutableAttributedString *)attStr configure:(CJLabelConfigure *)configure {
    
    __weak typeof(self)wSelf = self;
    //设置点击链点属性
    configure.attributes = @{
                             NSForegroundColorAttributeName:[UIColor blueColor],
                             NSFontAttributeName:[UIFont boldSystemFontOfSize:15],
                             kCJBackgroundStrokeColorAttributeName:[UIColor orangeColor],
                             kCJBackgroundLineWidthAttributeName:@(1),
                             kCJBackgroundFillColorAttributeName:[UIColor lightGrayColor]
                             };
    //设置点击高亮属性
    configure.activeLinkAttributes = @{
                                       NSForegroundColorAttributeName:[UIColor redColor],
                                       kCJActiveBackgroundStrokeColorAttributeName:[UIColor redColor],
                                       kCJActiveBackgroundFillColorAttributeName:UIRGBColor(247,231,121,1)
                                       };
    //链点自定义参数
    configure.parameter = @"参数为字符串";
    //点击回调
    configure.clickLinkBlock = ^(CJLabelLinkModel *linkModel) {
        [wSelf clickLink:linkModel isImage:NO];
    };
    //长按回调
    configure.longPressBlock = ^(CJLabelLinkModel *linkModel) {
        [wSelf clicklongPressLink:linkModel isImage:NO];
    };
    //设置为可点击链点
    configure.isLink = YES;
    
    NSAttributedString *link = [CJLabel initWithNSString:@"CJLabel" strIdentifier:@"aa" configure:configure];
    attStr = [CJLabel configureAttrString:attStr withAttributedString:link strIdentifier:@"aa" sameStringEnable:YES configure:configure];
    
    return attStr;
}

- (void)configureLabelContent:(NSMutableAttributedString *)attStr verticalAlignment:(CJLabelVerticalAlignment)verticalAlignment configure:(CJLabelConfigure *)configure {
    
    __weak typeof(self)wSelf = self;
    attStr = [self configureLabelContent:attStr configure:configure];
    
    //设置图片点击链点属性
    NSRange imageRange = [attStr.string rangeOfString:@"图片"];
    CJLabelConfigure *imgConfigure =
    [CJLabel configureAttributes:@{kCJBackgroundStrokeColorAttributeName:[UIColor redColor],
                                   kCJBackgroundLineWidthAttributeName:@(1),
                                   kCJBackgroundLineCornerRadiusAttributeName:@(2)}
                          isLink:YES
            activeLinkAttributes:@{kCJActiveBackgroundStrokeColorAttributeName:[UIColor lightGrayColor]}
                       parameter:@"图片参数"
                  clickLinkBlock:^(CJLabelLinkModel *linkModel){
                      [wSelf clickLink:linkModel isImage:YES];
                  }
                  longPressBlock:^(CJLabelLinkModel *linkModel){
                      [wSelf clicklongPressLink:linkModel isImage:YES];
                  }];
    
    UIImageView *imgView = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"CJLabel.png"]];
    imgView.contentMode = UIViewContentModeScaleToFill;
    imgView.clipsToBounds = YES;
    attStr = [CJLabel insertViewAtAttrString:attStr view:imgView viewSize:CGSizeMake(100, 40) atIndex:(imageRange.location+imageRange.length) lineAlignment:verticalAlignment configure:imgConfigure];
    
//    attStr = [CJLabel insertImageAtAttrString:attStr image:@"CJLabel.png" imageSize:CGSizeMake(45, 35) atIndex:(imageRange.location+imageRange.length) imagelineAlignment:verticalAlignment configure:imgConfigure];
    
    self.label.attributedText = attStr;
}

- (void)itemClick:(UIBarButtonItem *)item {
    if (item.tag == 100) {
        //移除指定链点
        NSArray *linkRangeArray = [CJLabel sameLinkStringRangeArray:@"CJLabel" inAttString:self.attStr];
        [self.label removeLinkAtRange:[linkRangeArray[0] rangeValue]];
        item.enabled = NO;
    }
    else if (item.tag == 200) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"图片所在行垂直对齐方式" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"顶部对齐" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self configureLabelContent:self.attStr verticalAlignment:CJVerticalAlignmentTop configure:self.configure];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"居中对齐" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self configureLabelContent:self.attStr verticalAlignment:CJVerticalAlignmentCenter configure:self.configure];
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"底部对齐" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self configureLabelContent:self.attStr verticalAlignment:CJVerticalAlignmentBottom configure:self.configure];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)clickLink:(CJLabelLinkModel *)linkModel isImage:(BOOL)isImage {
    NSString *title = [NSString stringWithFormat:@"点击链点 %@",linkModel.attributedString.string];
    if (isImage) {
         title = [NSString stringWithFormat:@"点击链点图片：%@",linkModel.insertView];
    }
    NSString *parameter = [NSString stringWithFormat:@"自定义参数：%@",linkModel.parameter];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:parameter preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)clicklongPressLink:(CJLabelLinkModel *)linkModel isImage:(BOOL)isImage {
    NSString *title = [NSString stringWithFormat:@"长按点击: %@",linkModel.attributedString.string];
    if (isImage) {
        title = [NSString stringWithFormat:@"长按点击图片：%@",linkModel.insertView];
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
