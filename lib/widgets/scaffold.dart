import "package:flutter/material.dart";

import "../utils/updater.dart" as updater;
import "drawer.dart";

class PageScaffold extends StatelessWidget {
  final String title;
  final Widget page;

  const PageScaffold({
    final Key? key,
    required final this.title,
    required final this.page,
  }) : super(key: key);

  @override
  build(final context) {
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

          if (scaffoldState.isDrawerOpen) {
            Navigator.pop(context);
          } else {
            scaffoldState.openDrawer();
          }

          return false;
        },
        child: page,
      ),
    );
  }

  Future<void> _checkUpdates(final BuildContext context) async {
    await updater.checkLatest();

    if (!updater.prompt || updater.dismissed) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("A new version is now avaliable"),
        behavior: SnackBarBehavior.floating,
        onVisible: () => updater.dismissed = true,
        action: SnackBarAction(
          label: "UPDATE",
          onPressed: () => updater.update(),
        ),
      ),
    );
  }
}
