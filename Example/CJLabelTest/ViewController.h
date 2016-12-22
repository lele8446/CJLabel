//
//  ViewController.h
//  CJLabelTest
//
//  Created by C.K.Lian on 15/12/11.
//  Copyright © 2015年 C.K.Lian. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CJLabel.h"

@interface ViewController : UIViewController
@property(nonatomic,weak)IBOutlet CJLabel *label;
@property(nonatomic,weak)IBOutlet UITextView *textView;
@property(nonatomic,weak)IBOutlet UIButton *button;


@end

