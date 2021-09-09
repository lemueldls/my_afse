library my_afse.routes;

import "package:flutter/material.dart";

import "../pages/attendance.dart";
import "../pages/grades.dart";
import "../pages/home.dart";
import "../pages/login.dart";
import "../pages/profile.dart";
import "../pages/schedule.dart";
import "../pages/settings.dart";

const pageRoutes = {
  "/profile": PageRoute(
    title: "Profile",
    page: ProfilePage(),
    icon: Icon(Icons.person),
  ),
  "/home": PageRoute(
    title: "Home",
    page: HomePage(),
    icon: Icon(Icons.home),
  ),
  "/schedule": PageRoute(
    title: "Schedule",
    page: SchedulePage(),
    icon: Icon(Icons.schedule),
  ),
  "/grades": PageRoute(
    title: "Grades",
    page: GradesPage(),
    icon: Icon(Icons.grade),
  ),
  "/attendance": PageRoute(
    title: "Attendance",
    page: AttendancePage(),
    icon: Icon(Icons.event_available),
  ),
  "/login": PageRoute(
    title: "Logout",
    page: LoginPage(),
    icon: Icon(Icons.logout),
    wrap: false,
  ),
  "/settings": PageRoute(
    title: "Settings",
    page: SettingsPage(),
    icon: Icon(Icons.settings),
  ),
};

class PageRoute {
  final String title;
  final Widget page;
  final Icon? icon;
  final bool wrap;

  const PageRoute({
    required this.title,
    required this.page,
    this.icon,
    this.wrap = true,
  });
}
