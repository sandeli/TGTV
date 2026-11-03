<div align="center">

# HTV · 本机 IPTV 播放器

**无内置频道源、无账号：导入自己的播放列表，在 Android 手机、电视或电视盒子播放。**

[![Platform](https://img.shields.io/badge/Android-4.4%2B-brightgreen)](#从源码构建)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)

</div>

---

<p align="center">
  <img src="assets/images/screenshot-panel.jpg" width="49%" alt="频道面板与播放列表">
  <img src="assets/images/screenshot-settings.jpg" width="49%" alt="播放器设置面板">
</p>

## 这是一个空壳播放器

App 不内置频道列表，也不要求登录。首次打开时列表为空；频道来自用户主动导入的订阅。播放器保留遥控器、触屏、收藏、自动切换备用流、回看与 EPG 等功能（后两项取决于订阅或 EPG 数据源是否支持）。

## 导入播放列表

1. 电视打开「设置 → 订阅链接 → 二维码」。
2. 手机和电视连接同一个局域网，在手机扫码打开的空白页面手动粘贴播放列表 URL。
3. 点「导入到电视」。电视从该 URL 获取列表并开始播放。

支持 **M3U、TXT（`#genre#`）、XSPF**；也兼容项目原有的 JSON 列表格式。App 不会预填或指定任何订阅地址。新导入的 URL 会替换当前保存的订阅。

扫码页不使用配对令牌，局域网服务只提供导入页面和播放列表导入接口；它仅在二维码页打开期间运行，退出后停止监听。请仅在可信的家庭网络中使用。

## 数据与隐私

订阅 URL、下载的播放列表、节目单缓存和应用设置保存在电视本机的应用私有存储中，不上传到云端或远程控制后台。升级时，旧版用户订阅缓存会迁移到本机持久目录；旧版内置频道列表及用户标识会删除。

网络仅用于访问用户主动填写的播放列表 URL、获取节目单、播放频道流，以及在用户查看版本信息时查询 GitHub 发布信息。项目不包含广告或统计 SDK；没有远程命令、远程配置下发或云端订阅保存接口。

## 操作

- 电视遥控器：方向键或数字键换台，OK 打开频道面板，菜单键进入设置。
- 手机触屏：上下滑动换台，点按显示控制面板，长按打开设置。
- 频道收藏、频道切换与回看能力取决于频道列表本身提供的内容。

## 从源码构建

为兼容 Android 4.4（API 19），请使用 **Flutter 3.19.6**（Flutter 3.22 起最低 Android 版本改为 API 21）、JDK 17 和 Android SDK 34。最低 SDK 已在 `android/app/build.gradle` 中明确设置为 API 19。

```bash
flutter pub get
flutter test
flutter analyze
flutter build apk --release
```

APK 位于 `build/app/outputs/flutter-apk/`。没有发布签名文件时，构建产物使用调试签名，适合安装验证；正式发布应使用自己的签名密钥。

## 许可

本项目遵循 [Apache License 2.0](LICENSE)。
