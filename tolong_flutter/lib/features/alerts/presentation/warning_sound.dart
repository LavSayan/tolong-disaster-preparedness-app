import 'dart:math';
import 'dart:typed_data';

const _sampleRate = 44100;
const _cycleSeconds = 1.8;

/// One 1.8 s loop of the two-tone (520 Hz → 660 Hz) triangle-wave warning chime, as 16-bit mono WAV.
Uint8List buildWarningWav() {
  final n = (_sampleRate * _cycleSeconds).round();
  final samples = Float64List(n);

  void tone(double start, double freq, double dur) {
    final s0 = (start * _sampleRate).round();
    final len = ((dur + 0.03) * _sampleRate).round();
    for (var i = 0; i < len && s0 + i < n; i++) {
      final t = i / _sampleRate;
      final phase = (t * freq) % 1.0;
      final tri = 4 * (phase - 0.5).abs() - 1;
      double gain;
      if (t < 0.025) {
        gain = 0.0001 * pow(0.12 / 0.0001, t / 0.025);
      } else if (t < dur) {
        gain = 0.12 * pow(0.0001 / 0.12, (t - 0.025) / (dur - 0.025));
      } else {
        gain = 0;
      }
      samples[s0 + i] += tri * gain;
    }
  }

  tone(0, 520, 0.28);
  tone(0.34, 660, 0.28);

  final bytes = ByteData(44 + n * 2);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      bytes.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + n * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, _sampleRate, Endian.little);
  bytes.setUint32(28, _sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bytes.setUint32(40, n * 2, Endian.little);
  for (var i = 0; i < n; i++) {
    bytes.setInt16(44 + i * 2, (samples[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
  }
  return bytes.buffer.asUint8List();
}
