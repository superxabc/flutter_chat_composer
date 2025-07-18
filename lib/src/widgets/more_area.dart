import 'package:flutter/material.dart';
import '../theme/chat_composer_theme.dart';

class _MoreItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _MoreItem({required this.icon, required this.label, this.onTap});
}

class MoreArea extends StatelessWidget {
  final ChatComposerTheme theme;
  final Function(String action) onActionSelected;
  final double itemContentWidth; // 接收 item 的内容宽度
  final double moreAreaListViewPadding; // 接收 ListView 的内边距
  final double itemSpacing; // 接收 item 间距

  const MoreArea({
    Key? key,
    required this.theme,
    required this.onActionSelected,
    required this.itemContentWidth,
    required this.moreAreaListViewPadding,
    required this.itemSpacing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<_MoreItem> items = [
      _MoreItem(icon: Icons.photo_library_outlined, label: '相册', onTap: () => onActionSelected('album')),
      _MoreItem(icon: Icons.folder_outlined, label: '文件', onTap: () => onActionSelected('file')),
      _MoreItem(icon: Icons.scanner_outlined, label: '扫描', onTap: () => onActionSelected('scan')),
      _MoreItem(icon: Icons.call_outlined, label: '通话', onTap: () => onActionSelected('call')),
      _MoreItem(icon: Icons.more_horiz_outlined, label: '更多', onTap: () => onActionSelected('more')),
    ];

    return Container(
      color: Colors.transparent, // 背景透明
      // MoreArea 的高度由父组件 ChatComposer 的 SizedBox 控制，这里不需要设置
      child: ListView.separated(
        scrollDirection: Axis.horizontal, // 单行展示
        physics: const NeverScrollableScrollPhysics(), // 禁止滚动
        itemCount: items.length,
        padding: EdgeInsets.only(left: moreAreaListViewPadding, right: moreAreaListViewPadding), // 应用 ListView 的左右内边距
        itemBuilder: (context, index) {
          return SizedBox(
            width: itemContentWidth, // 每个item的固定宽度
            child: _MoreGridItem(
              item: items[index],
              theme: theme,
              itemSize: itemContentWidth, // 传递 item 的内容宽度
            ),
          );
        },
        separatorBuilder: (context, index) {
          return SizedBox(width: itemSpacing); // item 之间的间距
        },
      ),
    );
  }
}

class _MoreGridItem extends StatelessWidget {
  final _MoreItem item;
  final ChatComposerTheme theme;
  final double itemSize; // 接收 item 的尺寸

  const _MoreGridItem({
    Key? key,
    required this.item,
    required this.theme,
    required this.itemSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 定义统一的颜色和样式，不再依赖theme
    const itemColor = Color(0xFF333333); // 图标和文字统一使用深灰色（接近90%黑色）
    const itemTextStyle = TextStyle(
      fontSize: 12.0, // 增大字号
      fontWeight: FontWeight.bold, // 使用粗体
      color: itemColor, // 与图标颜色保持一致
    );

    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: itemSize, // 确保 item 是正方形
            height: itemSize, // 确保 item 是正方形
            decoration: BoxDecoration(
              color: Colors.white, // 固定背景色
              borderRadius: BorderRadius.circular(12.0), // 固定圆角
              border: Border.all(color: Colors.grey[300]!, width: 1.0), // 固定边框
            ),
            child: Icon(
              item.icon,
              size: 24.0, // 恢复为固定的、标准的icon尺寸
              color: itemColor,
            ),
          ),
          const SizedBox(height: 8.0), // 统一间距
          Text(
            item.label,
            style: itemTextStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


