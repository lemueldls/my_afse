import "package:flutter/material.dart";

/// A nicer way of displaying errors.
class ErrorCard extends StatelessWidget {
  final String error;

  const ErrorCard({required final this.error, final Key? key})
      : super(key: key);

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.error,
      child: ListTile(
        textColor: colorScheme.onError,
        title: Text(error),
      ),
    );
  }
}
