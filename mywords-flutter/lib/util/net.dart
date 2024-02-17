import 'dart:io';

Future<List<String>> getIPv4s() async {
  final networks = await NetworkInterface.list(type: InternetAddressType.IPv4);
  if (networks.isEmpty) [];
  List<String> ips = [];
  for (var i in networks) {
    for (var s in i.addresses) {
      ips.add(s.address);
    }
  }
  return ips;
}
