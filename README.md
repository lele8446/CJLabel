# CJLabelTest 

## 功能简介
包含NSString+CJString与CJLabel两个文件
#### NSString+CJString
NSString类别
  * `getNSAttributedString: labelDict:`<br/>
  NSMutableAttributedString属性封装方法

  ```objective-c
  NSDictionary *dic = @{
                        NSFontAttributeName:[UIFont systemFontOfSize:20],/*(字体)*/
                        NSForegroundColorAttributeName:[UIColor blackColor],/*(字体颜色)*/
                       };
  NSMutableAttributedString *labelTitle = [NSString getNSAttributedString:@"this is test string" labelDict:dic];
  ```
  * `sizeLabelToFit: width: height:`<br/>
  返回UILabel自适应后的size方法

  * `getStringRect: width: height:`<br/>
  动态计算NSString的CGSize方法

#### CJLabel
UILabel的extension，可响应任意字符的点击
  * `addLinkString: linkAddAttribute: block:`<br/>
  增加点击链点方法

  ```objective-c
  NSDictionary *linkDic = @{
                            NSForegroundColorAttributeName:[UIColor redColor],
                            NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)
                          };
    
  [self.label addLinkString:@"点击" linkAddAttribute:linkDic block:^(CJLinkLabelModel *linkModel) {
      NSLog(@"点击了链接: %@",linkModel.linkString);
  }];
  ```
  * `addLinkString: linkAddAttribute: linkParameter: block:`<br/>
  增加点击链点方法

  ```objective-c
  NSDictionary *linkDic = @{
                            NSForegroundColorAttributeName:[UIColor redColor],
                            NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)
                          };
    
  [self.label addLinkString:@"点击" linkAddAttribute:linkDic linkParameter:@{@"id":@"1",@"type":@"text"} block:^(CJLinkLabelModel *linkModel) {
      NSLog(@"点击了链接: %@",linkModel.linkString);
  }];
  ```
  * `removeLinkString:`<br/>
  移除点击链点方法

## cocoapods安装
* Podfile<br/>
```ruby
platform :ios, '7.0'
pod 'CJLabel', '~> 1.0.1'
```

## V1.0.0
v1.0.0版本注意：文本内存在相同链点时只有首次出现的链点能够响应点击

<br/>
## V1.0.1
*  增加文本中内容相同的链点能够响应点击属性sameLinkEnable，必须在设置self.attributedText前赋值，默认值为NO，只取文本中首次出现的链点。<br/>
*  CJLinkLabelModel的linkString改为NSString类型<br/>

<br/>
## V1.0.2
* 点击链点增加扩展属性parameter<br/>
* 增加方法`addLinkString: linkAddAttribute: linkParameter: block:`
