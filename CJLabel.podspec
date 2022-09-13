#
#  Be sure to run `pod spec lint CJLabel.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "CJLabel"
  s.version      = "4.7.3"
  s.summary      = "A drop-in replacement for UILabel that supports NSAttributedString, rich text, links, select copy and more."
  s.homepage     = "https://github.com/lele8446/CJLabelTest"
  # s.license      = "MIT"
  s.license      = { :type => 'Apache License, Version 2.0', :text => <<-LICENSE
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    LICENSE
  }
  s.author       = { "ChiJinLian" => "lele8446@foxmail.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/lele8446/CJLabelTest.git", :tag => "#{s.version}" }
  s.source_files  = "CJLabel/*"

end
