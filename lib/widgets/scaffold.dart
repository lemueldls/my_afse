import "package:flutter/material.dart";

import "../utils/updater.dart" as updater;
import "drawer.dart";

class PageScaffold extends StatelessWidget {
  final String title;
  final Widget page;

  const PageScaffold({
    required final this.title,
    required final this.page,
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    _checkUpdates(context);

    final _scaffoldKey = LabeledGlobalKey<ScaffoldState>("Scaffold");

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: Text(title)),
      drawer: const PageDrawer(),
      drawerEdgeDragWidth: 40,
      body: WillPopScope(
        onWillPop: () async {
          final scaffoldState = _scaffoldKey.currentState!;

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

    await updater.checkLatest();

    if (!updater.prompt || updater.dismissed) return;

    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(days: 1),
        content: const Text("A new version is now avaliable"),
        behavior: SnackBarBehavior.floating,
        onVisible: () => updater.dismissed = true,
        action: const SnackBarAction(
          label: "UPDATE",
          onPressed: updater.update,
        ),
      ),
    );
  }
}
