import 'dart:io';
import 'package:flutter/material.dart';

Future<bool> isUsingVPN() async {
  try {
    List<NetworkInterface> interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.any,
    );

    for (NetworkInterface interface in interfaces) {
      String name = interface.name.toLowerCase();

      if (name.contains("tun") ||
          name.contains("tap") ||
          name.contains("ppp") ||
          name.contains("pptp")) {
        return true;
      }
    }

    return false;
  } catch (e) {
    debugPrint("e: $e");
    return false;
  }
}
