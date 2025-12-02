package com.example.aplicacionmovilmercadea;

import androidx.annotation.NonNull;

import java.io.IOException;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
	private static final String CHANNEL = "com.mercadea/gallery_saver";

	@Override
	public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
		super.configureFlutterEngine(flutterEngine);
		new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
				.setMethodCallHandler(this::handleMethodCall);
	}

	private void handleMethodCall(MethodCall call, MethodChannel.Result result) {
		if ("saveImage".equals(call.method)) {
			byte[] bytes = call.argument("bytes");
			String fileName = call.argument("fileName");
			if (bytes == null || fileName == null || fileName.isEmpty()) {
				result.error("invalid_args", "Bytes o nombre del archivo inválidos", null);
				return;
			}

			String path = saveImage(bytes, fileName);
			if (path.isEmpty()) {
				result.error("save_failed", "No se pudo guardar la imagen", null);
			} else {
				result.success(path);
			}
		} else {
			result.notImplemented();
		}
	}

	private String saveImage(byte[] bytes, String fileName) {
		return "";
	}
}
