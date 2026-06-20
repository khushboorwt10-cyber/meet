import 'dart:async';

import 'package:flutter/material.dart';
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

  const MeetingRoomScreen({super.key, required this.meeting});

  @override
  State<MeetingRoomScreen> createState() => _MeetingRoomScreenState();
}

class _MeetingRoomScreenState extends State<MeetingRoomScreen> {
  Timer? _screenShareTimer;

  bool isRemoteScreenSharing = false;

  String sharedBy = "";

  Map<String, Widget?> remoteViews = {};
  Map<String, int> remoteViewIds = {};
  Map<String, String> streamToUserMap = {}; 
  Map<String, String> userToStreamMap = {}; 
  Widget? localViewWidget;
  List<String> remoteStreams = [];

  List<ParticipantModel> _waitingList = [];

  List<ParticipantModel> participants = [];
  
  Duration _meetingDuration = Duration.zero;
  Timer? _timer;
  int? localViewID;
  Timer? _listRefreshTimer;
  bool _isLocalAdded = false;

  @override
  void initState() {
    super.initState();

    _screenShareTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final response = await ScreenShareService().getScreenShareStatus(
          widget.meeting.roomId,
        );

        if (!mounted) return;

        final isSharing = response?["isScreenSharing"] ?? false;
        final newSharedBy = response?["screenSharedBy"]?["name"] ?? "";

        if (isSharing != isRemoteScreenSharing || newSharedBy != sharedBy) {
          setState(() {
            isRemoteScreenSharing = isSharing;
            sharedBy = newSharedBy;
          });
        }
      } catch (e) {
        debugPrint("Screen share status error: $e");
      }
    });

    _addLocalParticipant();
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

  void _addLocalParticipant() {
    if (!_isLocalAdded) {
      setState(() {
        participants.add(
          ParticipantModel(
            userId: widget.meeting.userId,
            name: widget.meeting.userName,
            isLocal: true,
            status: 'active',
          ),
        );
        _isLocalAdded = true;
        print("✅ LOCAL ADDED: ${widget.meeting.userName}");
        print("✅ LOCAL USER ID: ${widget.meeting.userId}");
      });
    }
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
      participants.removeWhere((p) => p.userId == userId);
      // Remove all streams associated with this user
      final streamsToRemove = streamToUserMap.entries
          .where((e) => e.value == userId)
          .map((e) => e.key)
          .toList();
      
      for (var stream in streamsToRemove) {
        remoteStreams.removeWhere((s) => s == stream);
        streamToUserMap.remove(stream);
      }
      userToStreamMap.remove(userId);
    });
  }

  void _transferHost({required String userId}) {
    setState(() {
      for (int i = 0; i < participants.length; i++) {
        if (participants[i].userId == userId) {
          participants[i] = ParticipantModel(
            userId: participants[i].userId,
            name: participants[i].name,
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
    return participants.any(
      (p) => p.userId == widget.meeting.userId && widget.meeting.isHost,
    );
  }

  void _toggleMuteUser(ParticipantModel user) {
    setState(() {
      user.isMuted = !user.isMuted;
    });
  }

  void _initMeeting() async {
    await ZegoEngineService.initEngine();
    await [Permission.camera, Permission.microphone].request();

    localViewWidget = await ZegoExpressEngine.instance.createCanvasView((
      viewID,
    ) {
      localViewID = viewID;
    });

    setState(() {});

    // ✅ FIX: Ensure userId is not empty
    String userId = widget.meeting.userId;
    if (userId.isEmpty) {
      userId = "user_${DateTime.now().millisecondsSinceEpoch}";
      print("⚠️ UserId was empty, generated: $userId");
    }

    String userName = widget.meeting.userName;
    if (userName.isEmpty) {
      userName = "User";
    }

    await ZegoExpressEngine.instance.loginRoom(
      widget.meeting.roomId,
      ZegoUser(userId, userName),
    );

    ZegoExpressEngine.onRoomStreamUpdate =
        (roomID, updateType, streamList, extendedData) async {
      print("🔴 STREAM UPDATE: $updateType, Streams: ${streamList.length}");
      
      if (updateType == ZegoUpdateType.Add) {
        for (var stream in streamList) {
          print("🔴 NEW STREAM: ${stream.streamID}");
          print("🔴 USER ID: ${stream.user.userID}");
          print("🔴 USER NAME: ${stream.user.userName}");
          
          // ✅ STORE THE MAPPING WITH USER ID
          final streamUserId = stream.user.userID;
          if (streamUserId.isEmpty) {
            print("⚠️ WARNING: Stream has empty user ID: ${stream.streamID}");
            continue;
          }
          
          // ✅ SKIP LOCAL STREAM
         if (streamUserId.trim() ==
    widget.meeting.userId.trim()) {
  print("⏭️ Local Stream Ignored");
  continue;
}
          // ✅ UPDATE BOTH MAPPINGS
          streamToUserMap[stream.streamID] = streamUserId;
          userToStreamMap[streamUserId] = stream.streamID;
          
          print("🔗 Mapped: ${stream.streamID} -> $streamUserId");
          
          // ✅ CHECK IF PARTICIPANT EXISTS
          final exists = participants.any((p) => p.userId == streamUserId);
          
          if (!exists) {
            print("🟢 ADDING PARTICIPANT: ${stream.user.userName} (ID: $streamUserId)");
            setState(() {
              participants.add(
                ParticipantModel(
                  userId: streamUserId,
                  name: stream.user.userName ?? "User",
                  isLocal: false,
                  status: 'active',
                ),
              );
            });
          }

          // ✅ CREATE REMOTE VIEW FOR NON-SCREEN STREAMS
          if (!stream.streamID.startsWith("screen_")) {
            Widget? view = await ZegoExpressEngine.instance.createCanvasView((
              viewID,
            ) async {
              remoteViewIds[stream.streamID] = viewID;
              await ZegoExpressEngine.instance.startPlayingStream(
                stream.streamID,
                canvas: ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill),
              );
              print("🟢 STARTED PLAYING: ${stream.streamID}");
            });

            setState(() {
              remoteViews[stream.streamID] = view;
              if (!remoteStreams.contains(stream.streamID)) {
                remoteStreams.add(stream.streamID);
              }
              print("🟢 Remote view added for ${stream.streamID}");
            });
          }

          if (stream.streamID.startsWith("screen_")) {
            setState(() {
              remoteStreams.remove(stream.streamID);
              remoteStreams.insert(0, stream.streamID);
            });
          }

          setState(() {});
        }
      } else {
        // Handle stream removal
        for (var stream in streamList) {
          print("🔴 REMOVING STREAM: ${stream.streamID}");
          
          if (remoteViewIds.containsKey(stream.streamID)) {
            await ZegoExpressEngine.instance.stopPlayingStream(
              stream.streamID,
            );
            await ZegoExpressEngine.instance.destroyCanvasView(
              remoteViewIds[stream.streamID]!,
            );
          }
          
          setState(() {
            final userId = streamToUserMap[stream.streamID];
            streamToUserMap.remove(stream.streamID);
            remoteViewIds.remove(stream.streamID);
            remoteViews.remove(stream.streamID);
            remoteStreams.remove(stream.streamID);
            
            // Remove mapping for this user
            if (userId != null) {
              userToStreamMap.remove(userId);
            }
            
            // Remove participant if they left
            if (stream.user.userID.isNotEmpty) {
              participants.removeWhere((p) => p.userId == stream.user.userID);
            }
          });
        }
      }
    };

    if (localViewID != null) {
      await ZegoExpressEngine.instance.startPreview(
        canvas: ZegoCanvas(localViewID!, viewMode: ZegoViewMode.AspectFill),
      );
    }

    // ✅ START PUBLISHING LOCAL STREAM WITH VALID USER ID
    final localStreamId = "stream_${userId}_${DateTime.now().millisecondsSinceEpoch}";
    await ZegoExpressEngine.instance.startPublishingStream(localStreamId);
    
    // ✅ ADD LOCAL STREAM TO MAPPING
    setState(() {
      streamToUserMap[localStreamId] = userId;
      userToStreamMap[userId] = localStreamId;
    });
    
    print("✅ PUBLISHING STREAM: $localStreamId");
    print("✅ LOCAL USER ID IN STREAM: $userId");
  }

  Future<void> _refreshParticipantList() async {
    try {
      final list = await HostService().getWaitingParticipants(
        widget.meeting.roomId,
      );

      if (list.isEmpty) return;

      List<ParticipantModel> allUsers = [];
      try {
        allUsers = (list)
            .map((e) => ParticipantModel.fromJson(e))
            .toList();
      } catch (e) {
        print("Parse error: $e");
        return;
      }

      if (mounted) {
        setState(() {
          _waitingList = allUsers.where((p) => p.status == 'waiting').toList();
          
          final activeUsers = allUsers
              .where((p) => p.status == 'active')
              .toList();

          for (var apiUser in activeUsers) {

  // Local user already added hai
  if (apiUser.userId.trim() ==
      widget.meeting.userId.trim()) {
    continue;
  }

  final existingIndex = participants.indexWhere(
    (p) => p.userId == apiUser.userId,
  );

  if (existingIndex != -1) {
    participants[existingIndex] = ParticipantModel(
      userId: apiUser.userId,
      name: apiUser.name,
      status: apiUser.status,
      isLocal: false,
      isMuted: apiUser.isMuted,
      isVideoOff: apiUser.isVideoOff,
    );
  } else {
    participants.add(
      ParticipantModel(
        userId: apiUser.userId,
        name: apiUser.name,
        status: apiUser.status,
        isLocal: false,
        isMuted: apiUser.isMuted,
        isVideoOff: apiUser.isVideoOff,
      ),
    );
  }
}

          final localIndex = participants.indexWhere(
            (p) => p.userId == widget.meeting.userId
          );
          
          if (localIndex != -1) {
            participants[localIndex] = ParticipantModel(
              userId: participants[localIndex].userId,
              name: participants[localIndex].name,
              status: participants[localIndex].status,
              isLocal: true,
              isMuted: participants[localIndex].isMuted,
              isVideoOff: participants[localIndex].isVideoOff,
            );
          } else {
            participants.insert(
              0,
              ParticipantModel(
                userId: widget.meeting.userId,
                name: widget.meeting.userName,
                isLocal: true,
                status: 'active',
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
    ZegoExpressEngine.instance.logoutRoom(widget.meeting.roomId);
    if (localViewID != null) {
      ZegoExpressEngine.instance.destroyCanvasView(localViewID!);
    }
    streamToUserMap.clear();
    userToStreamMap.clear();
    remoteViews.clear();
    remoteViewIds.clear();
    remoteStreams.clear();
    ZegoExpressEngine.destroyEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MeetingBloc, MeetingState>(
      builder: (context, state) {
        print("🏗️ UI BUILD - Participants: ${participants.length}");
        print("📊 Streams: ${streamToUserMap.keys.length}");
        print("📹 Remote Views: ${remoteViews.keys.length}");
        
        // Debug: Print participant-stream mapping
        for (var participant in participants) {
          final streamId = userToStreamMap[participant.userId];
          print("👤 ${participant.name} (${participant.userId}) -> Stream: $streamId");
        }
        
        return Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const Icon(
              Icons.security,
              color: Colors.greenAccent,
              size: 20,
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "UI/UX Design Session",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${formatDuration(_meetingDuration)} • ${participants.length} Participants",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  state.isRecording
                      ? Icons.stop_circle
                      : Icons.fiber_manual_record,
                  color: state.isRecording ? Colors.red : Colors.white,
                ),
                onPressed: () =>
                    context.read<MeetingBloc>().add(ToggleRecording()),
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
                  child: participants.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : GridView.builder(
                          // ✅ FIXED: Updated key to rebuild when participants change
                          key: ValueKey(participants.map((p) => p.userId).join(',')),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: participants.length,
                          itemBuilder: (context, index) {
                            final participant = participants[index];
                            Widget? videoView;
                            
                            // ✅ IMPROVED: Use userToStreamMap for faster lookup
                            if (!participant.isLocal) {
                              final streamID = userToStreamMap[participant.userId];
                              
                              if (streamID != null && remoteViews.containsKey(streamID)) {
                                videoView = remoteViews[streamID];
                                print("✅ Found view for ${participant.name}: $streamID");
                              } else {
                                print("❌ No view found for ${participant.name} (streamID: $streamID)");
                              }
                            }

                            return _buildVideoTile(
                              name: participant.isLocal
                                  ? (widget.meeting.isHost
                                      ? "${participant.name} (Host)"
                                      : participant.name)
                                  : participant.name,
                              isMuted: participant.isLocal ? state.isMuted : participant.isMuted,
                              isVideoOff: participant.isLocal ? state.isCamOff : participant.isVideoOff,
                              isLocal: participant.isLocal,
                              avatarColor: participant.isLocal ? Colors.blueAccent : Colors.purpleAccent,
                              videoView: participant.isLocal ? null : videoView,
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF262626),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildControlButton(
                    icon: state.isMuted ? Icons.mic_off : Icons.mic,
                    color: state.isMuted ? Colors.redAccent : Colors.white24,
                    iconColor: Colors.white,
                    onPressed: () =>
                        context.read<MeetingBloc>().add(ToggleMic()),
                  ),
                  _buildControlButton(
                    icon: state.isCamOff ? Icons.videocam_off : Icons.videocam,
                    color: state.isCamOff ? Colors.redAccent : Colors.white24,
                    iconColor: Colors.white,
                    onPressed: () =>
                        context.read<MeetingBloc>().add(ToggleCam()),
                  ),
                  _buildControlButton(
                    icon: Icons.screen_share,
                    color: state.isScreenSharing
                        ? Colors.green
                        : Colors.white24,
                    iconColor: Colors.white,
                    onPressed: () {
                      context.read<MeetingBloc>().add(ToggleScreenShare());
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.cameraswitch,
                    color: Colors.white24,
                    iconColor: Colors.white,
                    onPressed: () {
                      context.read<MeetingBloc>().add(SwitchCamera());
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.people,
                    color: Colors.white24,
                    iconColor: Colors.white,
                    onPressed: _showParticipantsSheet,
                  ),
                  _buildControlButton(
                    icon: Icons.call_end,
                    color: Colors.red,
                    iconColor: Colors.white,
                    isEndCall: true,
                    onPressed: () async {
                      await ZegoExpressEngine.instance.stopPreview();
                      await ZegoExpressEngine.instance.stopPublishingStream();
                      await ZegoExpressEngine.instance.logoutRoom(
                        widget.meeting.roomId,
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                  ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Participants",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              if (_waitingList.isNotEmpty) ...[
                const Text(
                  "Waiting Room",
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: _waitingList.length,
                    itemBuilder: (_, index) {
                      final participant = _waitingList[index];
                      final safeName = (participant.name ?? '').trim();

                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: Icon(Icons.pending, size: 16),
                        ),
                        title: Text(
                          safeName.isNotEmpty ? safeName : "Unknown User",
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.greenAccent,
                              ),
                              onPressed: () async {
                                bool success = await HostService().admitUser(
                                  widget.meeting.roomId,
                                  participant.userId,
                                );

                                if (success) {
                                  await _refreshParticipantList();
                                  setModalState(() {});
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.redAccent,
                              ),
                              onPressed: () async {
                                bool success = await HostService().rejectUser(
                                  widget.meeting.roomId,
                                  participant.userId,
                                );

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
              const Text(
                "In Meeting",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: participants.length,
                  itemBuilder: (_, index) {
                    final participant = participants[index];
                    final safeName = (participant.name ?? '').trim();
                    final displayName =
                        safeName.isNotEmpty ? safeName : "Unknown User";

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Text(
                          safeName.isNotEmpty
                              ? safeName.characters.first.toUpperCase()
                              : "?",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      trailing: widget.meeting.isHost && !participant.isLocal
                          ? PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert,
                                  size: 16, color: Colors.white),
                              onSelected: (value) {
                                if (value == "mute") {
                                  _toggleMuteUser(participant);
                                }
                                if (value == "remove") {
                                  _removeUser(userId: participant.userId);
                                }
                                if (value == "host") {
                                  _transferHost(userId: participant.userId);
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
                            )
                          : null,
                    );
                  },
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
    final safeName = (name ?? '').trim();
    final displayName = safeName.isNotEmpty ? safeName : "Unknown";

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          // VIDEO VIEW
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
                            "Waiting for video...",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      )),
            )
          else
            // AVATAR WHEN VIDEO OFF
            Center(
              child: CircleAvatar(
                radius: 35,
                backgroundColor: avatarColor,
                child: Text(
                  safeName.isNotEmpty
                      ? safeName.characters.first.toUpperCase()
                      : "?",
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          
          // NAME AND MIC STATUS
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onPressed,
    bool isEndCall = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        width: isEndCall ? 60 : 50,
        height: isEndCall ? 60 : 50,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: isEndCall ? 28 : 22),
      ),
    );
  }
}

// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:meet_easyy/bloc/meeting_room_bloc/service/host_service_meet_room.dart';
// import 'package:meet_easyy/bloc/meeting_room_bloc/service/screen_share_service.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:zego_express_engine/zego_express_engine.dart';
// import '../../model/new_meeting_model.dart';
// import '../../zego_engine/zego_service.dart';
// import 'meeting_room_bloc.dart';
// import 'model.dart';

// class MeetingRoomScreen extends StatefulWidget {
//   final MeetingModel2 meeting;

//   const MeetingRoomScreen({super.key, required this.meeting});

//   @override
//   State<MeetingRoomScreen> createState() => _MeetingRoomScreenState();
// }

// class _MeetingRoomScreenState extends State<MeetingRoomScreen> {
//   Timer? _screenShareTimer;

//   bool isRemoteScreenSharing = false;

//   String sharedBy = "";

//   Map<String, Widget?> remoteViews = {};
//   Map<String, int> remoteViewIds = {};
//   Widget? localViewWidget;
//   List<String> remoteStreams = [];

//   List<ParticipantModel> _waitingList = [];
//   List<ParticipantModel> participants = [];
//   Duration _meetingDuration = Duration.zero;
//   Timer? _timer;
//   int? localViewID;
//   Timer? _listRefreshTimer;
//   @override
//   void initState() {
//     super.initState();

//     _screenShareTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
//       try {
//         final response = await ScreenShareService().getScreenShareStatus(
//           widget.meeting.roomId,
//         );

//         if (!mounted) return;

//         final isSharing = response?["isScreenSharing"] ?? false;

//         final newSharedBy = response?["screenSharedBy"]?["name"] ?? "";

//         if (isSharing != isRemoteScreenSharing || newSharedBy != sharedBy) {
//           setState(() {
//             isRemoteScreenSharing = isSharing;
//             sharedBy = newSharedBy;
//           });
//         }
//       } catch (e) {
//         debugPrint("Screen share status error: $e");
//       }
//     });
//     participants.add(
//       ParticipantModel(
//         userId: widget.meeting.userId,
//         name: widget.meeting.userName,
//         isLocal: true,
//       ),
//     );

//     _listRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
//       _refreshParticipantList();
//     });

//     _initMeeting();

//     _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       setState(() {
//         _meetingDuration += const Duration(seconds: 1);
//       });
//     });
//   }

//   String formatDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, '0');

//     final h = twoDigits(duration.inHours);
//     final m = twoDigits(duration.inMinutes.remainder(60));
//     final s = twoDigits(duration.inSeconds.remainder(60));

//     return "$h:$m:$s";
//   }

//   void _removeUser({required String userId}) {
//     setState(() {
//       participants.removeWhere((p) => p.userId == userId);
//       remoteStreams.removeWhere((s) => s.contains(userId));
//     });
//   }

//   void _transferHost({required String userId}) {
//     setState(() {
//       for (int i = 0; i < participants.length; i++) {
//         if (participants[i].userId == userId) {
//           participants[i] = ParticipantModel(
//             userId: participants[i].userId,
//             name: participants[i].name,
//             isLocal: false,
//           );
//         }
//       }
//     });
//   }

//   Future<void> _startScreenSharing() async {
//     await ZegoExpressEngine.instance.startPublishingStream(
//       "screen_${widget.meeting.roomId}",
//       config: ZegoPublisherConfig(),
//       channel: ZegoPublishChannel.Aux,
//     );
//   }

//   bool get isHostUser {
//     return participants.any(
//       (p) => p.userId == widget.meeting.userId && widget.meeting.isHost,
//     );
//   }

//   void _toggleMuteUser(ParticipantModel user) {
//     setState(() {
//       user.isMuted = !user.isMuted;
//     });
//   }

//   void _initMeeting() async {
//     await ZegoEngineService.initEngine();

//     await [Permission.camera, Permission.microphone].request();

//     localViewWidget = await ZegoExpressEngine.instance.createCanvasView((
//       viewID,
//     ) {
//       localViewID = viewID;
//     });

//     setState(() {});

//     await ZegoExpressEngine.instance.loginRoom(
//       widget.meeting.roomId,
//       ZegoUser(widget.meeting.userId, widget.meeting.userName),
//     );

//     ZegoExpressEngine.onRoomStreamUpdate =
//         (roomID, updateType, streamList, extendedData) async {
//           if (updateType == ZegoUpdateType.Add) {
//             for (var stream in streamList) {
//               print("STREAM ID => ${stream.streamID}");
//               debugPrint("USER ID => ${stream.user.userID}");
//               debugPrint("USER NAME => ${stream.user.userName}");
//               Widget? view = await ZegoExpressEngine.instance.createCanvasView((
//                 viewID,
//               ) async {
//                 remoteViewIds[stream.streamID] = viewID;
//                 await ZegoExpressEngine.instance.startPlayingStream(
//                   stream.streamID,
//                   canvas: ZegoCanvas(viewID, viewMode: ZegoViewMode.AspectFill),
//                 );
//               });

//               print("STREAM ID => ${stream.streamID}");

//               remoteViews[stream.streamID] = view;

//               if (!remoteStreams.contains(stream.streamID)) {
//                 remoteStreams.add(stream.streamID);
//               }

//               if (stream.streamID.startsWith("screen_")) {
//                 remoteStreams.remove(stream.streamID);
//                 remoteStreams.insert(0, stream.streamID);
//               }

//               setState(() {});
//               continue;
//             }

//             print("REMOTE STREAMS => $remoteStreams");

//             setState(() {});
//             setState(() {});
//             setState(() {});
//           } else {
//             for (var stream in streamList) {
//               if (remoteViewIds.containsKey(stream.streamID)) {
//                 await ZegoExpressEngine.instance.stopPlayingStream(
//                   stream.streamID,
//                 );
//                 await ZegoExpressEngine.instance.destroyCanvasView(
//                   remoteViewIds[stream.streamID]!,
//                 );
//               }
//               remoteViewIds.remove(stream.streamID);
//               remoteViews.remove(stream.streamID);
//               setState(() {});
//             }
//           }
//         };

//     if (localViewID != null) {
//       await ZegoExpressEngine.instance.startPreview(
//         canvas: ZegoCanvas(localViewID!, viewMode: ZegoViewMode.AspectFill),
//       );
//     }

//     await ZegoExpressEngine.instance.startPublishingStream(
//       "stream_${DateTime.now().millisecondsSinceEpoch}",
//     );
//   }

//   Future<void> _refreshParticipantList() async {
//     try {
//       final list = await HostService().getWaitingParticipants(
//         widget.meeting.roomId,
//       );

//       List<ParticipantModel> allUsers = (list)
//           .map((e) => ParticipantModel.fromJson(e))
//           .toList();

//       if (mounted) {
//         setState(() {
//           _waitingList = allUsers.where((p) => p.status == 'waiting').toList();
//           participants = allUsers
//               .where((p) => p.status == 'active')
//               .map(
//                 (p) => ParticipantModel(
//                   userId: p.userId,
//                   // name: p.name,
//                   name: (p.name).toString().trim(),
//                   status: p.status,
//                   isLocal: p.userId == widget.meeting.userId,
//                   isMuted: p.isMuted,
//                   isVideoOff: p.isVideoOff,
//                 ),
//               )
//               .toList();
//           // Host check
//           if (!participants.any((p) => p.userId == widget.meeting.userId)) {
//             participants.insert(
//               0,
//               ParticipantModel(
//                 userId: widget.meeting.userId,
//                 name: widget.meeting.userName,
//                 isLocal: true,
//               ),
//             );
//           }
//         });
//       }
//     } catch (e) {
//       debugPrint("Refresh Error: $e");
//     }
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     _screenShareTimer?.cancel();
//     _listRefreshTimer?.cancel();
//     ZegoExpressEngine.instance.stopPreview();
//     ZegoExpressEngine.instance.stopPublishingStream();
//     ZegoExpressEngine.instance.logoutRoom(widget.meeting.roomId);
//     if (localViewID != null) {
//       ZegoExpressEngine.instance.destroyCanvasView(localViewID!);
//     }
//     ZegoExpressEngine.destroyEngine();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<MeetingBloc, MeetingState>(
//       builder: (context, state) {
//         return Scaffold(
//           backgroundColor: const Color(0xFF1A1A1A),
//           appBar: AppBar(
//             backgroundColor: Colors.transparent,
//             elevation: 0,
//             leading: const Icon(
//               Icons.security,
//               color: Colors.greenAccent,
//               size: 20,
//             ),
//             title: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   "UI/UX Design Session",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 Text(
//                   "${formatDuration(_meetingDuration)} • ${participants.length} Participants",
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.6),
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//             actions: [
//               IconButton(
//                 icon: Icon(
//                   state.isRecording
//                       ? Icons.stop_circle
//                       : Icons.fiber_manual_record,
//                   color: state.isRecording ? Colors.red : Colors.white,
//                 ),
//                 onPressed: () =>
//                     context.read<MeetingBloc>().add(ToggleRecording()),
//               ),
//               IconButton(
//                 icon: const Icon(Icons.bookmark_border, color: Colors.white),
//                 onPressed: () {},
//               ),
//             ],
//           ),
//           body: Column(
//             children: [
//               if (isRemoteScreenSharing && sharedBy.isNotEmpty)
//                 Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.all(10),
//                   color: Colors.green,
//                   child: Text(
//                     "$sharedBy is sharing screen",
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),

//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.all(12.0),

//                   child: GridView.builder(
//                     gridDelegate:
//                         const SliverGridDelegateWithFixedCrossAxisCount(
//                           crossAxisCount: 2,
//                           crossAxisSpacing: 12,
//                           mainAxisSpacing: 12,
//                         ),

//                     itemCount: participants.length + remoteStreams.length,

//                     itemBuilder: (context, index) {
//                       final hasScreenShare =
//                           remoteStreams.isNotEmpty &&
//                           remoteStreams.first.startsWith("screen_");

//                       /// SCREEN SHARE TILE
//                       if (hasScreenShare && index == 0) {
//                         final streamID = remoteStreams.first;

//                         return SizedBox(
//                           width: double.infinity,
//                           child:
//                               remoteViews[streamID] ??
//                               const Center(child: CircularProgressIndicator()),
//                         );
//                       }

//                       final participantIndex = hasScreenShare
//                           ? index - 1
//                           : index;

//                       /// LOCAL + PARTICIPANTS
//                       if (participantIndex >= 0 &&
//                           participantIndex < participants.length) {
//                         final participant = participants[participantIndex];

//                         return _buildVideoTile(
//                           name: participant.isLocal
//                               ? (widget.meeting.isHost
//                                     ? "${participant.name} (Host)"
//                                     : participant.name)
//                               : participant.name,
//                           isMuted: participant.isLocal
//                               ? state.isMuted
//                               : participant.isMuted,
//                           isVideoOff: participant.isLocal
//                               ? state.isCamOff
//                               : participant.isVideoOff,
//                           isLocal: participant.isLocal,
//                           avatarColor: Colors.blueAccent,
//                         );
//                       }

//                       /// REMOTE STREAM INDEX
//                       int remoteIndex = participantIndex - participants.length;

//                       if (hasScreenShare) {
//                         remoteIndex += 1;
//                       }

//                       /// SAFETY CHECK
//                       if (remoteIndex < 0 ||
//                           remoteIndex >= remoteStreams.length) {
//                         return const SizedBox.shrink();
//                       }

//                       final streamID = remoteStreams[remoteIndex];

//                       return _buildVideoTile(
//                         name: "Participant",
//                         isMuted: false,
//                         isVideoOff: false,
//                         isLocal: false,
//                         avatarColor: Colors.purpleAccent,
//                         videoView: remoteViews[streamID],
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           bottomNavigationBar: Container(
//             padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
//             decoration: const BoxDecoration(
//               color: Color(0xFF262626),
//               borderRadius: BorderRadius.only(
//                 topLeft: Radius.circular(24),
//                 topRight: Radius.circular(24),
//               ),
//             ),
//             child: SafeArea(
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   _buildControlButton(
//                     icon: state.isMuted ? Icons.mic_off : Icons.mic,
//                     color: state.isMuted ? Colors.redAccent : Colors.white24,
//                     iconColor: Colors.white,
//                     onPressed: () =>
//                         context.read<MeetingBloc>().add(ToggleMic()),
//                   ),
//                   _buildControlButton(
//                     icon: state.isCamOff ? Icons.videocam_off : Icons.videocam,
//                     color: state.isCamOff ? Colors.redAccent : Colors.white24,
//                     iconColor: Colors.white,
//                     onPressed: () =>
//                         context.read<MeetingBloc>().add(ToggleCam()),
//                   ),
//                   _buildControlButton(
//                     icon: Icons.screen_share,
//                     color: state.isScreenSharing
//                         ? Colors.green
//                         : Colors.white24,
//                     iconColor: Colors.white,
//                     onPressed: () {
//                       context.read<MeetingBloc>().add(ToggleScreenShare());
//                     },
//                   ),
//                   _buildControlButton(
//                     icon: Icons.cameraswitch,
//                     color: Colors.white24,
//                     iconColor: Colors.white,
//                     onPressed: () {
//                       context.read<MeetingBloc>().add(SwitchCamera());
//                     },
//                   ),
//                   _buildControlButton(
//                     icon: Icons.people,
//                     color: Colors.white24,
//                     iconColor: Colors.white,
//                     onPressed: _showParticipantsSheet,
//                   ),
//                   _buildControlButton(
//                     icon: Icons.call_end,
//                     color: Colors.red,
//                     iconColor: Colors.white,
//                     isEndCall: true,
//                     onPressed: () async {
//                       await ZegoExpressEngine.instance.stopPreview();

//                       await ZegoExpressEngine.instance.stopPublishingStream();
//                       await ZegoExpressEngine.instance.logoutRoom(
//                         widget.meeting.roomId,
//                       );

//                       if (context.mounted) {
//                         Navigator.pop(context);
//                       }
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void _showParticipantsSheet() {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: const Color(0xFF262626),
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       builder: (_) => StatefulBuilder(
//         builder: (context, setModalState) => Container(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Center(
//                 child: Text(
//                   "Participants",
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // WAITING ROOM SECTION
//               if (_waitingList.isNotEmpty) ...[
//                 const Text(
//                   "Waiting Room",
//                   style: TextStyle(
//                     color: Colors.amber,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: _waitingList.length,
//                     itemBuilder: (_, index) {
//                       final participant =
//                           _waitingList[index]; // Assuming list of objects
//                       return ListTile(
//                         leading: const CircleAvatar(
//                           backgroundColor: Colors.amber,
//                           child: Icon(Icons.pending, size: 16),
//                         ),
//                         title: Text(
//                           participant.name,
//                           style: const TextStyle(color: Colors.white),
//                         ),
//                         trailing: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             IconButton(
//                               icon: const Icon(
//                                 Icons.check_circle,
//                                 color: Colors.greenAccent,
//                               ),
//                               onPressed: () async {
//                                 bool success = await HostService().admitUser(
//                                   widget.meeting.roomId,
//                                   participant.userId,
//                                 );
//                                 if (success) {
//                                   await _refreshParticipantList(); // Turant list refresh karein
//                                   setModalState(() {}); // UI update karein
//                                 }
//                               },
//                             ),
//                             // REJECT BUTTON
//                             IconButton(
//                               icon: const Icon(
//                                 Icons.cancel,
//                                 color: Colors.redAccent,
//                               ),
//                               onPressed: () async {
//                                 bool success = await HostService().rejectUser(
//                                   widget.meeting.roomId,
//                                   participant.userId,
//                                 );
//                                 if (success) {
//                                   setModalState(() {
//                                     _waitingList.removeAt(index);
//                                   });
//                                 }
//                               },
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],

//               const Divider(color: Colors.white24),
//               const Text(
//                 "In Meeting",
//                 style: TextStyle(
//                   color: Colors.white70,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               // IN MEETING SECTION
//               // Expanded(
//               //   child: ListView.builder(
//               //     itemCount: participants.length,
//               //     itemBuilder: (_, index) => ListTile(
//               //       leading: CircleAvatar(
//               //         backgroundColor: Colors.blueAccent,
//               //         child: Text(
//               //           participants[index].name[0].toUpperCase(),
//               //           style: const TextStyle(color: Colors.white),
//               //         ),
//               //       ),
//               //       title: Text(
//               //         participants[index].name,
//               //         style: const TextStyle(color: Colors.white),
//               //       ),
//               //     ),
//               //   ),
//               // ),
//               // IN MEETING SECTION
// Expanded(
//   child: ListView.builder(
//     itemCount: participants.length,
//     itemBuilder: (_, index) {
//       final participant = participants[index];

//       return ListTile(
//         leading: CircleAvatar(
//           backgroundColor: Colors.blueAccent,
//           child: Text(
//             participant.name.trim().isNotEmpty
//                 ? participant.name.trim()[0].toUpperCase()
//                 : "?",
//             style: const TextStyle(
//               color: Colors.white,
//             ),
//           ),
//         ),
//         title: Text(
//           participant.name.trim().isNotEmpty
//               ? participant.name
//               : "Unknown User",
//           style: const TextStyle(
//             color: Colors.white,
//           ),
//         ),
//       );
//     },
//   ),
// ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildVideoTile({
//     required bool isLocal,
//     required String name,
//     required bool isMuted,
//     required bool isVideoOff,
//     required Color avatarColor,
//     Widget? videoView,
//   }) {
//      final safeName = name.trim();
//     return Container(
//       decoration: BoxDecoration(
//         color: const Color(0xFF333333),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.white10),
//       ),
//       child: Stack(
//         children: [
//           if (!isVideoOff)
//             Positioned.fill(
//               child: isLocal
//                   ? (localViewWidget ??
//                         Container(
//                           color: Colors.black,
//                           child: const Center(
//                             child: CircularProgressIndicator(),
//                           ),
//                         ))
//                   : (videoView ??
//                         Container(
//                           color: Colors.black,
//                           child: const Center(
//                             child: Text(
//                               "Waiting User...",
//                               style: TextStyle(color: Colors.white),
//                             ),
//                           ),
//                         )),
//             )
//           else
//             Center(
//               child: CircleAvatar(
//                 radius: 35,
//                 backgroundColor: avatarColor,
// //              child: Text(
// //   name.isNotEmpty ? name[0] : "?",
// //   style: const TextStyle(
// //     fontSize: 28,
// //     color: Colors.white,
// //     fontWeight: FontWeight.bold,
// //   ),
// // ),
// child: Text(
//   safeName.isNotEmpty
//       ? safeName.characters.first.toUpperCase()
//       : "?",
//   style: const TextStyle(
//     fontSize: 28,
//     color: Colors.white,
//     fontWeight: FontWeight.bold,
//   ),
// ),
//               ),
//             ),

//           Positioned(
//             bottom: 8,
//             left: 8,
//             right: 8,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 // LEFT SIDE NAME
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.black54,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(
//                     name,
//                     style: const TextStyle(color: Colors.white, fontSize: 12),
//                   ),
//                 ),

//                 // RIGHT SIDE MIC ICON
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(4),
//                       decoration: BoxDecoration(
//                         color: isMuted ? Colors.red : Colors.black54,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         isMuted ? Icons.mic_off : Icons.mic,
//                         size: 14,
//                         color: Colors.white,
//                       ),
//                     ),

//                     // ✅ HOST MENU ONLY FOR HOST & NOT SELF
//                     if (widget.meeting.isHost && !isLocal)
//                       PopupMenuButton<String>(
//                         icon: const Icon(Icons.more_vert, color: Colors.white),
//                         onSelected: (value) {
//                           if (value == "mute") {
//                             _toggleMuteUser(
//                               ParticipantModel(userId: name, name: name),
//                             );
//                           }

//                           if (value == "remove") {
//                             _removeUser(userId: name);
//                           }

//                           if (value == "host") {
//                             _transferHost(userId: name);
//                           }
//                         },
//                         itemBuilder: (_) => const [
//                           PopupMenuItem(
//                             value: "mute",
//                             child: Text("Mute/Unmute"),
//                           ),
//                           PopupMenuItem(
//                             value: "remove",
//                             child: Text("Remove User"),
//                           ),
//                           PopupMenuItem(
//                             value: "host",
//                             child: Text("Make Host"),
//                           ),
//                         ],
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildControlButton({
//     required IconData icon,
//     required Color color,
//     required Color iconColor,
//     required VoidCallback onPressed,
//     bool isEndCall = false,
//   }) {
//     return InkWell(
//       onTap: onPressed,
//       borderRadius: BorderRadius.circular(100),
//       child: Container(
//         width: isEndCall ? 60 : 50,
//         height: isEndCall ? 60 : 50,
//         decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//         child: Icon(icon, color: iconColor, size: isEndCall ? 28 : 22),
//       ),
//     );
//   }
// }
