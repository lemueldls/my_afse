import "package:flutter/material.dart";

/// A nicer way of displaying errors.
class ErrorCard extends StatelessWidget {
  final String error;

  const ErrorCard({required final this.error, final Key? key})
      : super(key: key);

  @override
  Widget build(final BuildContext context) => Card(
        child: ListTile(
          title: Text(error, style: const TextStyle(color: Colors.red)),
        ),
      );
}
