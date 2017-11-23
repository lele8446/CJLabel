//
//  AttributedTableViewCell.m
//  tableViewLabel
//
//  Created by YiChe on 16/4/19.
//  Copyright © 2016年 YiChe. All rights reserved.
//

#import "AttributedTableViewCell.h"

@implementation AttributedTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.label.preferredMaxLayoutWidth = [[UIScreen mainScreen] bounds].size.width - 20;
    self.label.numberOfLines = 4;
    self.label.textInsets = UIEdgeInsetsMake(5, 5, 5, 0);
    self.label.enableCopy = YES;
//    self.label.font = [UIFont systemFontOfSize:12];
//    self.label.attributedTruncationToken = [[NSAttributedString alloc]initWithString:@""];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
