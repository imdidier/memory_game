import 'package:flutter/material.dart';

class CustomDropDown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String hintText;
  final Function onChange;

  const CustomDropDown({
    required this.value,
    required this.items,
    required this.hintText,
    required this.onChange,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      onTap: () => FocusScope.of(context).unfocus(),
      underline: const SizedBox(),
      value: value,
      isExpanded: true,
      menuMaxHeight: 300,
      items: items.map<DropdownMenuItem<String>>(
        (String value) {
          return DropdownMenuItem(
            value: value,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          );
        },
      ).toList(),
      onChanged: (String? newValue) => onChange(newValue),
    );
  }
}
