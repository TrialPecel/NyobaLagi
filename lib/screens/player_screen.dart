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
    _pageController = PageController(viewportFraction: 0.75);
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
            backgroundColor: Color(0xFFE8E8EC),
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
                  _buildHeader(),
                  Expanded(
                    flex: 55,
                    child: _buildCarousel(controller),
                  ),
                  _buildPagination(controller),
                  Expanded(
                    flex: 35,
                    child: _buildRadialDialAndControls(controller),
                  ),
                  _buildBottomNavBar(),
                  const SizedBox(height: 16),
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
      backgroundColor: const Color(0xFFE8E8EC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off, size: 64, color: Colors.black54),
            const SizedBox(height: 16),
            Text(
              'Storage Permission Required',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Please grant permission to read local music.'),
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
      backgroundColor: const Color(0xFFE8E8EC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 64, color: Colors.black54),
            const SizedBox(height: 16),
            Text(
              'No Music Found',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
              color: Colors.black87,
              letterSpacing: -1.0,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.queue_music, color: Colors.black87),
              onPressed: () {},
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
              value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
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

  Widget _buildPagination(MusicController controller) {
    int totalDots = controller.songList.length > 5 ? 5 : controller.songList.length;
    if (totalDots == 0) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDots, (index) {
        // Simplified dot logic for a 5-dot window around current index
        bool isActive = false;
        if (controller.songList.length <= 5) {
          isActive = index == controller.currentIndex;
        } else {
          isActive = index == 2; // middle dot is active
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8,
          width: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.black87 : Colors.black26,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildRadialDialAndControls(MusicController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RadialDial(
          progress: controller.duration.inMilliseconds > 0
              ? controller.position.inMilliseconds / controller.duration.inMilliseconds
              : 0.0,
          positionText: _formatDuration(controller.position),
          durationText: _formatDuration(controller.duration),
          isPlaying: controller.isPlaying,
          onTogglePlay: controller.togglePlayPause,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.skip_previous, color: Colors.black87),
              onPressed: controller.previous,
            ),
            const SizedBox(width: 80), // Space for dial
            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.skip_next, color: Colors.black87),
              onPressed: controller.next,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.search),
            _buildNavItem(Icons.close), // Map to queue close or similar
            _buildNavItem(Icons.person_outline),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.black87, size: 24),
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
