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
    ditto -x -k "$zip_file" "$script_dir/temp_unzips"
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

      # 提取版本号（用于 SPM 子目录命名）
      ios_version=$(echo "$zip_file" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')

      unzipped_dir="$script_dir/temp_unzips/$filename"

      # ─── 原有：合包 zip（CocoaPods 模式用，podspec 的 prepare_command 会下载这个） ───
      zip_output_file="$parent_dir/frameworks/$filename.zip"
      pushd "$unzipped_dir/SDK" > /dev/null
      zip -ro "$zip_output_file" TXFFmpeg.xcframework/ TXLiteAVSDK_Player.xcframework/ TXSoundTouch.xcframework/
      popd > /dev/null
      if [ $? -eq 0 ]; then
        echo "压缩 $zip_output_file 文件成功！"
      else
        echo "压缩 $zip_output_file 文件失败！"
      fi

      # ─── 新增：SPM 模式产物（独立 xcframework zip + GitHub release） ───
      if [ -n "$ios_version" ]; then
        spm_dir="$parent_dir/frameworks/spm/$ios_version"
        mkdir -p "$spm_dir"

        # 分别打 3 个独立 xcframework zip（SPM binaryTarget 要求 zip 内只有单个 xcframework）
        echo "→ 生成 SPM 独立 xcframework zip 到 $spm_dir/"
        pushd "$unzipped_dir/SDK" > /dev/null
        for fw in TXFFmpeg TXLiteAVSDK_Player TXSoundTouch; do
          rm -f "$spm_dir/${fw}.xcframework.zip"
          zip -ro "$spm_dir/${fw}.xcframework.zip" "${fw}.xcframework/" > /dev/null
        done
        popd > /dev/null

        # 计算 SPM sha256 checksum
        checksum_file="$spm_dir/checksums.txt"
        : > "$checksum_file"
        for fw in TXFFmpeg TXLiteAVSDK_Player TXSoundTouch; do
          sum=$(shasum -a 256 "$spm_dir/${fw}.xcframework.zip" | awk '{print $1}')
          printf "%-40s %s\n" "${fw}.xcframework.zip" "$sum" >> "$checksum_file"
        done
        echo "→ checksums:"
        cat "$checksum_file"

        # 上传到 GitHub release，tag 自动避让已存在版本（同版本重打 → 加 -r2/-r3 后缀）
        if ! command -v gh > /dev/null 2>&1; then
          echo "⚠️  未检测到 gh CLI，跳过 release 上传。装好后可手动："
          echo "    gh release create <tag> --repo chenyuanyuan23/librarys $spm_dir/*.xcframework.zip"
        else
          base_tag="$filename"  # e.g. LiteAVSDK_Player_iOS_13.1.0.20454
          release_tag="$base_tag"
          rev=1
          while gh release view "$release_tag" --repo chenyuanyuan23/librarys >/dev/null 2>&1; do
            rev=$((rev + 1))
            release_tag="${base_tag}-r${rev}"
          done
          echo "→ 使用 release tag: $release_tag"

          gh release create "$release_tag" \
            --repo chenyuanyuan23/librarys \
            --title "TXLiteAVSDK Player iOS $ios_version (SPM, ${release_tag##*-})" \
            --notes "SPM-compatible xcframeworks for super_player.

Checksums:
$(cat "$checksum_file")" \
            "$spm_dir/TXFFmpeg.xcframework.zip" \
            "$spm_dir/TXLiteAVSDK_Player.xcframework.zip" \
            "$spm_dir/TXSoundTouch.xcframework.zip"

          echo ""
          echo "→ super_player 的 Package.swift 用以下 url + checksum："
          for fw in TXFFmpeg TXLiteAVSDK_Player TXSoundTouch; do
            sum=$(shasum -a 256 "$spm_dir/${fw}.xcframework.zip" | awk '{print $1}')
            cat <<EOF
        .binaryTarget(
            name: "${fw}",
            url: "https://github.com/chenyuanyuan23/librarys/releases/download/${release_tag}/${fw}.xcframework.zip",
            checksum: "${sum}"
        ),
EOF
          done
        fi
      fi
    fi
  fi
done

echo "所有 zip 文件处理完成！"