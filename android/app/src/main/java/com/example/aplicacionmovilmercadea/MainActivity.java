package com.example.aplicacionmovilmercadea;

import android.content.ContentResolver;
import android.content.ContentValues;
import android.media.MediaScannerConnection;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;

import androidx.annotation.NonNull;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

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

			try {
				String path = saveImage(bytes, fileName);
				result.success(path);
			} catch (IOException e) {
				result.error("save_failed", e.getMessage(), null);
			}
		} else {
			result.notImplemented();
		}
	}

	private String saveImage(byte[] bytes, String fileName) throws IOException {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			ContentValues values = new ContentValues();
			values.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, fileName);
			values.put(android.provider.MediaStore.MediaColumns.MIME_TYPE, "image/png");
			values.put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH,
					Environment.DIRECTORY_PICTURES + "/qr_ventas");

			ContentResolver resolver = getApplicationContext().getContentResolver();
			Uri uri = resolver.insert(android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values);
			if (uri == null) {
				throw new IOException("No se pudo insertar en MediaStore");
			}

			try (OutputStream stream = resolver.openOutputStream(uri)) {
				if (stream == null) {
					throw new IOException("No se pudo abrir el flujo de salida");
				}
				stream.write(bytes);
			}
			return uri.toString();
		} else {
			File pictures = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES);
			File folder = new File(pictures, "qr_ventas");
			if (!folder.exists() && !folder.mkdirs()) {
				throw new IOException("No se pudo crear la carpeta de destino");
			}

			File file = new File(folder, fileName);
			try (FileOutputStream stream = new FileOutputStream(file)) {
				stream.write(bytes);
			}

			MediaScannerConnection.scanFile(
					getApplicationContext(),
					new String[]{file.getAbsolutePath()},
					null,
					null
			);

			return file.getAbsolutePath();
		}
	}
}
