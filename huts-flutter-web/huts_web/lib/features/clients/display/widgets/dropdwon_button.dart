import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../auth/domain/entities/screen_size_entity.dart';
import '../../../general_info/display/providers/general_info_provider.dart';

class DropDwonButton extends StatefulWidget {
  final ScreenSize screenSize;

  final String text;
  final List<Map<String, dynamic>> itemsSelected;
  final bool isCountry;
  const DropDwonButton(
      {super.key,
      required this.text,
      required this.itemsSelected,
      required this.isCountry,
      required this.screenSize});

  @override
  State<DropDwonButton> createState() => _DropDwonButtonState();
}

class _DropDwonButtonState extends State<DropDwonButton> {
  late ScreenSize screenSize;

  Map<String, dynamic> selectedSubtype = {
    "name": "Operaciones",
    "key": "operations"
  };

  Map<String, dynamic> selectedCountry = {"name": "Costa Rica", "key": "CR"};
  bool isDesktop = false;
  @override
  Widget build(BuildContext context) {
    screenSize = Provider.of<GeneralInfoProvider>(context).screenSize;
    isDesktop = screenSize.width >= 1120;
    String text = widget.text;
    List<Map<String, dynamic>> itemsSelected = widget.itemsSelected;
    bool isCountry = widget.isCountry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: isDesktop ? 14 : 11,
            color: Colors.grey,
          ),
        ),
        Container(
          width: screenSize.blockWidth >= 920
              ? screenSize.blockWidth * 0.28
              : screenSize.blockWidth,
          height: screenSize.blockWidth >= 920
              ? screenSize.height * 0.055
              : screenSize.height * 0.04,
          margin: EdgeInsets.only(
            top: screenSize.height * 0.01,
            bottom: screenSize.height * 0.02,
          ),
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
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: DropdownButton<String>(
              isExpanded: true,
              hint: Text(
                text,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: screenSize.blockWidth >= 920 ? 12 : 10,
                ),
              ),
              menuMaxHeight: 200,
              underline: const SizedBox(),
              value:
                  isCountry ? selectedCountry["name"] : selectedSubtype["name"],
              items: itemsSelected
                  .map(
                    (e) => DropdownMenuItem<String>(
                      value: e["name"],
                      child: Text(
                        e["name"],
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: screenSize.blockWidth >= 920 ? 14 : 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                setState(() {
                  isCountry
                      ? selectedCountry = itemsSelected.firstWhere(
                          (element) => element["name"] == value,
                        )
                      : selectedSubtype = itemsSelected
                          .firstWhere((element) => element["name"] == value);
                });
              },
            ),
          ),
        )
      ],
    );
  }
}
