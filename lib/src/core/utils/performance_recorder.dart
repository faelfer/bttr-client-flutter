import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Enabled only in the Android release APK built by the performance CI job.
/// The native side appends CSV rows to an app-specific file that adb can pull.
void startPerformanceRecorder() {
  const enabled = bool.fromEnvironment('BTTR_PERFORMANCE');
  if (!enabled || defaultTargetPlatform != TargetPlatform.android) return;

  const channel = MethodChannel('bttr/performance');
  SchedulerBinding.instance.addTimingsCallback((timings) {
    if (timings.isEmpty) return;
    final rows = timings
        .map(
          (frame) =>
              '${frame.buildDuration.inMicroseconds},'
              '${frame.rasterDuration.inMicroseconds},'
              '${frame.totalSpan.inMicroseconds}',
        )
        .join('\n');
    unawaited(
      channel.invokeMethod<void>('appendFrames', rows).catchError((
        Object error,
      ) {
        debugPrint('Não foi possível registrar frames: $error');
      }),
    );
  });
}
