# repo 22
## LiteAVSDK_Player 新包上传说明
  给过来的sdk如
  LiteAVSDK_Player_Android_12.4.0.17372.zip
  LiteAVSDK_Player_iOS_12.4.0.17856.zip
  放到tools目录下执行build_liteavsdk.sh脚本即可完成“如何使用”之前的步骤

  android: 
  1.LiteAVSDK_Player目录下 -> 
  2.版本号目录 ->
  3.放入 LiteAVSDK_Player arr -> 
  4.拷贝一个pom pom跟arr同名 LiteAVSDK_Playe-{版本号}.{arr|pom} ->
  5.修改 pom内的版本号
  6.如何使用
    dependencies {
        implementation 'com.chenyuanyuan23:LiteAVSDK_Player:{版本号}'
    }

  ios:
  1.frameworks目录下 -> 
  2.需要的.xcframework 压缩成 LiteAVSDK_Player_iOS_{版本号}.zip 直接选中所有xcframework压缩不要带目录  提交到git
  3.如何使用
    搜索LiteAVSDK_Player_iOS 替换相关zip名称


