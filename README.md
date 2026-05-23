# 区块记账 (Chain Accounting)

基于区块链技术的记账应用，每笔交易都会生成一个包含 SHA-256 哈希的区块，确保数据不可篡改。

## 功能

- **区块链记账** — 每笔记账自动生成区块，通过哈希值相互链接，形成完整的区块链
- **哈希校验** — 单条账单卡片展示区块哈希，点击可查看完整的区块详情
- **账户管理** — 创建多个账户（支付宝、银行卡等），独立记录收支
- **统计图表** — 月度柱状图、账户分布饼图、各账户收支进度条
- **夜间模式** — 支持亮色/暗色主题切换
- **数据导出** — 一键导出全部区块链数据为 JSON 文件
- **数据持久化** — 使用 SharedPreferences 本地存储，关闭应用不丢失

## 技术架构

```
lib/
├── main.dart                     # 应用入口、主题配置、侧边栏导航
├── models/
│   ├── block.dart                # 区块模型（SHA-256 哈希计算）
│   ├── blockchain.dart           # 区块链模型（创世区块、proofOfWork、链验证）
│   ├── account.dart              # 账户模型
│   └── transaction.dart          # 交易记录模型
├── providers/
│   └── chain_provider.dart       # 状态管理（Provider），区块链操作、持久化
├── screens/
│   ├── home_page.dart            # 首页（账单列表、总资产卡片）
│   ├── stats_page.dart           # 统计页面（柱状图、饼图）
│   ├── accounts_page.dart        # 账户管理页面
│   ├── settings_page.dart        # 设置页面（夜间模式、导出、清空）
│   └── add_transaction_sheet.dart # 新增账单底部弹窗
```

## 依赖

| 包 | 用途 |
|---|---|
| `provider` | 状态管理 |
| `crypto` | SHA-256 哈希计算 |
| `fl_chart` | 柱状图、饼图 |
| `shared_preferences` | 本地数据持久化 |
| `intl` | 日期格式化 |
| `uuid` | 唯一 ID 生成 |
| `path_provider` | 文件路径获取 |
| `share_plus` | 数据分享导出 |

## 运行

```bash
# 安装依赖
flutter pub get

# 调试运行
flutter run

# 构建 Debug APK
flutter build apk --debug

# 构建签名 Release APK
flutter build apk --release
```

## 签名配置

Release 构建使用 `android/key.properties` 配置签名信息，密钥库位于 `android/app/upload-keystore.jks`。

## 平台

主要支持 Android，同时兼容 iOS / macOS / Linux / Windows。

## License

MIT.
