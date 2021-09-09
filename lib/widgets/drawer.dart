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
    Key? key,
    required this.route,
    this.icon = true,
    this.title,
    this.subtitle,
    this.onTap,
  }) : super(key: key);

  @override
  build(context) {
    final currentRoute = ModalRoute.of(context)!.settings.name;
    final pageRoute = pageRoutes[route]!;

    final name = title ?? pageRoute.title;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: ListTile(
        selected: currentRoute == route,
        leading: icon ? pageRoute.icon : null,
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: subtitle != null ? Text(subtitle!) : null,
        onTap: onTap ??
            () {
              if (currentRoute != route)
                Navigator.of(context).pushNamedAndRemoveUntil(
                  route,
                  (route) => false,
                );
            },
      ),
    );
  }
}

class PageDrawer extends StatelessWidget {
  const PageDrawer();

  @override
  build(context) {
    final theme = Theme.of(context);
    final selectedColor = theme.brightness.text;
    final selectedTileColor = theme.primaryColor.withAlpha(85);

    const clamping = ClampingScrollPhysics();

    final auth = FirebaseAuth.instance;

    return Drawer(
      child: ListTileTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        selectedColor: selectedColor,
        selectedTileColor: selectedTileColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                    const Divider(height: 8.0),
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
                      ? TextButtonTheme(
                          data: TextButtonThemeData(
                            style: TextButton.styleFrom(primary: Colors.white),
                          ),
                          child: MaterialBanner(
                            content:
                                const Text("A new version is now avaliable"),
                            leading: const Icon(Icons.update),
                            actions: [
                              TextButton(
                                child: const Text("UPDATE"),
                                onPressed: () => updater.update(),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                  DrawerListTile(
                    route: "/login",
                    onTap: () async {
                      await api.logout();
                      await auth.signOut();

                      Navigator.of(context).pushNamedAndRemoveUntil(
                        "/login",
                        (route) => false,
                      );
                    },
                  ),
                  const Divider(height: 8.0, indent: 8.0, endIndent: 8.0),
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
