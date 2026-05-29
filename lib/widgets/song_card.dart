import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:google_fonts/google_fonts.dart';

class SongCard extends StatelessWidget {
  final SongModel song;
  final int index;

  const SongCard({
    Key? key,
    required this.song,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Generate a placeholder gradient based on the song's index
    final List<MaterialColor> placeholderColors = [
      Colors.blueGrey,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
      Colors.deepPurple,
    ];
    final color1 = placeholderColors[index % placeholderColors.length];
    final color2 = placeholderColors[(index + 1) % placeholderColors.length];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: ShapeDecoration(
        shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(110)),
        shadows: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(110))),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Artwork or Placeholder
            QueryArtworkWidget(
              id: song.id,
              type: ArtworkType.AUDIO,
              artworkFit: BoxFit.cover,
              quality: 100,
              format: ArtworkFormat.JPEG,
              size: 2000,
              nullArtworkWidget: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color1.shade300, color2.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.music_note,
                    size: 80,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
            // Gradient Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 120, // Bottom 25-30% approx depending on height
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Text Content
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist ?? "<Unknown Artist>",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
