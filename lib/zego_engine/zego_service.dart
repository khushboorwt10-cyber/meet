import 'package:zego_express_engine/zego_express_engine.dart';

class ZegoEngineService {
  static const int appID = 1471134991;
  static const String appSign = "edc18a4fd49cd66fab2c3e47f21db0cd9f93d88af7385c20bf093ae47b584526";

  static Future<void> initEngine() async {
    ZegoEngineProfile profile = ZegoEngineProfile(
      appID,
      ZegoScenario.General,
      appSign: appSign,
    );
    await ZegoExpressEngine.createEngineWithProfile(profile);
  }
}