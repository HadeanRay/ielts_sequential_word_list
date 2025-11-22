#!/usr/bin/env python3
"""
Flutter应用图标生成脚本
此脚本将使用提供的logo.png生成适用于Android和iOS的各个分辨率图标
"""

import os
from PIL import Image
import json

def create_android_icons(source_path, output_dir):
    """生成Android各个分辨率的图标"""
    # Android图标尺寸定义 (mipmap-密度级别)
    android_sizes = {
        'mipmap-mdpi': 48,      # 1x
        'mipmap-hdpi': 72,      # 1.5x
        'mipmap-xhdpi': 96,     # 2x
        'mipmap-xxhdpi': 144,   # 3x
        'mipmap-xxxhdpi': 192   # 4x
    }
    
    print("生成Android图标...")
    
    for density, size in android_sizes.items():
        density_dir = os.path.join(output_dir, 'android', 'app', 'src', 'main', 'res', density)
        if not os.path.exists(density_dir):
            os.makedirs(density_dir)
        
        output_path = os.path.join(density_dir, 'ic_launcher.png')
        resize_and_save_image(source_path, output_path, size, size)
        print(f"  已生成: {output_path} ({size}x{size})")

def create_ios_icons(source_path, output_dir):
    """生成iOS各个分辨率的图标"""
    # iOS图标尺寸定义 (文件名 -> 尺寸)
    ios_sizes = {
        'Icon-App-20x20@1x.png': (20, 20),
        'Icon-App-20x20@2x.png': (40, 40),
        'Icon-App-20x20@3x.png': (60, 60),
        'Icon-App-29x29@1x.png': (29, 29),
        'Icon-App-29x29@2x.png': (58, 58),
        'Icon-App-29x29@3x.png': (87, 87),
        'Icon-App-40x40@1x.png': (40, 40),
        'Icon-App-40x40@2x.png': (80, 80),
        'Icon-App-40x40@3x.png': (120, 120),
        'Icon-App-60x60@2x.png': (120, 120),
        'Icon-App-60x60@3x.png': (180, 180),
        'Icon-App-76x76@1x.png': (76, 76),
        'Icon-App-76x76@2x.png': (152, 152),
        'Icon-App-83.5x83.5@2x.png': (167, 167),
        'Icon-App-1024x1024@1x.png': (1024, 1024),  # App Store
    }
    
    print("生成iOS图标...")
    
    ios_dir = os.path.join(output_dir, 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    if not os.path.exists(ios_dir):
        os.makedirs(ios_dir)
    
    for filename, (width, height) in ios_sizes.items():
        output_path = os.path.join(ios_dir, filename)
        resize_and_save_image(source_path, output_path, width, height)
        print(f"  已生成: {output_path} ({width}x{height})")
    
    # 生成iOS的Contents.json文件
    create_ios_contents_json(ios_dir)

def create_ios_contents_json(ios_dir):
    """生成iOS图标集的Contents.json文件"""
    contents = {
        "images": [
            {
                "size": "20x20",
                "idiom": "iphone",
                "filename": "Icon-App-20x20@2x.png",
                "scale": "2x"
            },
            {
                "size": "20x20",
                "idiom": "iphone",
                "filename": "Icon-App-20x20@3x.png",
                "scale": "3x"
            },
            {
                "size": "29x29",
                "idiom": "iphone",
                "filename": "Icon-App-29x29@1x.png",
                "scale": "1x"
            },
            {
                "size": "29x29",
                "idiom": "iphone",
                "filename": "Icon-App-29x29@2x.png",
                "scale": "2x"
            },
            {
                "size": "29x29",
                "idiom": "iphone",
                "filename": "Icon-App-29x29@3x.png",
                "scale": "3x"
            },
            {
                "size": "40x40",
                "idiom": "iphone",
                "filename": "Icon-App-40x40@2x.png",
                "scale": "2x"
            },
            {
                "size": "40x40",
                "idiom": "iphone",
                "filename": "Icon-App-40x40@3x.png",
                "scale": "3x"
            },
            {
                "size": "60x60",
                "idiom": "iphone",
                "filename": "Icon-App-60x60@2x.png",
                "scale": "2x"
            },
            {
                "size": "60x60",
                "idiom": "iphone",
                "filename": "Icon-App-60x60@3x.png",
                "scale": "3x"
            },
            {
                "size": "20x20",
                "idiom": "ipad",
                "filename": "Icon-App-20x20@1x.png",
                "scale": "1x"
            },
            {
                "size": "20x20",
                "idiom": "ipad",
                "filename": "Icon-App-20x20@2x.png",
                "scale": "2x"
            },
            {
                "size": "29x29",
                "idiom": "ipad",
                "filename": "Icon-App-29x29@1x.png",
                "scale": "1x"
            },
            {
                "size": "29x29",
                "idiom": "ipad",
                "filename": "Icon-App-29x29@2x.png",
                "scale": "2x"
            },
            {
                "size": "40x40",
                "idiom": "ipad",
                "filename": "Icon-App-40x40@1x.png",
                "scale": "1x"
            },
            {
                "size": "40x40",
                "idiom": "ipad",
                "filename": "Icon-App-40x40@2x.png",
                "scale": "2x"
            },
            {
                "size": "76x76",
                "idiom": "ipad",
                "filename": "Icon-App-76x76@1x.png",
                "scale": "1x"
            },
            {
                "size": "76x76",
                "idiom": "ipad",
                "filename": "Icon-App-76x76@2x.png",
                "scale": "2x"
            },
            {
                "size": "83.5x83.5",
                "idiom": "ipad",
                "filename": "Icon-App-83.5x83.5@2x.png",
                "scale": "2x"
            },
            {
                "size": "1024x1024",
                "idiom": "ios-marketing",
                "filename": "Icon-App-1024x1024@1x.png",
                "scale": "1x"
            }
        ],
        "info": {
            "version": 1,
            "author": "xcode"
        }
    }
    
    json_path = os.path.join(ios_dir, 'Contents.json')
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(contents, f, indent=2)
    print(f"  已生成: {json_path}")

def resize_and_save_image(source_path, output_path, width, height):
    """调整图片大小并保存"""
    with Image.open(source_path) as img:
        # 转换为RGBA模式以处理透明背景
        img = img.convert('RGBA')
        
        # 调整图片大小，使用高质量重采样算法
        resized_img = img.resize((width, height), Image.Resampling.LANCZOS)
        
        # 保存图片
        resized_img.save(output_path, 'PNG', optimize=True)

def main():
    # 项目根目录
    project_dir = '.'
    
    # 源图片路径
    source_path = os.path.join(project_dir, 'logo.png')
    
    # 检查源图片是否存在
    if not os.path.exists(source_path):
        print(f"错误: 源图片不存在: {source_path}")
        return
    
    print(f"开始生成图标，源图片: {source_path}")
    
    # 生成Android图标
    create_android_icons(source_path, project_dir)
    
    # 生成iOS图标
    create_ios_icons(source_path, project_dir)
    
    print("\n图标生成完成！")

if __name__ == '__main__':
    main()
