import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/widgets/general/custom_tooltip.dart';

class GraphIndicator extends StatelessWidget {
  const GraphIndicator({
    Key? key,
    required this.color,
    required this.title,
  }) : super(key: key);

  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          color: color,
          width: 15,
          height: 8,
        ),
        const SizedBox(
          width: 5,
        ),
        SizedBox(
          width: 100,
          child: CustomTooltip(
            message: title,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
