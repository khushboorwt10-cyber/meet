import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meet_easyy/bloc/meeting_room_bloc/service/host_service_meet_room.dart';
import 'package:meet_easyy/bloc/meeting_room_bloc/service/screen_share_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import '../../model/new_meeting_model.dart';
import '../../zego_engine/zego_service.dart';
import 'meeting_room_bloc.dart';
import 'model.dart';

class MeetingRoomScreen extends StatefulWidget {
  final MeetingModel2 meeting;

  const MeetingRoomScreen({
    super.key,
    required this.meeting,
  });

  @override
  State<MeetingRoomScreen> createState() => _MeetingRoomScreenState();
}

class _MeetingRoomScreenState extends State<MeetingRoomScreen> {

  Timer? _screenShareTimer;

  bool isRemoteScreenSharing = false;

  String sharedBy = "";

  Map<String, Widget?> remoteViews = {};
  Map<String, int> remoteViewIds = {};
  Widget? localViewWidget;
  List<String> remoteStreams = [];

  List<ParticipantModel> _waitingList = [];
  List<ParticipantModel> _participants = [];
  Duration _meetingDuration = Duration.zero;
  Timer? _timer;
  int? localViewID;
  Timer? _listRefreshTimer;
  @override
  void initState() {
    super.initState();

    _screenShareTimer =
        Timer.periodic(const Duration(seconds: 5), (_) async {
          try {
            final response =
            await ScreenShareService()
                .getScreenShareStatus(widget.meeting.roomId);

            if (!mounted) return;

            final isSharing = response?["isScreenSharing"] ?? false;

            final newSharedBy =
                response?["screenSharedBy"]?["name"] ?? "";

            if (isSharing != isRemoteScreenSharing ||
                newSharedBy != sharedBy) {

              setState(() {
                isRemoteScreenSharing = isSharing;
                sharedBy = newSharedBy;
              });
            }

          } catch (e) {
            debugPrint("Screen share status error: $e");
          }
        });
    _participants.add(
      ParticipantModel(
        userId: widget.meeting.userId,
        name: widget.meeting.userName,
        isLocal: true,
      ),
    );

    _listRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _refreshParticipantList();
    });

    _initMeeting();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _meetingDuration += const Duration(seconds: 1);
      });
    });
  }
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    final h = twoDigits(duration.inHours);
    final m = twoDigits(duration.inMinutes.remainder(60));
    final s = twoDigits(duration.inSeconds.remainder(60));

    return "$h:$m:$s";
  }
  void _removeUser({required String userId}) {
    setState(() {
      _participants.removeWhere((p) => p.userId == userId);
      remoteStreams.removeWhere((s) => s.contains(userId));
    });
  }
  void _transferHost({required String userId}) {
    setState(() {
      for (int i = 0; i < _participants.length; i++) {
        if (_participants[i].userId == userId) {
          _participants[i] = ParticipantModel(
            userId: _participants[i].userId,
            name: _participants[i].name,
            isLocal: false,
          );
        }
      }
    });
  }
  Future<void> _startScreenSharing() async {
    await ZegoExpressEngine.instance.startPublishingStream(
      "screen_${widget.meeting.roomId}",
      config: ZegoPublisherConfig(),
      channel: ZegoPublishChannel.Aux,
    );
  }
  bool get isHostUser {
    return _participants.any((p) =>
    p.userId == widget.meeting.userId && widget.meeting.isHost
    );
  }
  void _toggleMuteUser(ParticipantModel user) {
    setState(() {
      user.isMuted = !user.isMuted;
    });
  }
  void _initMeeting() async {
    await ZegoEngineService.initEngine();

    await [
      Permission.camera,
      Permission.microphone,
    ].request();

    localViewWidget = await ZegoExpressEngine.instance.createCanvasView((viewID) {
      localViewID = viewID;
    });

    setState(() {});

    await ZegoExpressEngine.instance.loginRoom(
      widget.meeting.roomId,
      ZegoUser(widget.meeting.userId, widget.meeting.userName),
    );

    ZegoExpressEngine.onRoomStreamUpdate = (roomID, updateType, streamList, extendedData) async {

      if (updateType == ZegoUpdateType.Add) {
        for (var stream in streamList) {
          print("STREAM ID => ${stream.streamID}");
          debugPrint("USER ID => ${stream.user.userID}");
          debugPrint("USER NAME => ${stream.user.userName}");
          Widget? view = await ZegoExpressEngine.instance.createCanvasView((viewID) async {
            remoteViewIds[stream.streamID] = viewID;
            await ZegoExpressEngine.instance.startPlayingStream(
              stream.streamID,
              canvas: ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill),
            );
          });

          print("STREAM ID => ${stream.streamID}");

          remoteViews[stream.streamID] = view;

          if (!remoteStreams.contains(stream.streamID)) {
            remoteStreams.add(stream.streamID);
          }

          if (stream.streamID.startsWith("screen_")) {
            remoteStreams.remove(stream.streamID);
            remoteStreams.insert(0, stream.streamID);
          }

            setState(() {});
            continue;
          }

          print("REMOTE STREAMS => $remoteStreams");

          setState(() {});
          setState(() {});
          setState(() {});


      } else {
        for (var stream in streamList) {
          if (remoteViewIds.containsKey(stream.streamID)) {
            await ZegoExpressEngine.instance.stopPlayingStream(stream.streamID);
            await ZegoExpressEngine.instance.destroyCanvasView(remoteViewIds[stream.streamID]!);
          }
          remoteViewIds.remove(stream.streamID);
          remoteViews.remove(stream.streamID);
          setState(() {});
        }
      }
    };

    if (localViewID != null) {
      await ZegoExpressEngine.instance.startPreview(
        canvas: ZegoCanvas(localViewID!, viewMode: ZegoViewMode.AspectFill),
      );
    }

    await ZegoExpressEngine.instance.startPublishingStream(
      "stream_${DateTime.now().millisecondsSinceEpoch}",
    );
  }
  Future<void> _refreshParticipantList() async {
    try {
      final list = await HostService().getWaitingParticipants(widget.meeting.roomId);

      List<ParticipantModel> allUsers = (list as List).map((e) => ParticipantModel.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          _waitingList = allUsers.where((p) => p.status == 'waiting').toList();
          _participants = allUsers
              .where((p) => p.status == 'active')
              .map((p) => ParticipantModel(
            userId: p.userId,
            name: p.name,
            status: p.status,
            isLocal: p.userId == widget.meeting.userId,
            isMuted: p.isMuted,
            isVideoOff: p.isVideoOff,
          ))
              .toList();
          // Host check
          if (!_participants.any((p) => p.userId == widget.meeting.userId)) {
            _participants.insert(
              0,
              ParticipantModel(
                userId: widget.meeting.userId,
                name: widget.meeting.userName,
                isLocal: true,

              ),
            );

          }
        });
      }
    } catch (e) {
      debugPrint("Refresh Error: $e");
    }
  }
  @override
  void dispose() {
    _timer?.cancel();
    _screenShareTimer?.cancel();
    _listRefreshTimer?.cancel();
    ZegoExpressEngine.instance.stopPreview();
    ZegoExpressEngine.instance.stopPublishingStream();
    ZegoExpressEngine.instance.logoutRoom(
      widget.meeting.roomId,
    );
    if (localViewID != null) {
      ZegoExpressEngine.instance.destroyCanvasView(
        localViewID!,
      );
    }
    ZegoExpressEngine.destroyEngine();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MeetingBloc, MeetingState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const Icon(Icons.security, color: Colors.greenAccent, size: 20),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("UI/UX Design Session", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                "${formatDuration(_meetingDuration)} • ${_participants.length} Participants",
               style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(state.isRecording ? Icons.stop_circle : Icons.fiber_manual_record, color: state.isRecording ? Colors.red : Colors.white),
                onPressed: () => context.read<MeetingBloc>().add(ToggleRecording()),
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          body: Column(
            children: [

              if (isRemoteScreenSharing && sharedBy.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  color: Colors.green,
                  child: Text(
                    "$sharedBy is sharing screen",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),

                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),

                    itemCount: _participants.length + remoteStreams.length,

                    itemBuilder: (context, index) {

                      final hasScreenShare =
                          remoteStreams.isNotEmpty &&
                              remoteStreams.first.startsWith("screen_");

                      /// SCREEN SHARE TILE
                      if (hasScreenShare && index == 0) {
                        final streamID = remoteStreams.first;

                        return SizedBox(
                          width: double.infinity,
                          child: remoteViews[streamID] ??
                              const Center(
                                child: CircularProgressIndicator(),
                              ),
                        );
                      }

                      final participantIndex =
                      hasScreenShare ? index - 1 : index;

                      /// LOCAL + PARTICIPANTS
                      if (participantIndex >= 0 &&
                          participantIndex < _participants.length) {

                        final participant =
                        _participants[participantIndex];

                        return _buildVideoTile(
                          name: participant.isLocal
                              ? (widget.meeting.isHost
                              ? "${participant.name} (Host)"
                              : participant.name)
                              : participant.name,
                          isMuted: participant.isLocal
                              ? state.isMuted
                              : participant.isMuted,
                          isVideoOff: participant.isLocal
                              ? state.isCamOff
                              : participant.isVideoOff,
                          isLocal: participant.isLocal,
                          avatarColor: Colors.blueAccent,
                        );
                      }

                      /// REMOTE STREAM INDEX
                      int remoteIndex =
                          participantIndex - _participants.length;

                      if (hasScreenShare) {
                        remoteIndex += 1;
                      }

                      /// SAFETY CHECK
                      if (remoteIndex < 0 ||
                          remoteIndex >= remoteStreams.length) {
                        return const SizedBox.shrink();
                      }

                      final streamID = remoteStreams[remoteIndex];

                      return _buildVideoTile(
                          name: "Participant",
                          isMuted: false,
                          isVideoOff: false,
                          isLocal: false,
                          avatarColor: Colors.purpleAccent,
                          videoView: remoteViews[streamID],
                      );

                    },
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: const BoxDecoration(color: Color(0xFF262626), borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildControlButton(
                      icon: state.isMuted ? Icons.mic_off : Icons.mic,
                      color: state.isMuted ? Colors.redAccent : Colors.white24,
                      iconColor: Colors.white,
                      onPressed: () => context.read<MeetingBloc>().add(ToggleMic())),
                  _buildControlButton(
                      icon: state.isCamOff ? Icons.videocam_off : Icons.videocam,
                      color: state.isCamOff ? Colors.redAccent : Colors.white24,
                      iconColor: Colors.white,
                      onPressed: () => context.read<MeetingBloc>().add(ToggleCam())),
                  _buildControlButton(
                    icon: Icons.screen_share,
                    color: state.isScreenSharing
                        ? Colors.green
                        : Colors.white24,
                    iconColor: Colors.white,
                    onPressed: () {
                      context
                          .read<MeetingBloc>()
                          .add(ToggleScreenShare());
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.cameraswitch,
                    color: Colors.white24,
                    iconColor: Colors.white,
                    onPressed: () {
                      context
                          .read<MeetingBloc>()
                          .add(
                        SwitchCamera(),
                      );
                    },
                  ),
                  _buildControlButton(icon: Icons.people, color: Colors.white24, iconColor: Colors.white, onPressed: _showParticipantsSheet),
                  _buildControlButton(icon: Icons.call_end, color: Colors.red, iconColor: Colors.white, isEndCall: true, onPressed: () async {

                    await ZegoExpressEngine.instance
                        .stopPreview();

                    await ZegoExpressEngine.instance
                        .stopPublishingStream();
                    await ZegoExpressEngine.instance.logoutRoom(
                      widget.meeting.roomId,
                    );

                    if(context.mounted){
                      Navigator.pop(context);
                    }
                  },),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  void _showParticipantsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF262626),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: Text("Participants", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 20),

              // WAITING ROOM SECTION
              if (_waitingList.isNotEmpty) ...[
                const Text("Waiting Room", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _waitingList.length,
                    itemBuilder: (_, index) {
                      final participant = _waitingList[index]; // Assuming list of objects
                      return ListTile(
                        leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.pending, size: 16)),
                        title: Text(participant.name, style: const TextStyle(color: Colors.white)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                              onPressed: () async {
                                bool success = await HostService().admitUser(widget.meeting.roomId, participant.userId);
                                if (success) {
                                  await _refreshParticipantList(); // Turant list refresh karein
                                  setModalState(() {}); // UI update karein
                                }
                              },
                            ),
                            // REJECT BUTTON
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.redAccent),
                              onPressed: () async {
                                bool success = await HostService().rejectUser(widget.meeting.roomId, participant.userId);
                                if (success) {
                                  setModalState(() {
                                    _waitingList.removeAt(index);
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              const Divider(color: Colors.white24),
              const Text("In Meeting", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),

              // IN MEETING SECTION
              Expanded(
                child: ListView.builder(
                  itemCount: _participants.length,
                  itemBuilder: (_, index) => ListTile(
                    leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Text(_participants[index].name[0].toUpperCase(), style: const TextStyle(color: Colors.white))
                    ),
                    title: Text(_participants[index].name, style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoTile({
    required bool isLocal,
    required String name,
    required bool isMuted,
    required bool isVideoOff,
    required Color avatarColor,
    Widget? videoView,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          if (!isVideoOff)
        Positioned.fill(
    child: isLocal
    ? (localViewWidget ??
      Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    ))
        : (videoView ??
    Container(
    color: Colors.black,
    child: const Center(
    child: Text(
    "Waiting User...",
    style: TextStyle(color: Colors.white),
    ),
    ),
    )
    ),
    )
    else
    Center(
    child: CircleAvatar(
    radius: 35,
    backgroundColor: avatarColor,
    child: Text(
      name.isNotEmpty ? name[0] : "?",
    style: const TextStyle(
    fontSize: 28,
    color: Colors.white,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    ),

          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [

                // LEFT SIDE NAME
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),

                // RIGHT SIDE MIC ICON
                Row(
                  children: [

                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isMuted ? Colors.red : Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isMuted ? Icons.mic_off : Icons.mic,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),

                    // ✅ HOST MENU ONLY FOR HOST & NOT SELF
                    if (widget.meeting.isHost && !isLocal)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == "mute") {
                            _toggleMuteUser(
                              ParticipantModel(
                                userId: name,
                                name: name,
                              ),
                            );
                          }

                          if (value == "remove") {
                            _removeUser(userId: name);
                          }

                          if (value == "host") {
                            _transferHost(userId: name);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: "mute",
                            child: Text("Mute/Unmute"),
                          ),
                          PopupMenuItem(
                            value: "remove",
                            child: Text("Remove User"),
                          ),
                          PopupMenuItem(
                            value: "host",
                            child: Text("Make Host"),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
    ]),
    );
  }

  Widget _buildControlButton({required IconData icon, required Color color, required Color iconColor, required VoidCallback onPressed, bool isEndCall = false}) {
    return InkWell(onTap: onPressed, borderRadius: BorderRadius.circular(100), child: Container(width: isEndCall ? 60 : 50, height: isEndCall ? 60 : 50, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: isEndCall ? 28 : 22)));
  }
}