import 'package:fijkplayer_ijkfix/fijkplayer_ijkfix.dart';
import 'package:flutter/material.dart';

/// Keep the default Fijk panel only while a real playback source is selected.
/// Its idle state otherwise shows a progress spinner forever on the empty screen.
FijkPanelWidgetBuilder iptvPlayerPanelBuilder({
  required bool hasPlaybackSource,
}) {
  if (hasPlaybackSource) return defaultFijkPanelBuilder;

  return (player, data, context, viewSize, texturePos) =>
      const SizedBox.shrink();
}
