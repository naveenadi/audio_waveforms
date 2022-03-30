import 'dart:math';
import 'package:audio_waveforms/src/base/constants.dart';
import 'package:flutter/material.dart';

///Referenced from https://stackoverflow.com/questions/38744579/show-waveform-of-audio
class FileWaveformsPainter extends CustomPainter {
  List<int> waveData;
  double waveThickness;
  double multiplier;
  double density;
  int maxDuration, currentDuration;
  LinearGradient? linearGradient;
  double animValue;
  double currentSeekPostion;
  bool showSeekLine;
  double scaleFactor;
  Color seekLineColor;
  Shader? liveWaveGradient;
  double seekLineThickness;

  FileWaveformsPainter({
    required this.waveData,
    required this.waveThickness,
    required this.multiplier,
    required this.density,
    required this.maxDuration,
    required this.currentDuration,
    required this.animValue,
    required this.currentSeekPostion,
    required this.showSeekLine,
    required this.scaleFactor,
    required this.seekLineColor,
    required this.seekLineThickness,
    this.liveWaveGradient,
    this.linearGradient,
  })  : wavePaint = Paint()
          ..color = Colors.white
          ..strokeWidth = waveThickness
          ..strokeCap = StrokeCap.round,
        liveAudioPaint = Paint()
          ..color = Colors.deepOrange
          ..strokeWidth = waveThickness
          ..strokeCap = StrokeCap.round,
        seeklinePaint = Paint()
          ..color = seekLineColor
          ..strokeWidth = seekLineThickness
          ..strokeCap = StrokeCap.round;

  Paint wavePaint;
  Paint liveAudioPaint;
  Paint seeklinePaint;

  int visualizerHieght = 28;
  double denseness = 1.0;
  double _seekerXPosition = 0.0;

  @override
  void paint(Canvas canvas, Size size) {
    _updatePlayerPercent(size);
    _drawWave(size, canvas);
    if (showSeekLine) _drawSeekLine(size, canvas);
  }

  @override
  bool shouldRepaint(FileWaveformsPainter oldDelegate) => true;

  void _drawSeekLine(Size size, Canvas canvas) {
    if (scrubberProgress() == 1.0) {
      canvas.drawLine(
        Offset(_seekerXPosition + liveAudioPaint.strokeWidth, 0),
        Offset(_seekerXPosition + liveAudioPaint.strokeWidth, size.height),
        seeklinePaint,
      );
    } else {
      canvas.drawLine(
        Offset(_seekerXPosition, 0),
        Offset(_seekerXPosition, size.height),
        seeklinePaint,
      );
    }
  }

  void _drawWave(Size size, Canvas canvas) {
    if (liveWaveGradient != null) liveAudioPaint.shader = liveWaveGradient;
    double totalBarsCount = size.width / dp(3);
    if (totalBarsCount <= 0.1) return;
    int samplesCount = waveData.length * 8 ~/ 5;
    double samplesPerBar = samplesCount / totalBarsCount;
    double barCounter = 0;
    int nextBarNum = 0;
    int y = (size.height - dp(visualizerHieght.toDouble())) ~/ 2;
    int barNum = 0;
    int lastBarNum;
    int drawBarCount;
    int byte;
    for (int i = 0; i < samplesCount; i++) {
      if (i != nextBarNum) {
        continue;
      }
      drawBarCount = 0;
      lastBarNum = nextBarNum;

      while (lastBarNum == nextBarNum) {
        barCounter += samplesPerBar;
        nextBarNum = barCounter.toInt();
        drawBarCount++;
      }
      int bitPointer = i * 5;
      double byteNum = bitPointer / Constants.byteSize;
      double byteBitOffset = bitPointer - byteNum * Constants.byteSize;
      int currentByteCount = (Constants.byteSize - byteBitOffset).toInt();
      int nextByteRest = 5 - currentByteCount;
      byte = (waveData[byteNum.toInt()] >> byteBitOffset.toInt() &
          ((2 << min(5, currentByteCount) - 1)) - 1);
      if (nextByteRest > 0) {
        byte <<= nextByteRest;
        byte |= waveData[byteNum.toInt() + 1] &
            ((2 << (nextByteRest - 1)) - 1);
      }
      for (int j = 0; j < drawBarCount; j++) {
        int x = barNum * dp(3);
        double left = x.toDouble();
        double top = y.toDouble() +
            dp(visualizerHieght - max(1, visualizerHieght * byte / 31));
        double bottom =
            y.toDouble() + dp(visualizerHieght.toDouble()).toDouble();
        if(x < size.width){
          if (x < denseness && x + dp(2) < denseness) {
            _seekerXPosition = left;
            canvas.drawLine(
                Offset(left, size.height / 2),
                Offset(left, size.height / 2 + (bottom - top) * scaleFactor),
                liveAudioPaint);
            canvas.drawLine(
                Offset(left, size.height / 2),
                Offset(left, size.height / 2 + (top - bottom) * scaleFactor),
                liveAudioPaint);
          } else {
            canvas.drawLine(
                Offset(left, size.height / 2),
                Offset(left,
                    size.height / 2 + ((bottom - top) * animValue) * scaleFactor),
                wavePaint);
            canvas.drawLine(
                Offset(left, size.height / 2),
                Offset(left,
                    size.height / 2 + ((top - bottom) * animValue) * scaleFactor),
                wavePaint);
            if (x < denseness) {
              _seekerXPosition = left;
              canvas.drawLine(
                  Offset(left, size.height / 2),
                  Offset(left, size.height / 2 + (bottom - top) * scaleFactor),
                  liveAudioPaint);
              canvas.drawLine(
                  Offset(left, size.height / 2),
                  Offset(left, size.height / 2 + (top - bottom) * scaleFactor),
                  liveAudioPaint);
            }
          }
        }

        barNum++;
      }
    }
  }

  void _updatePlayerPercent(Size size) {
    denseness = (size.width * scrubberProgress()).ceilToDouble();
    if (denseness < 0) {
      denseness = 0;
    } else if (denseness > size.width) {
      denseness = size.width;
    }
  }

  int dp(double value) {
    if (value == 0) return 0;
    return (density / 2 * value).ceil();
  }

  double scrubberProgress() {
    if (currentDuration / maxDuration > 0.99) {
      return 1.0;
    }
    if (maxDuration == 0) return 0;
    return currentDuration / maxDuration;
  }
}
