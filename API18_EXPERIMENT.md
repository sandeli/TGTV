# Android API 18 实验分支

此分支只用于尝试在 Android 4.3/API 18 上安装 TGTV，不代表项目正式支持 API 18。Flutter 3.19 默认最低版本是 API 19；此实验还强制覆盖了 `share_plus`、`package_info_plus`、`path_provider_android` 和 `shared_preferences_android` 的 API 19 清单声明。绕过这些检查不证明 Flutter 引擎或插件能在 API 18 正常运行。

## 构建 ARMv7 测试 APK

使用项目对应的 Flutter 3.19 工具链和 Java 17，在仓库根目录运行：

```sh
flutter pub get
cd android
./gradlew :app:assembleRelease -Ptarget-platform=android-arm -Psplit-per-abi=true
```

本实验应通过 Gradle 直接构建；Flutter CLI 的 Gradle 自动迁移会把 `minSdkVersion` 改回默认的 API 19。生成的 ARMv7 APK 位于 `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`。

## 本次构建结果

APK 包名为 `com.sandeli.tgtv`，版本 `6.0.1`，清单最低 API 为 18、目标 API 为 29，大小约 11.28 MB。它通过了构建、APK 签名和清单检查；本环境没有连接 Android 设备，因此没有验证安装、启动或任何 IPTV 播放，也不能据此声称它能在 LeTV S40 Air L 上工作。

不要将此实验 APK 发布为正式 Release。只有在目标设备上实际完成安装、启动及用户常用频道的播放测试后，才能评估是否值得继续维护该分支。