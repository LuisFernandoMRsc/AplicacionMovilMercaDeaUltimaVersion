import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:light/light.dart';
import 'package:screen_brightness/screen_brightness.dart';

class AmbientBrightnessService with WidgetsBindingObserver {
	AmbientBrightnessService._();

	static final AmbientBrightnessService instance = AmbientBrightnessService._();

	final ScreenBrightness _screenBrightness = ScreenBrightness();
	final Light _lightSensor = Light();
	StreamSubscription<int>? _subscription;
	bool _initialized = false;
	bool _hasSensor = Platform.isAndroid;
	bool _observerAttached = false;

	Future<void> initialize() async {
		if (_initialized) return;
		_initialized = true;

		if (!_hasSensor) return;

		WidgetsBinding.instance.addObserver(this);
		_observerAttached = true;
		_startListening();
	}

	void _startListening() {
		if (_subscription != null || !_hasSensor) return;
		try {
			_subscription = _lightSensor.lightSensorStream.listen(
				(lux) => _handleLux(lux.toDouble()),
				onError: (_) => _restartLater(),
				cancelOnError: false,
			);
		} catch (_) {
			_hasSensor = false;
			_detachObserver();
		}
	}

	void _restartLater() {
		_subscription?.cancel();
		_subscription = null;
		if (_hasSensor) {
			Future.delayed(const Duration(seconds: 5), _startListening);
		}
	}

	Future<void> _handleLux(double lux) async {
		final brightness = _normalizeLux(lux);
		try {
			await _screenBrightness.setApplicationScreenBrightness(brightness);
		} catch (_) {
			// Ignore errors (permissions or platform limitations)
		}
	}

	double _normalizeLux(double lux) {
		final clamped = lux.clamp(0, 2000);
		const minBrightness = 0.2;
		const maxBrightness = 1.0;
		final normalized = minBrightness + (clamped / 2000) * (maxBrightness - minBrightness);
		return normalized.clamp(minBrightness, maxBrightness);
	}

	void _stopListening() {
		_subscription?.cancel();
		_subscription = null;
	}

	void dispose() {
		_stopListening();
		_detachObserver();
	}

	void _detachObserver() {
		if (!_observerAttached) return;
		WidgetsBinding.instance.removeObserver(this);
		_observerAttached = false;
	}

	@override
	void didChangeAppLifecycleState(AppLifecycleState state) {
		if (!_hasSensor) return;
		if (state == AppLifecycleState.resumed) {
			_startListening();
		} else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
			_stopListening();
		}
	}
}
