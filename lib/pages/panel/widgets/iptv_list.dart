import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:collection/collection.dart';
import 'package:video_player_example/common/index.dart';
import 'package:video_player_example/pages/settings/view.dart';

import '../../../common/widgets/two_dimension_list_view.dart';

class PanelIptvList extends StatefulWidget {
  const PanelIptvList({super.key});

  @override
  State<PanelIptvList> createState() => _PanelIptvListState();
}

class _PanelIptvListState extends State<PanelIptvList> {
  final iptvStore = GetIt.I<IptvStore>();
  final _categoryFocusNode = FocusNode();
  final _channelFocusNode = FocusNode();

  /// 一级菜单包含收藏、用户播放列表分类，以及源切换/设置操作。
  static const int _favoriteRow = 0;
  static const int _firstGroupRow = 1;
  static const int _channelFocusAnchorIndex = 5;

  bool _showFavorites = false;
  bool _channelsFocused = false;
  String? _selectedGroupName;

  bool get _isCompact => MediaQuery.of(context).size.shortestSide < 600;

  int get _sourceCount => iptvStore.currentSources.length;
  bool get _hasSourceSwitch => _sourceCount > 1;

  IptvGroup? _selectedGroup(List<IptvGroup> groups) {
    if (_showFavorites) return null;

    final selectedName = _selectedGroupName;
    if (selectedName != null) {
      final selected =
          groups.firstWhereOrNull((group) => group.name == selectedName);
      if (selected != null) return selected;
    }

    // 初次打开时展示当前频道所属分类；若频道不在列表中则回退到首组。
    return groups.elementAtOrNull(iptvStore.currentIptv.groupIdx) ??
        groups.firstOrNull;
  }

  int _sourceRow(int groupCount) =>
      _hasSourceSwitch ? _firstGroupRow + groupCount : -1;

  int _settingsRow(int groupCount) =>
      _firstGroupRow + groupCount + (_hasSourceSwitch ? 1 : 0);

  void _focusChannels() {
    setState(() => _channelsFocused = true);
    _channelFocusNode.requestFocus();
  }

  void _focusCategories() {
    setState(() => _channelsFocused = false);
    _categoryFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _categoryFocusNode.dispose();
    _channelFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Observer(builder: (context) {
        final groups = iptvStore.iptvGroupList;
        final favoriteList = iptvStore.favoriteIptvList;
        final selectedGroup = _selectedGroup(groups);
        final channelList = _showFavorites
            ? favoriteList
            : (selectedGroup?.list ?? const <Iptv>[]);
        final categoryCount = _firstGroupRow +
            (groups.isEmpty ? 1 : groups.length) +
            (_hasSourceSwitch ? 1 : 0) +
            1; // settings
        final sourceRow = _sourceRow(groups.length);
        final settingsRow = _settingsRow(groups.length);
        final activeGroupIndex = selectedGroup == null
            ? -1
            : groups.indexWhere((group) => group.name == selectedGroup.name);
        final categoryPosition = _showFavorites
            ? _favoriteRow
            : activeGroupIndex >= 0
                ? _firstGroupRow + activeGroupIndex
                : _favoriteRow;
        final currentChannelIndex = channelList.indexWhere((item) =>
            item.name == iptvStore.currentIptv.name &&
            item.tvgName == iptvStore.currentIptv.tvgName);
        final initialChannelPosition =
            currentChannelIndex < 0 ? 0 : currentChannelIndex;
        final leftWidth = _isCompact
            ? (constraints.maxWidth * 0.3).clamp(104.0, 210.0).toDouble()
            : (constraints.maxWidth * 0.34).clamp(110.w, 300.w).toDouble();
        final rowHeight = _isCompact
            ? (constraints.maxHeight * 0.18).clamp(48.0, 60.0).toDouble()
            : 82.h;
        final rowGap = _isCompact ? 5.0 : 8.h;
        final categoryHeaderHeight = _isCompact ? 27.0 : 36.h;
        final channelHeaderHeight = _isCompact ? 40.0.h : 48.h;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: leftWidth,
              color: AppTheme.categoryMenuSurface,
              child: TwoDimensionListView(
                key: const ValueKey('category-list'),
                focusNode: _categoryFocusNode,
                autofocus: !_channelsFocused,
                verticalLayout: true,
                viewportHeight: constraints.maxHeight,
                initialPosition: (row: categoryPosition, col: 0),
                size: (rowHeight: rowHeight, colWidth: 0),
                scrollOffset: (row: 0, col: 0),
                gap: (row: rowGap, col: 4.h),
                headerHeightBuilder: (row) => row == 0 || row == _firstGroupRow
                    ? categoryHeaderHeight
                    : 0,
                itemCount: (
                  row: categoryCount,
                  col: (_) => 1,
                ),
                rowTopBuilder: (context, row) {
                  if (row == 0) return _buildSectionHeader('一级菜单');
                  if (row == _firstGroupRow) {
                    return _buildSectionHeader('频道分类');
                  }
                  return const SizedBox.shrink();
                },
                onArrowRight: _focusChannels,
                onSelect: (position) {
                  if (position.row == _favoriteRow) {
                    setState(() {
                      _showFavorites = true;
                      _selectedGroupName = null;
                    });
                    return;
                  }
                  if (position.row == sourceRow) {
                    iptvStore.switchToNextSource();
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(SnackBar(
                        content: Text(
                            '已切换到源 ${iptvStore.currentSourceIndex + 1}/$_sourceCount'),
                        duration: const Duration(milliseconds: 1500),
                      ));
                    return;
                  }
                  if (position.row == settingsRow) {
                    NavigatorUtil.push(context, const SettingsPage());
                    return;
                  }

                  final group =
                      groups.elementAtOrNull(position.row - _firstGroupRow);
                  if (group != null) {
                    setState(() {
                      _showFavorites = false;
                      _selectedGroupName = group.name;
                      _channelsFocused = false;
                    });
                  }
                },
                itemBuilder: (context, position, isSelected) {
                  if (position.row == _favoriteRow) {
                    return _buildCategoryItem(
                      title: '我的收藏',
                      subtitle: '${favoriteList.length} 个频道',
                      isSelected: isSelected,
                      isFocused: _categoryFocusNode.hasFocus,
                    );
                  }
                  if (position.row == sourceRow) {
                    return _buildActionItem(
                      icon: Icons.swap_horiz,
                      label: '切换源',
                      isSelected: isSelected,
                      isFocused: _categoryFocusNode.hasFocus,
                    );
                  }
                  if (position.row == settingsRow) {
                    return _buildActionItem(
                      icon: Icons.settings,
                      label: '设置',
                      isSelected: isSelected,
                      isFocused: _categoryFocusNode.hasFocus,
                    );
                  }

                  final group =
                      groups.elementAtOrNull(position.row - _firstGroupRow);
                  if (group == null) {
                    return _buildEmptyItem(
                      '暂无分类',
                      isSelected,
                      isFocused: _categoryFocusNode.hasFocus,
                      unselectedFill: AppTheme.categoryMenuTileFill,
                    );
                  }
                  return _buildCategoryItem(
                    title: group.name,
                    subtitle: '${group.list.length} 个频道',
                    isSelected: isSelected,
                    isFocused: _categoryFocusNode.hasFocus,
                  );
                },
              ),
            ),
            Container(
              width: 1.w,
              margin: EdgeInsets.symmetric(vertical: 8.h),
              color: AppTheme.fgFaded(context, 0.22),
            ),
            Expanded(
              child: Container(
                color: AppTheme.channelMenuSurface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: channelHeaderHeight,
                      child: _buildSectionHeader(
                        '二级菜单 · ${_showFavorites ? '我的收藏' : (selectedGroup?.name ?? '频道')}',
                      ),
                    ),
                    Expanded(
                      child:
                          LayoutBuilder(builder: (context, channelConstraints) {
                        return TwoDimensionListView(
                          key: ValueKey(
                              'channel-list-${_showFavorites ? 'favorites' : selectedGroup?.name ?? 'empty'}'),
                          focusNode: _channelFocusNode,
                          autofocus: _channelsFocused,
                          verticalLayout: true,
                          viewportHeight: channelConstraints.maxHeight,
                          verticalFocusAnchorIndex: _channelFocusAnchorIndex,
                          initialPosition: (
                            row: initialChannelPosition,
                            col: 0
                          ),
                          size: (rowHeight: rowHeight, colWidth: 0),
                          scrollOffset: (row: 0, col: 0),
                          gap: (row: rowGap, col: 4.h),
                          headerHeightBuilder: (_) => 0,
                          itemCount: (
                            row: channelList.isEmpty ? 1 : channelList.length,
                            col: (_) => 1,
                          ),
                          onArrowLeft: _focusCategories,
                          onSelect: (position) {
                            final iptv =
                                channelList.elementAtOrNull(position.row);
                            if (iptv == null) return;
                            iptvStore.currentIptv = iptv;
                            Navigator.pop(context);
                          },
                          onLongSelect: (position) {
                            final iptv =
                                channelList.elementAtOrNull(position.row);
                            if (iptv == null) return;
                            iptvStore.toggleFavorite(iptv).then((nowFavorite) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context)
                                ..clearSnackBars()
                                ..showSnackBar(SnackBar(
                                  content: Text(nowFavorite
                                      ? '已收藏「${iptv.name}」'
                                      : '已取消收藏「${iptv.name}」'),
                                  duration: const Duration(milliseconds: 1200),
                                ));
                            });
                          },
                          itemBuilder: (context, position, isSelected) {
                            final iptv =
                                channelList.elementAtOrNull(position.row);
                            if (iptv == null) {
                              return _buildEmptyItem(
                                _showFavorites ? '还没有收藏频道' : '此分类下暂无频道',
                                isSelected,
                                isFocused: _channelFocusNode.hasFocus,
                                unselectedFill: AppTheme.channelMenuTileFill,
                              );
                            }
                            return _buildIptvItem(
                              iptv,
                              isSelected,
                              isFocused: _channelFocusNode.hasFocus,
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      });
    });
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(
        left: _isCompact ? 10.w : 12.w,
        bottom: _isCompact ? 4.h : 8.h,
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          title,
          style: AppTheme.text(AppTheme.fg(context), _isCompact ? 16.sp : 24.sp,
              weight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildTile({
    required bool isSelected,
    required bool isFocused,
    required Color unselectedFill,
    required Widget child,
  }) {
    final showFocus = isSelected && isFocused;
    return Transform.translate(
      offset: showFocus ? const Offset(0, -2) : Offset.zero,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _isCompact ? 8.w : 12.w,
          vertical: _isCompact ? 4.h : 8.h,
        ),
        decoration: BoxDecoration(
          color: unselectedFill,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color:
                showFocus ? AppTheme.iptvMenuFocusOutline : Colors.transparent,
            width: _isCompact ? 2 : 3,
          ),
          // 白色柔光模拟轻微悬浮，不增加深色阴影或实心选中底色。
          boxShadow: showFocus
              ? const [
                  BoxShadow(
                    color: Color(0x33FFFFFF),
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }

  Widget _buildCategoryItem({
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isFocused,
  }) {
    return _buildTile(
      isSelected: isSelected,
      isFocused: isFocused,
      unselectedFill: AppTheme.categoryMenuTileFill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTheme.text(
                AppTheme.tileText(context, false), _isCompact ? 18.sp : 26.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: _isCompact ? 2.h : 3.h),
          Text(
            subtitle,
            style: AppTheme.text(AppTheme.tileTextFaded(context, false, 0.7),
                _isCompact ? 12.sp : 18.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isFocused,
  }) {
    return _buildTile(
      isSelected: isSelected,
      isFocused: isFocused,
      unselectedFill: AppTheme.categoryMenuTileFill,
      child: Row(
        children: [
          Icon(icon,
              color: AppTheme.tileText(context, false),
              size: _isCompact ? 18.sp : 24.sp),
          SizedBox(width: _isCompact ? 5.w : 8.w),
          Expanded(
            child: Text(
              label,
              style: AppTheme.text(AppTheme.tileText(context, false),
                  _isCompact ? 16.sp : 22.sp),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyItem(
    String message,
    bool isSelected, {
    required bool isFocused,
    required Color unselectedFill,
  }) {
    return _buildTile(
      isSelected: isSelected,
      isFocused: isFocused,
      unselectedFill: unselectedFill,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message,
          style: AppTheme.text(AppTheme.tileTextFaded(context, false, 0.75),
              _isCompact ? 15.sp : 22.sp),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildIptvItem(
    Iptv iptv,
    bool isSelected, {
    required bool isFocused,
  }) {
    final color = AppTheme.tileText(context, false);
    return _buildTile(
      isSelected: isSelected,
      isFocused: isFocused,
      unselectedFill: AppTheme.channelMenuTileFill,
      child: Row(
        children: [
          SizedBox(
            width: _isCompact ? 28.w : 38.w,
            child: Text(
              iptv.channel.toString(),
              textAlign: TextAlign.center,
              style: AppTheme.text(AppTheme.tileTextFaded(context, false, 0.75),
                  _isCompact ? 13.sp : 20.sp),
              maxLines: 1,
            ),
          ),
          SizedBox(width: _isCompact ? 6.w : 10.w),
          Observer(
            builder: (_) => Icon(
              iptvStore.isFavorite(iptv) ? Icons.star_rounded : Icons.live_tv,
              size: _isCompact ? 17.sp : 23.sp,
              color: iptvStore.isFavorite(iptv)
                  ? Colors.amber
                  : AppTheme.tileTextFaded(context, false, 0.65),
            ),
          ),
          SizedBox(width: _isCompact ? 6.w : 10.w),
          Expanded(
            child: Text(
              iptv.name,
              style: AppTheme.text(color, _isCompact ? 18.sp : 27.sp),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
