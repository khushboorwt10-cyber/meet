class MeetingSettings {
  bool isMicOn;
  bool isCameraOn;
  bool isScreenSharing;
  bool isRecording;

  MeetingSettings({this.isMicOn = true, this.isCameraOn = true, this.isScreenSharing = false, this.isRecording = false});
}
class Participant {
  final String name;
  final bool isLocal;

  bool isMuted;
  bool isVideoOff;

  Participant({
    required this.name,
    this.isLocal = false,
    this.isMuted = false,
    this.isVideoOff = false,
  });
}
