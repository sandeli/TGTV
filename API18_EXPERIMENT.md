# Android API 18 实验分支

此分支只用于尝试在 Android 4.3/API 18 上安装 TGTV，不代表项目正式支持 API 18。Flutter 3.19 默认最低版本是 API 19；此实验在 Manifest 中覆盖了 `share_plus`、`package_info_plus`、`path_provider_android` 和 `shared_preferences_android` 的 API 19 清单声明。为保留「关于」页的链接功能，实验分支将 `url_launcher_android` 固定到 6.2.1（最低 API 16）；6.3.2 的最低版本是 API 19。上述兼容处理不证明 Flutter 引擎或这些插件能在 API 18 设备上正常运行。

## 构建 ARMv7 测试 APK

使用项目对应的 Flutter 3.19.6 工具链和 Java 17，在仓库根目录运行：

```sh
flutter pub get
cd android
./gradlew :app:assembleRelease -Ptarget-platform=android-arm -Psplit-per-abi=true
```

本实验应通过 Gradle 直接构建；Flutter CLI 的 Gradle 自动迁移会把 `minSdkVersion` 改回默认的 API 19。生成的 ARMv7 APK 位于 `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`。

## 当前实验 APK

本次 APK 为 `1.5.1+616`，包名 `com.sandeli.tgtv`，`versionName` 为 `1.5.1`，pubspec build number 为 `616`。ARMv7 分包会给 APK manifest 的 `versionCode` 加上 ABI 偏移，实际清单值为 `1616`。清单核验结果：最低 API 18、目标 API 29、仅包含 `armeabi-v7a`；APK 大小约 11 MB。Gradle 构建成功，`apksigner` 验证 v1 和 v2 签名均通过。

当前环境没有提供项目 release keystore，因此 APK 使用调试签名（`CN=Android Debug`）。它不是正式 Release 包；若设备已有同包名但由其他密钥签名的安装，系统可能拒绝覆盖安装。不要仅为安装测试包而贸然卸载旧应用，以免丢失本地数据。

API18 实验分支的完整 Flutter 测试 93 项通过，静态分析无问题。此环境没有连接 Android 设备，因此未验证安装、启动或 IPTV 播放，也不能据此声称它能在 LeTV S40 Air L 上工作。只有在目标设备上实际完成安装、启动及用户常用频道的播放测试后，才能评估是否值得继续维护该分支。

不要将此实验 APK 发布为正式 Release。
