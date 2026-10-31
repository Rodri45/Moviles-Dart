import 'package:flutter/material.dart';

class HeaderScrollView extends StatefulWidget {
  const HeaderScrollView({
    super.key,
    required this.header,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.onRefresh,
  });

  static const minHeightForFixedHeader = 560.0;

  static bool isShort(BuildContext context) =>
      MediaQuery.sizeOf(context).height < minHeightForFixedHeader;

  final Widget header;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final Future<void> Function()? onRefresh;

  @override
  State<HeaderScrollView> createState() => _HeaderScrollViewState();
}

class _HeaderScrollViewState extends State<HeaderScrollView> {
  final _headerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final short = HeaderScrollView.isShort(context);
    final header = KeyedSubtree(key: _headerKey, child: widget.header);

    Widget list = CustomScrollView(
      slivers: [
        if (short) SliverToBoxAdapter(child: header),
        SliverPadding(
          padding: widget.padding,
          sliver: SliverList.list(children: widget.children),
        ),
      ],
    );
    final onRefresh = widget.onRefresh;
    if (onRefresh != null) {
      list = RefreshIndicator(onRefresh: onRefresh, child: list);
    }

    if (short) return list;
    return Column(
      children: [
        header,
        Expanded(child: list),
      ],
    );
  }
}
