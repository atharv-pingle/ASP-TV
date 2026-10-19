import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/channel_service.dart';
import 'services/epg_service.dart';
import 'screens/tv_home_screen.dart';
import 'theme/tv_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force Landscape orientation for Smart TV & TV Boxes
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Hide system status bar on TV
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final channelService = ChannelService();
  await channelService.initialize();
  await EpgService.instance.initialize();

  runApp(ASPTVApp(channelService: channelService));
}

class ASPTVApp extends StatelessWidget {
  final ChannelService channelService;

  const ASPTVApp({Key? key, required this.channelService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASP TV',
      debugShowCheckedModeBanner: false,
      theme: TVTheme.theme,
      home: TVHomeScreen(channelService: channelService),
    );
  }
}
