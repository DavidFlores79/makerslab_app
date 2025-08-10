import 'package:flutter/material.dart';

import 'px_section_header.dart';

class PxGenericListSection<T> extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;
  final String? onViewAllLabel;
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget separator;
  final Axis scrollDirection;
  final EdgeInsetsGeometry padding;
  final double? height;

  const PxGenericListSection({
    super.key,
    required this.title,
    required this.onViewAll,
    required this.items,
    required this.itemBuilder,
    this.separator = const SizedBox(height: 10, width: 10),
    this.scrollDirection = Axis.horizontal,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.height,
    this.onViewAllLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          onViewAll: onViewAll,
          padding: padding,
          onViewAllLabel: onViewAllLabel,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: scrollDirection == Axis.horizontal ? height : null,
          child: ListView.separated(
            scrollDirection: scrollDirection,
            shrinkWrap: scrollDirection == Axis.vertical,
            physics:
                scrollDirection == Axis.vertical
                    ? const NeverScrollableScrollPhysics()
                    : null,
            padding: padding,
            itemCount: items.length,
            separatorBuilder: (_, __) => separator,
            itemBuilder: (context, index) => itemBuilder(context, items[index]),
          ),
        ),
      ],
    );
  }
}
