import "package:flutter/material.dart";

import "../utils/constants.dart";
import "../utils/updater.dart" as updater;
import "drawer.dart";

class PageScaffold extends StatelessWidget {
  final String title;
  final Widget page;

  const PageScaffold({
    required this.title,
    required this.page,
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    if (isProduction) _checkUpdates(context);

    final scaffoldKey = LabeledGlobalKey<ScaffoldState>("Scaffold");

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(title: Text(title)),
      drawer: const PageDrawer(),
      drawerEdgeDragWidth: 40,
      body: WillPopScope(
        onWillPop: () async {
          final scaffoldState = scaffoldKey.currentState!;

          // Use the back button to open and close the drawer.
          if (scaffoldState.isDrawerOpen)
            Navigator.of(context).pop();
          else
            scaffoldState.openDrawer();

          return false;
        },
        child: page,
      ),
    );
  }

  /// Show a snackbar popup when there's a new update.
  Future<void> _checkUpdates(final BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    await updater.checkLatest();

    if (!updater.prompt || updater.dismissed) return;

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: colorScheme.inverseSurface,
        content: Text(
          "A new version is now available",
          style: TextStyle(color: colorScheme.onInverseSurface),
        ),
        behavior: SnackBarBehavior.floating,
        onVisible: () => updater.dismissed = true,
        action: SnackBarAction(
          label: "UPDATE",
          textColor: colorScheme.inversePrimary,
          onPressed: updater.update,
        ),
      ),
    );
  }
}
