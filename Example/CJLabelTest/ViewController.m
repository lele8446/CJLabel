//
//  ViewController.m
//  tableViewLabelDemo
//
//  Created by YiChe on 16/6/13.
//  Copyright © 2016年 YiChe. All rights reserved.
//

#import "ViewController.h"
#import "AttributedTableViewCell.h"
#import "DetailViewController.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,CJLabelLinkDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *espressos;

@property (nonatomic, strong) AttributedTableViewCell *tempCell;

@end

@implementation ViewController

- (AttributedTableViewCell *)tempCell {
    if (!_tempCell) {
        _tempCell = [[[NSBundle mainBundle] loadNibNamed:@"AttributedTableViewCell" owner:self options:Nil] lastObject];
    }
    return _tempCell;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height) style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.view addSubview:self.tableView];
    
    [self handleData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handleData {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Example" ofType:@"txt"];
    NSArray *data = [[NSString stringWithContentsOfFile:filePath usedEncoding:nil error:nil] componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    self.espressos = [NSMutableArray array];
    for (int i = 0;i<data.count;i++) {
        NSString *str = [data objectAtIndex:i];
        if (str.length == 0) {
            continue;
        }
        NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc]initWithString:str];
        [attStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14] range:NSMakeRange(0, str.length)];
        
        CJLabelConfigure *configure =
        [CJLabel configureAttributes:@{
                                       NSForegroundColorAttributeName:[UIColor blueColor],
                                       NSFontAttributeName:[UIFont boldSystemFontOfSize:15],
//                                       kCJBackgroundFillColorAttributeName:[UIColor lightGrayColor]
                                       }
                              isLink:YES
                activeLinkAttributes:@{NSForegroundColorAttributeName:[UIColor redColor]}
                           parameter:nil
                      clickLinkBlock:nil
                      longPressBlock:nil];
        attStr = [CJLabel configureAttrString:attStr withString:@"CJLabel" sameStringEnable:YES configure:configure];
//        attStr = [CJLabel initWithAttributedString:attStr strIdentifier:nil configure:configure];
        
        [self.espressos addObject:attStr];
    }
}


- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section {
    return (NSInteger)[self.espressos count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(__unused NSIndexPath *)indexPath {
    NSAttributedString *content = [self.espressos objectAtIndex:(NSUInteger)indexPath.row];
    
    // 方法一 systemLayoutSizeFittingSize:计算高度
    self.tempCell.label.text = content;
    CGSize size =[self.tempCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height+1;

//    // 方法二 CJLabel类方法计算高度
//    CGSize size1 = [CJLabel sizeWithAttributedString:content withConstraints:CGSizeMake(ScreenWidth-20, CGFLOAT_MAX) limitedToNumberOfLines:0];
//    // label垂直方向约束高度top=10，另外再 + 1
//    return size1.height+11;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    AttributedTableViewCell *cell = (AttributedTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"AttributedTableViewCell" owner:self options:Nil] lastObject];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.label.delegate = self;
    NSAttributedString *content = [self.espressos objectAtIndex:(NSUInteger)indexPath.row];
    cell.label.text = content;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //    NSLog(@"点击第 %@ 行cell",@(indexPath.row+1));
    DetailViewController *detailCtr = [[DetailViewController alloc]initWithNibName:@"DetailViewController" bundle:nil];
    detailCtr.index = indexPath.row;
    detailCtr.content = self.espressos[indexPath.row];
    [self.navigationController pushViewController:detailCtr animated:YES];
}

#pragma mark - CJLabelLinkDelegate
- (void)CJLable:(CJLabel *)label didClickLink:(CJLabelLinkModel *)linkModel {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"点击链点" message:linkModel.attributedString.string preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)CJLable:(CJLabel *)label didLongPressLink:(CJLabelLinkModel *)linkModel {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"长按链点" message:linkModel.attributedString.string preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
