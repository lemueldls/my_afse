import "package:flutter/material.dart";

class ErrorCard extends StatelessWidget {
  final String error;

  const ErrorCard({final Key? key, required final this.error})
      : super(key: key);

  @override
  Widget build(final BuildContext context) => Card(
        child: ListTile(
          title: Text(error, style: const TextStyle(color: Colors.red)),
        ),
      );
}
