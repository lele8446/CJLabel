# CJLabelTest 

## 功能简介
* NSString+CJString <br/>
类扩展提供了NSMutableAttributedString属性封装、动态计算NSString的CGSize方法
* CJLabel<br/>
可响应任意字符的点击<br/>
增加链点点击方法 addLinkString:linkAddAttribute:block:<br/>
取消点击链点 removeLinkString:<br/>

## cocoapods安装
* Podfile
> platform :ios, '7.0'
pod 'CJLabel', '~> 1.0.1'

## V1.0.0
v1.0.0版本注意：文本内存在相同链点时只有首次出现的链点能够响应点击

<br/>
## V1.0.1
*  增加文本中内容相同的链点能够响应点击属性sameLinkEnable，必须在设置self.attributedText前赋值，默认值为NO，只取文本中首次出现的链点。<br/>
*  CJLinkLabelModel的linkString改为NSString类型<br/>
