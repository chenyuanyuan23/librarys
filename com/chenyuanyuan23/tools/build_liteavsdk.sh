#!/bin/bash

# 获取脚本所在目录
script_dir="$(cd "$(dirname "$0")" && pwd)"

# 获取脚本的上级目录
parent_dir="$(dirname "$script_dir")"

# 清空 temp_unzips 目录
rm -rf "$script_dir/temp_unzips"
mkdir -p "$script_dir/temp_unzips"

# 创建 LiteAVSDK_Player 目录
mkdir -p "$parent_dir/LiteAVSDK_Player"

# 创建 frameworks 目录
mkdir -p "$parent_dir/frameworks"

# 遍历脚本所在目录下的所有 zip 文件
for zip_file in "$script_dir"/*.zip; do
  if [ -f "$zip_file" ]; then
    # 解压到 temp_unzips 目录（所有 zip 文件都解压到这里）
    echo "解压 $zip_file 到 $script_dir/temp_unzips 目录..."
    unzip "$zip_file" -d "$script_dir/temp_unzips"
    if [ $? -eq 0 ]; then
      echo "$zip_file 解压到 temp_unzips 目录成功！"
    else
      echo "$zip_file 解压到 temp_unzips 目录失败！"
    fi

    # 检查 zip 文件名是否以 LiteAVSDK_Player_Android_ 开头
    if [[ "$zip_file" == *LiteAVSDK_Player_Android_* ]]; then
      # 提取版本号
      version=$(echo "$zip_file" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')

      if [ -n "$version" ]; then
        # 创建以版本号命名的文件夹
        output_dir="$parent_dir/LiteAVSDK_Player/$version"
        mkdir -p "$output_dir"

        # 拷贝 .aar 文件并生成同名的 .pom 文件
        aar_file=$(find "$script_dir/temp_unzips" -name "*.aar" | head -n 1)

        if [ -f "$aar_file" ]; then
          new_aar_name="LiteAVSDK_Player-$version.aar"
          cp "$aar_file" "$output_dir/$new_aar_name"
          echo "拷贝 $aar_file 到 $output_dir/$new_aar_name 成功！"

          pom_file="$output_dir/LiteAVSDK_Player-$version.pom"
          cat <<EOF > "$pom_file"
<?xml version="1.0" encoding="UTF-8"?>
<project xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd" xmlns="http://maven.apache.org/POM/4.0.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.chenyuanyuan23</groupId>
  <artifactId>LiteAVSDK_Player</artifactId>
  <version>$version</version>
  <packaging>aar</packaging>
</project>
EOF

          echo "生成 $pom_file 文件成功！"
        else
          echo "未找到解压后的 .aar 文件！"
        fi
      else
        echo "无法从 $zip_file 中提取版本号！"
      fi
    fi

    # 检查 zip 文件名是否以 LiteAVSDK_Player_iOS_ 开头
    if [[ "$zip_file" == *LiteAVSDK_Player_iOS_* ]]; then
       # 提取文件名（不包含扩展名）
      filename=$(basename "$zip_file" .zip)

      # 压缩 xcframework 目录
      zip_output_file="$parent_dir/frameworks/$filename.zip"
      unzipped_dir="$script_dir/temp_unzips/$filename"
      pushd "$unzipped_dir/SDK" > /dev/null
      zip -ro "$zip_output_file" TXFFmpeg.xcframework/ TXLiteAVSDK_Player.xcframework/ TXSoundTouch.xcframework/
      popd > /dev/null
      if [ $? -eq 0 ]; then
        echo "压缩 $zip_output_file 文件成功！"
      else
        echo "压缩 $zip_output_file 文件失败！"
      fi
    fi
  fi
done

echo "所有 zip 文件处理完成！"