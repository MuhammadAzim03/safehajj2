import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class PrayerDayTimes {
  final Map<Prayer, DateTime> times; // Fajr..Isha
  final Prayer? nextPrayer;
  final Duration? timeToNext;

  PrayerDayTimes({required this.times, required this.nextPrayer, required this.timeToNext});

  String timeString(Prayer p) => DateFormat.Hm().format(times[p]!);
}

class PrayerTimeService {
  // Request permission and get current position; fallback to Makkah if denied.
  static Future<Position> _getPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (!serviceEnabled) {
        // Don't throw; we'll fallback to Makkah
      }
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied ||
          !serviceEnabled) {
        return _makkahFallback();
      }
      return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
    } catch (_) {
      // If plugin throws (e.g., missing manifest permission), use fallback
      return _makkahFallback();
    }
  }

  static Position _makkahFallback() => Position(
        longitude: 39.8262,
        latitude: 21.4225,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

  static CalculationParameters _calcParams() {
    // Common, decent default for KSA/Global: Muslim World League
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;
    return params;
  }

  static Future<PrayerDayTimes> getTodayTimes() async {
    final pos = await _getPosition();
    final coords = Coordinates(pos.latitude, pos.longitude);
    final date = DateComponents.from(DateTime.now());
    final params = _calcParams();

    final prayerTimes = PrayerTimes(coords, date, params);

    final Map<Prayer, DateTime> times = {
      Prayer.fajr: prayerTimes.fajr,
      Prayer.sunrise: prayerTimes.sunrise,
      Prayer.dhuhr: prayerTimes.dhuhr,
      Prayer.asr: prayerTimes.asr,
      Prayer.maghrib: prayerTimes.maghrib,
      Prayer.isha: prayerTimes.isha,
    };

    final now = DateTime.now();
    var next = prayerTimes.nextPrayer();
    Duration? until;
    DateTime? nextTime;
    if (next != Prayer.none) {
      nextTime = prayerTimes.timeForPrayer(next);
    } else {
      // After Isha: show countdown to tomorrow's Fajr
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tDate = DateComponents.from(tomorrow);
      final tPrayers = PrayerTimes(coords, tDate, params);
      next = Prayer.fajr;
      nextTime = tPrayers.fajr;
    }

    if (nextTime != null) {
      until = nextTime.difference(now);
      if (until.isNegative) until = Duration.zero;
    }

    return PrayerDayTimes(times: times, nextPrayer: next, timeToNext: until);
  }

  static String prayerName(Prayer p) {
    switch (p) {
      case Prayer.fajr:
        return 'Fajr';
      case Prayer.sunrise:
        return 'Sunrise';
      case Prayer.dhuhr:
        return 'Dhuhr';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
      case Prayer.none:
        return '';
    }
  }
}
