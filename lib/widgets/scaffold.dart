import "package:flutter/material.dart";

import "drawer.dart";

class PageScaffold extends StatelessWidget {
  final String title;
  final Widget page;

  const PageScaffold({
    Key? key,
    required this.title,
    required this.page,
  }) : super(key: key);

  @override
  build(context) {
    final _scaffoldKey = LabeledGlobalKey<ScaffoldState>("Scaffold");

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: Text(title)),
      drawer: const PageDrawer(),
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
}
