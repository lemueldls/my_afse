import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";

import "../extensions/brightness.dart";
import "../utils/api.dart" as api;
import "../utils/routes.dart";
import "../utils/student.dart";
import "../utils/updater.dart" as updater;

class DrawerListTile extends StatelessWidget {
  final String route;
  final bool icon;
  final String? title;
  final String? subtitle;
  final GestureTapCallback? onTap;

  const DrawerListTile({
    final Key? key,
    required final this.route,
    final this.icon = true,
    final this.title,
    final this.subtitle,
    final this.onTap,
  }) : super(key: key);

  @override
  build(final context) {
    final currentRoute = ModalRoute.of(context)!.settings.name;
    final pageRoute = pageRoutes[route]!;

    final name = title ?? pageRoute.title;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        selected: currentRoute == route,
        leading: icon ? pageRoute.icon : null,
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        onTap: onTap ??
            () {
              if (currentRoute != route)
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  route,
                  (final route) => false,
                );
            },
      ),
    );
  }
}

class PageDrawer extends StatelessWidget {
  const PageDrawer({final Key? key}) : super(key: key);

  @override
  build(final context) {
    final theme = Theme.of(context);
    final selectedColor = theme.brightness.text;
    final selectedTileColor = theme.primaryColor.withAlpha(85);
    final contrast = theme.primaryColorBrightness.text;

    const clamping = ClampingScrollPhysics();

    final auth = FirebaseAuth.instance;

    return Drawer(
      child: ListTileTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        selectedColor: selectedColor,
        selectedTileColor: selectedTileColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  physics: clamping,
                  children: [
                    DrawerListTile(
                      route: "/profile",
                      title: "${student.firstName} ${student.lastName}",
                      subtitle: student.email,
                      icon: false,
                    ),
                    const Divider(height: 8),
                    const DrawerListTile(route: "/home"),
                    const DrawerListTile(route: "/schedule"),
                    const DrawerListTile(route: "/grades"),
                    const DrawerListTile(route: "/attendance"),
                  ],
                ),
              ),
              ListView(
                shrinkWrap: true,
                physics: clamping,
                children: [
                  updater.prompt
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: TextButtonTheme(
                            data: TextButtonThemeData(
                              style: TextButton.styleFrom(primary: contrast),
                            ),
                            child: MaterialBanner(
                              contentTextStyle: TextStyle(color: contrast),
                              content:
                                  const Text("A new version is now avaliable"),
                              leading: Icon(Icons.download, color: contrast),
                              actions: [
                                TextButton(
                                  child: const Text("UPDATE"),
                                  onPressed: () => updater.update(),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  DrawerListTile(
                    route: "/login",
                    onTap: () => showDialog(
                      context: context,
                      builder: (final context) {
                        final navigator = Navigator.of(context);

                        return AlertDialog(
                          title: const Text("Are you sure you want to logout?"),
                          actions: [
                            TextButton(
                                onPressed: () => navigator.pop(),
                                child: const Text("NO")),
                            TextButton(
                              onPressed: () async {
                                await api.logout();
                                await auth.signOut();

                                navigator.pushNamedAndRemoveUntil(
                                  "/login",
                                  (final route) => false,
                                );
                              },
                              child: const Text("YES"),
                            )
                          ],
                        );
                      },
                    ),
                  ),
                  const Divider(height: 8, indent: 8, endIndent: 8),
                  const DrawerListTile(route: "/settings")
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
