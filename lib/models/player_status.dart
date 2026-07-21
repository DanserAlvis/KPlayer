enum PlayerPhase { initializing, ready, loading, playing, paused, error }

class PlayerStatus {
  const PlayerStatus({
    required this.isPlaying,
    required this.position,
    required this.duration,
  });

  final bool isPlaying;
  final Duration position;
  final Duration duration;
}
