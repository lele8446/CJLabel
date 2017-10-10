# CJLabel

***注意***

**V3.0.0** 版本引入CJLabelConfigure类，优化了NSAttributedString的设置，旧的配置API不再支持。相关调用请参照以下相关方法<br/>
`+ initWithImageName:imageSize:imagelineAlignment:configure:`<br/>
`+ initWithString:configure:`<br/>
`+ initWithAttributedString:strIdentifier:configure:`<br/>


先看点击链点效果图：<br/>
![点击链点](http://7xnrwl.com1.z0.glb.clouddn.com/CJLabel1.gif)
![点击链点](http://7xnrwl.com1.z0.glb.clouddn.com/CJLabel2.gif)

## 功能简介

 * CJLabel 继承自 UILabel，其文本绘制基于NSAttributedString实现，同时增加了图文混排、富文本展示以及添加自定义点击链点并设置点击链点文本属性的功能。
 *
 * CJLabel 与 UILabel 不同点：
 *
   1. `- init` 不可直接调用init初始化，请使用`initWithFrame:` 或 `initWithCoder:`，以便完成相关初始属性设置
 
   2. `attributedText` 与 `text` 均可设置文本，注意 [self setText:text]中 text类型只能是NSAttributedString或NSString
 
   3. `NSAttributedString`不再通过`NSTextAttachment`显示图片（使用`NSTextAttachment`不会起效），请调用
      `+ initWithImageName:imageSize:imagelineAlignment:configure:`或者
      `+ insertImageAtAttrString:imageName:imageSize:imagelineAlignment:atIndex:configure:`方法添加图片
 
   4. 新增`extendsLinkTouchArea`， 设置是否加大点击响应范围，类似于UIWebView的链点点击效果
 
   5. 新增`shadowRadius`， 设置文本阴影模糊半径，可与 `shadowColor`、`shadowOffset` 配合设置，注意改设置将对全局文本起效
 
   6. 新增`textInsets` 设置文本内边距
 
   7. 新增`verticalAlignment` 设置垂直方向的文本对齐方式
   
   8. 新增`delegate` 点击链点代理
 *
 * CJLabel 已知bug：
 *
   `numberOfLines`大于0且小于实际`label.numberOfLines`，同时`verticalAlignment`不等于`CJContentVerticalAlignmentTop`时，文本显示位置有偏差

## CJLabel引用
### 一、直接导入
下载demo，将CJLabel文件夹导入项目，引用头文件`#import "CJLabel.h"`
### 二、CocoaPods安装
* Podfile<br/>
```ruby
platform :ios, '7.0'
target 'CJLabelDemo' do
   pod 'CJLabel', '~> 3.0.0'
end
```

## 若干API介绍
* `+ sizeWithAttributedString:withConstraints:limitedToNumberOfLines:`
  计算指定NSAttributedString的size大小
```objective-c
CGSize size = [CJLabel sizeWithAttributedString:str withConstraints:CGSizeMake(320, CGFLOAT_MAX) limitedToNumberOfLines:0]
  ```
  
* `+ insertImageAtAttrString:imageName:imageSize:imagelineAlignment:atIndex:configure:` 
插入图片链点
在指定位置插入图片，插入图片为可点击的链点！！！返回插入图片后的NSMutableAttributedString（图片占位符所占的NSRange={loc,1}）
```objective-c
attStr = [CJLabel insertImageAtAttrString:attStr
                                            imageName:@"CJLabel.png"
                                            imageSize:CGSizeMake(120, 85)
                                              atIndex:3
                                   imagelineAlignment:CJVerticalAlignmentBottom
                                            configure:imgConfigure];
  ```
  
* `+ configureAttrString:atRange:configure:`
根据指定NSRange配置富文本，可设置指定NSRange文本为可点击链点！！！<br/>
```objective-c
attStr = [CJLabel configureAttrString:attStr atRange:NSMakeRange(0, 3) configure:configure];
```

* `+ configureAttrString:withString:sameStringEnable:configure:`
对文本中跟withString相同的文字配置富文本，可设置指定的文字为可点击链点！！！<br/>
```objective-c
attStr = [CJLabel configureAttrString:attStr
                                       withString:@"CJLabel"
                                 sameStringEnable:NO
                                        configure:configure];
```

* 移除点击链点<br/>
```objective-c
- (void)removeLinkAtRange:(NSRange)range;

- (void)removeAllLink;
```

## 版本说明
### V3.0.0
* 优化富文本配置方法，新增CJLabelConfigure类，简化方法调用，增加对NSAttributedString点击链点的判断（比如对于两个重名用户：@lele 和 @lele，可以分别设置不同的点击响应事件）

### V2.1.2
* 新增方法，可修改插入图片所在行图文在垂直方向的对齐方式（只针对当前行），有居上、居中、居下选项，默认居下

### V2.1.2
* 修复单行文字时候点击链点的判断，增加delegate
### V2.0.0
* 重构了底层对点击链点响应的判断，增加插入图片、插入图片链点、点击链点背景色填充、点击链点边框线描边等功能
* v2.0.0之后版本与v1.x.x版本差别较大，基本上重写了增加以及移除点击链点的API
***
### V1.0.2
* 点击链点增加扩展属性parameter<br/>
* 增加方法`- addLinkString: linkAddAttribute: linkParameter: block:`<br/>
### V1.0.1
*  增加文本中内容相同的链点能够响应点击属性sameLinkEnable，必须在设置self.attributedText前赋值，默认值为NO，只取文本中首次出现的链点。<br/>
*  CJLinkLabelModel的linkString改为NSString类型<br/>
### V1.0.0
*  v1.0.0版本注意：文本内存在相同链点时只有首次出现的链点能够响应点击

## 相关介绍
[CJLabel图文混排二 —— UILabel插入图片以及精确链点点击](http://www.jianshu.com/p/9a70533d217e)
