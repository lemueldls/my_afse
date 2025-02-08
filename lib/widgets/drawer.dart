import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";

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
    required this.route,
    this.icon = true,
    this.title,
    this.subtitle,
    this.onTap,
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    final currentRoute = ModalRoute.of(context)!.settings.name;
    final pageRoute = pageRoutes[route]!;

    final name = title ?? pageRoute.title;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        selected: currentRoute == route,
        leading: icon ? pageRoute.icon : null,
        title: Text(name),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        onTap: onTap ??
            () {
              if (currentRoute != route)
                Navigator.of(context).pushNamedAndRemoveUntil(
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
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    const clampingScroll = ClampingScrollPhysics();

    return Drawer(
      // width: 360,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: ListTileTheme(
        // horizontalTitleGap: 0,
        iconColor: colorScheme.onSecondaryContainer,
        textColor: colorScheme.onSecondaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ListView(
                  shrinkWrap: true,
                  physics: clampingScroll,
                  children: [
                    DrawerListTile(
                      route: "/profile",
                      title: "${student.firstName} ${student.lastName}",
                      subtitle: student.email,
                      icon: false,
                    ),
                    const DrawerDivider(),
                    const DrawerListTile(route: "/home"),
                    const DrawerListTile(route: "/schedule"),
                    const DrawerListTile(route: "/grades"),
                    const DrawerListTile(route: "/attendance"),
                  ],
                ),
              ),
            ),
            ListView(
              shrinkWrap: true,
              physics: clampingScroll,
              children: [
                if (updater.prompt)
                  MaterialBanner(
                    backgroundColor: colorScheme.secondary,
                    contentTextStyle: TextStyle(
                      color: colorScheme.onSecondary,
                    ),
                    content: const Text("A new version is now available"),
                    leading: Icon(
                      Icons.download,
                      color: colorScheme.onSecondary,
                    ),
                    actions: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.onSecondary,
                        ),
                        onPressed: updater.update,
                        child: const Text("Update"),
                      ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      DrawerListTile(
                        route: "/login",
                        onTap: () => _logout(context),
                      ),
                      const DrawerDivider(),
                      const DrawerListTile(route: "/settings"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(final BuildContext context) async => showDialog(
        context: context,
        builder: (final context) {
          final navigator = Navigator.of(context);

          return AlertDialog(
            title: const Text("Are you sure you want to logout?"),
            actions: [
              TextButton(onPressed: navigator.pop, child: const Text("No")),
              TextButton(
                onPressed: () async {
                  await api.logout();
                  await FirebaseAuth.instance.signOut();

                  await navigator.pushNamedAndRemoveUntil(
                    "/login",
                    (final route) => false,
                  );
                },
                child: const Text("Yes"),
              ),
            ],
          );
        },
      );
}

class DrawerDivider extends StatelessWidget {
  const DrawerDivider({
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) => Divider(
        height: 12,
        indent: 16,
        endIndent: 16,
        color: Theme.of(context).colorScheme.outline,
      );
}
