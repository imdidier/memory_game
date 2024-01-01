import 'package:flutter/material.dart';
import 'package:huts_web/core/utils/ui/ui_variables.dart';
import 'package:huts_web/features/messages/data/models/message_job.dart';
import 'package:huts_web/features/messages/display/provider/messages_provider.dart';
import 'package:provider/provider.dart';

class JobItem extends StatelessWidget {
  final int jobIndex;
  const JobItem({required this.jobIndex, super.key, required this.isDesktop});
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    MessagesProvider provider = Provider.of<MessagesProvider>(context);
    MessageJob messageJob = provider.jobsList[jobIndex];
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(offset: Offset(0, 2), color: Colors.black12, blurRadius: 2)
        ],
      ),
      child: OverflowBar(
        spacing: 5,
        overflowSpacing: 1,
        alignment: MainAxisAlignment.spaceBetween,
        overflowAlignment: OverflowBarAlignment.center,
        children: [
          Text(
            messageJob.name,
            maxLines: 3,
            style: TextStyle(fontSize: isDesktop ? 14 : 11),
          ),
          Checkbox(
            activeColor: UiVariables.primaryColor,
            value: messageJob.isSelected,
            onChanged: (bool? newValue) =>
                provider.selectJob(jobIndex, newValue ?? false),
          )
        ],
      ),
    );
  }
}
