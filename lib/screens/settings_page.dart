import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../providers/chain_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChainProvider>(
      builder: (context, provider, _) {
        final chainValid = provider.verifyChain();
        final blockCount = provider.blockchain.chain.length;
        final txCount = provider.transactions.length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Blockchain status
            const Text(
              '区块链状态',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _StatusRow(
                      label: '链状态',
                      value: chainValid ? '已验证' : '异常',
                      icon: chainValid ? Icons.check_circle : Icons.error,
                      color: chainValid
                          ? const Color(0xFF43A047)
                          : const Color(0xFFE53935),
                    ),
                    const Divider(),
                    _StatusRow(
                      label: '区块总数',
                      value: '$blockCount',
                      icon: Icons.link,
                      color: const Color(0xFF1565C0),
                    ),
                    const Divider(),
                    _StatusRow(
                      label: '交易总数',
                      value: '$txCount',
                      icon: Icons.receipt_long,
                      color: const Color(0xFF1565C0),
                    ),
                    const Divider(),
                    _StatusRow(
                      label: '账户总数',
                      value: '${provider.accounts.length}',
                      icon: Icons.account_balance_wallet,
                      color: const Color(0xFF1565C0),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Settings
            const Text(
              '设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  // Dark mode toggle
                  ListTile(
                    leading: Icon(
                      provider.isDarkMode
                          ? Icons.dark_mode
                          : Icons.light_mode,
                      color: provider.isDarkMode
                          ? Colors.amber
                          : const Color(0xFF1565C0),
                    ),
                    title: const Text('夜间模式'),
                    subtitle: Text(provider.isDarkMode ? '已开启' : '已关闭'),
                    trailing: Switch(
                      value: provider.isDarkMode,
                      onChanged: (_) => provider.toggleDarkMode(),
                      activeThumbColor: const Color(0xFF1565C0),
                    ),
                  ),
                  const Divider(height: 1),
                  // Export data
                  ListTile(
                    leading: const Icon(Icons.file_download,
                        color: Color(0xFF1565C0)),
                    title: const Text('导出区块数据'),
                    subtitle: const Text('导出全部区块链数据为JSON文件'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _exportData(context, provider),
                  ),
                  const Divider(height: 1),
                  // Clear all
                  ListTile(
                    leading:
                        const Icon(Icons.delete_sweep, color: Color(0xFFE53935)),
                    title: const Text('清空全部记录',
                        style: TextStyle(color: Color(0xFFE53935))),
                    subtitle: const Text('删除所有账户和账单记录'),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFFE53935)),
                    onTap: () => _confirmClearAll(context, provider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // About
            const Text(
              '关于',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chain Accounting',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    Text(
                      '基于区块链技术的记账应用。每笔交易都会生成一个包含SHA-256哈希的区块，'
                      '确保数据不可篡改。所有区块通过哈希值相互链接，形成完整的区块链。',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    SizedBox(height: 8),
                    Text('版本: 1.0.0',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _exportData(BuildContext context, ChainProvider provider) async {
    if (provider.transactions.isEmpty && provider.accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('暂无数据可导出'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      final jsonData = provider.exportData();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'chain_accounting_$timestamp.json';

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(jsonData, flush: true);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Chain Accounting 区块链数据导出',
      );
    } catch (e) {
      // Fallback: copy to clipboard
      final jsonData = provider.exportData();
      await Clipboard.setData(ClipboardData(text: jsonData));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('数据已复制到剪贴板'),
            backgroundColor: const Color(0xFF43A047),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _confirmClearAll(BuildContext context, ChainProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Color(0xFFE53935)),
            SizedBox(width: 8),
            Text('清空全部记录'),
          ],
        ),
        content: const Text(
          '此操作将删除所有账户和账单记录，区块链将重置为创世区块。\n\n此操作不可撤销，确定继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE53935)),
            onPressed: () {
              provider.clearAll();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('已清空全部记录'),
                  backgroundColor: const Color(0xFFE53935),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 15)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
