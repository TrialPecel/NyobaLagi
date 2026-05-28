import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:typed_data';

class MusicController extends ChangeNotifier {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();

  List<SongModel> _songList = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Color _dominantColor = const Color(0xFFE8E8EC);
  bool _permissionGranted = false;
  bool _isLoading = true;

  List<SongModel> get songList => _songList;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  Color get dominantColor => _dominantColor;
  bool get permissionGranted => _permissionGranted;
  bool get isLoading => _isLoading;

  SongModel? get currentSong => _currentIndex >= 0 && _currentIndex < _songList.length ? _songList[_currentIndex] : null;

  MusicController() {
    _init();
  }

  Future<void> _init() async {
    await checkAndRequestPermissions();
    if (_permissionGranted) {
      await querySongs();
    }
    _setupAudioPlayerListeners();
  }

  Future<void> checkAndRequestPermissions() async {
    PermissionStatus status;
    if (await Permission.audio.status.isGranted || await Permission.storage.status.isGranted) {
      _permissionGranted = true;
    } else {
      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.audio,
      ].request();
      
      _permissionGranted = statuses[Permission.storage] == PermissionStatus.granted || 
                           statuses[Permission.audio] == PermissionStatus.granted;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> querySongs() async {
    _isLoading = true;
    notifyListeners();

    _songList = await _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.DESC_OR_GREATER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );
    
    // Sort by recently added - OnAudioQuery has DATE_ADDED
    _songList = await _audioQuery.querySongs(
      sortType: SongSortType.DATE_ADDED,
      orderType: OrderType.DESC_OR_GREATER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    _isLoading = false;
    if (_songList.isNotEmpty && _currentIndex == -1) {
      _currentIndex = 0;
      await _updateDominantColor(_songList[_currentIndex]);
    }
    notifyListeners();
  }

  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  void _setupAudioPlayerListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        next();
      }
      notifyListeners();
    });

    _audioPlayer.positionStream.listen((pos) {
      _position = pos;
      // notifyListeners(); removed to prevent flickering
    });

    _audioPlayer.durationStream.listen((dur) {
      _duration = dur ?? Duration.zero;
      // notifyListeners(); removed to prevent flickering
    });
  }

  Future<void> play(int index) async {
    if (_songList.isEmpty || index < 0 || index >= _songList.length) return;

    if (_currentIndex != index) {
      _currentIndex = index;
      String? uri = _songList[index].uri;
      if (uri != null) {
        await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(uri)));
        await _updateDominantColor(_songList[index]);
      }
    }
    
    await _audioPlayer.play();
    notifyListeners();
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play(_currentIndex == -1 ? 0 : _currentIndex);
    }
  }

  Future<void> next() async {
    if (_songList.isEmpty) return;
    int nextIndex = (_currentIndex + 1) % _songList.length;
    await play(nextIndex);
  }

  Future<void> previous() async {
    if (_songList.isEmpty) return;
    int prevIndex = (_currentIndex - 1) < 0 ? _songList.length - 1 : _currentIndex - 1;
    await play(prevIndex);
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> seekToPercentage(double percent) async {
    if (_duration.inMilliseconds > 0) {
      int targetMs = (_duration.inMilliseconds * percent).round();
      await _audioPlayer.seek(Duration(milliseconds: targetMs));
    }
  }

  Future<void> _updateDominantColor(SongModel song) async {
    try {
      Uint8List? artwork = await _audioQuery.queryArtwork(
        song.id,
        ArtworkType.AUDIO,
      );

      if (artwork != null) {
        final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImageProvider(
          MemoryImage(artwork),
        );
        
        Color? newColor = paletteGenerator.dominantColor?.color;
        if (newColor != null) {
          // Lighten/desaturate the color to match the iOS clean aesthetic
          HSLColor hsl = HSLColor.fromColor(newColor);
          _dominantColor = hsl.withLightness((hsl.lightness + 0.4).clamp(0.0, 0.95)).toColor();
        } else {
          _dominantColor = const Color(0xFFE8E8EC);
        }
      } else {
        _dominantColor = const Color(0xFFE8E8EC);
      }
    } catch (e) {
      _dominantColor = const Color(0xFFE8E8EC);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
