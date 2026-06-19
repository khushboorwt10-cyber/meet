import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meet_easyy/bloc/meeting_room_bloc/service/screen_share_service.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

///--------------Event-------------
abstract class MeetingEvent {}
class ToggleMic extends MeetingEvent {}
class ToggleCam extends MeetingEvent {}
class ToggleHand extends MeetingEvent {}
class ToggleRecording extends MeetingEvent {}
class ToggleScreenShare extends MeetingEvent {}

class SwitchCamera extends MeetingEvent {}

///-----------State----------------

class MeetingState {
  final bool isMuted;
  final bool isCamOff;
  final bool isHandRaised;
  final bool isRecording;

  final bool isScreenSharing;
  final bool isFrontCamera;

  MeetingState({
    this.isMuted = false,
    this.isCamOff = false,
    this.isHandRaised = false,
    this.isRecording = false,
    this.isScreenSharing = false,
    this.isFrontCamera = true,
  });

  MeetingState copyWith({
    bool? isMuted,
    bool? isCamOff,
    bool? isHandRaised,
    bool? isRecording,
    bool? isScreenSharing,
    bool? isFrontCamera,
  }) {
    return MeetingState(
      isMuted: isMuted ?? this.isMuted,
      isCamOff: isCamOff ?? this.isCamOff,
      isHandRaised: isHandRaised ?? this.isHandRaised,
      isRecording: isRecording ?? this.isRecording,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
    );
  }
}
///-----------------Bloc------------
class MeetingBloc extends Bloc<MeetingEvent, MeetingState> {
  final String roomId;
  final ScreenShareService _screenShareService =
  ScreenShareService();

  ZegoScreenCaptureSource? _screenSource;

  MeetingBloc({
    required this.roomId,
  }) : super(MeetingState()) {

    on<ToggleMic>((event, emit) {
      bool newState = !state.isMuted;
      ZegoExpressEngine.instance.muteMicrophone(newState);
      emit(state.copyWith(isMuted: newState));
    });

    on<ToggleCam>((event, emit) {
      bool newState = !state.isCamOff;
      ZegoExpressEngine.instance.enableCamera(!newState);
      emit(state.copyWith(isCamOff: newState));
    });
    on<ToggleScreenShare>((event, emit) async {
      bool newState = !state.isScreenSharing;

      try {
        /// ================= START SCREEN SHARE =================
        if (newState) {

          bool apiSuccess =
          await _screenShareService.startScreenShare(roomId);

          if (!apiSuccess) {
            print("❌ Start API failed");
            return;
          }

          _screenSource =
          await ZegoExpressEngine.instance.createScreenCaptureSource();

          await _screenSource!.startCapture();

          await ZegoExpressEngine.instance.setVideoSource(
            ZegoVideoSourceType.ScreenCapture,
            channel: ZegoPublishChannel.Aux,
          );

          await ZegoExpressEngine.instance.startPublishingStream(
            "screen_${DateTime.now().millisecondsSinceEpoch}",
            channel: ZegoPublishChannel.Aux,
          );
        }

        /// ================= STOP SCREEN SHARE =================
        else {

          /// 🔥 ADD API CALL HERE (IMPORTANT FIX)
          bool apiSuccess =
          await _screenShareService.stopScreenShare(roomId);

          if (!apiSuccess) {
            print("❌ Stop API failed");
            return;
          }

          await ZegoExpressEngine.instance.stopPublishingStream(
            channel: ZegoPublishChannel.Aux,
          );

          await ZegoExpressEngine.instance.setVideoSource(
            ZegoVideoSourceType.Camera,
            channel: ZegoPublishChannel.Aux,
          );

          await _screenSource?.stopCapture();

          if (_screenSource != null) {
            await ZegoExpressEngine.instance
                .destroyScreenCaptureSource(_screenSource!);
          }

          _screenSource = null;
        }

        emit(state.copyWith(isScreenSharing: newState));

      } catch (e) {
        print("Screen share error => $e");
      }
    });
    on<SwitchCamera>((event, emit) async {
      bool newState = !state.isFrontCamera;
      await ZegoExpressEngine.instance.useFrontCamera(newState);
      emit(
        state.copyWith(
          isFrontCamera: newState,
        ),
      );
    });
    on<ToggleHand>((event, emit) => emit(state.copyWith(isHandRaised: !state.isHandRaised)));
    on<ToggleRecording>((event, emit) => emit(state.copyWith(isRecording: !state.isRecording)));
  }
}


