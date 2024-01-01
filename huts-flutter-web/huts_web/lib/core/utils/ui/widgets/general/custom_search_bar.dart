import 'package:flutter/material.dart';
import 'package:huts_web/features/auth/domain/entities/screen_size_entity.dart';
import 'package:huts_web/features/general_info/display/providers/general_info_provider.dart';
import 'package:provider/provider.dart';

import '../../ui_variables.dart';

class CustomSearchBar extends StatefulWidget {
  final String hint;
  final Function onChange;
  const CustomSearchBar({required this.onChange, required this.hint, Key? key})
      : super(key: key);

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  TextEditingController textController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    ScreenSize screenSize =
        Provider.of<GeneralInfoProvider>(context, listen: false).screenSize;
    return Container(

      width: screenSize.blockWidth * 0.25,
      height: screenSize.height * 0.055,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 2),
            color: Colors.black26,
            blurRadius: 2,
          )
        ],
      ),
      child: TextField(
        controller: textController,
        cursorColor: UiVariables.primaryColor,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          suffixIcon: const Icon(Icons.search),
          hintText: widget.hint,
          hintStyle: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        onChanged: (String query) {
          widget.onChange(query.toLowerCase().trim());
        },
      ),
    );
  }
}
