import 'package:flutter/material.dart';

class Screen404 extends StatelessWidget {
  const Screen404({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "404",
            style: TextStyle(color: Colors.black, fontSize: 35),
          ),
          const Text(
            "No se encontró la página",
            style: TextStyle(color: Colors.black, fontSize: 35),
          ),
          TextButton(
            child: const Text("Volver"),
            onPressed: () => Navigator.pushNamed(context, "/"),
          ),
        ],
      ),
    );
  }
}
