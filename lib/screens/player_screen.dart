import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/music_controller.dart';
import '../widgets/song_card.dart';
import '../widgets/radial_dial.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    return Consumer<MusicController>(
      builder: (context, controller, child) {
        if (!controller.permissionGranted && !controller.isLoading) {
          return _buildPermissionDenied();
        }

        if (controller.isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.songList.isEmpty) {
          return _buildEmptyState();
        }

        // Keep page controller in sync with current song index
        if (_pageController.hasClients && 
            _pageController.page?.round() != controller.currentIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _pageController.animateToPage(
              controller.currentIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            color: controller.dominantColor,
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    flex: 65,
                    child: _buildCarousel(controller),
                  ),
                  Expanded(
                    flex: 30,
                    child: _buildRadialDialAndControls(controller),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPermissionDenied() {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              'Storage Permission Required',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Please grant permission to read local music.', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<MusicController>().checkAndRequestPermissions();
              },
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text(
              'No Music Found',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Now Playing',
            style: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel(MusicController controller) {
    return PageView.builder(
      controller: _pageController,
      itemCount: controller.songList.length,
      onPageChanged: (index) {
        controller.play(index);
      },
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double value = 1.0;
            if (_pageController.position.haveDimensions) {
              value = _pageController.page! - index;
              value = (1 - (value.abs() * 0.1)).clamp(0.9, 1.0);
            }
            double opacity = value.clamp(0.7, 1.0);
            
            return Center(
              child: Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: opacity,
                  child: child,
                ),
              ),
            );
          },
          child: AspectRatio(
            aspectRatio: 1,
            child: SongCard(
              song: controller.songList[index],
              index: index,
            ),
          ),
        );
      },
    );
  }



  Widget _buildRadialDialAndControls(MusicController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StreamBuilder<Duration>(
          stream: controller.positionStream,
          builder: (context, positionSnapshot) {
            return StreamBuilder<Duration?>(
              stream: controller.durationStream,
              builder: (context, durationSnapshot) {
                final position = positionSnapshot.data ?? controller.position;
                final duration = durationSnapshot.data ?? controller.duration;
                
                return RadialDial(
                  progress: duration.inMilliseconds > 0
                      ? position.inMilliseconds / duration.inMilliseconds
                      : 0.0,
                  positionText: _formatDuration(position),
                  durationText: _formatDuration(duration),
                  isPlaying: controller.isPlaying,
                  onTogglePlay: controller.togglePlayPause,
                  onSeek: controller.seekToPercentage,
                );
              }
            );
          }
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
