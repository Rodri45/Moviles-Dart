import 'package:flutter/material.dart';

/// Body of a screen with a header and a list below it.
///
/// On a tall screen the header stays fixed and only the list scrolls. On a
/// short one, like a phone in landscape, the header scrolls away with the
/// list, so the content keeps most of the height and nothing overflows.
///
/// The choice uses the height of the screen and not the space left by the
/// keyboard, so it does not change while the driver types. The header keeps
/// its state when the phone rotates, for example the text of a search field.
class HeaderScrollView extends StatefulWidget {
  const HeaderScrollView({
    super.key,
    required this.header,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.onRefresh,
  });

  /// Screens shorter than this scroll the header with the content.
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
