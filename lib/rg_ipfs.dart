import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
//import 'package:flutter/foundation.dart';
import 'package:warp_dart/multipass.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/raygun.dart';
import 'package:warp_dart/warp_dart_bindings_generated.dart';

const String _libNameRaygunIpfs = 'warp_rg_ipfs';
String currentPath = Directory.current.path;

final DynamicLibrary raygun_ipfs_dlib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    String currentPath = Directory.current.path;
    return DynamicLibrary.open(
        '$currentPath/macos/new/lib$_libNameRaygunIpfs.dylib');
  }
  if (Platform.isAndroid) {
    return DynamicLibrary.open('lib$_libNameRaygunIpfs.so');
  }
  if (Platform.isLinux) {
    return DynamicLibrary.open('$currentPath/linux/lib$_libNameRaygunIpfs.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('$currentPath/windows/$_libNameRaygunIpfs.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();
final WarpDartBindings _raygun_ipfs_bindings =
    WarpDartBindings(raygun_ipfs_dlib);

Raygun raygun_ipfs_temporary(MultiPass account) {
  Pointer<G_RgIpfsConfig> config =
      _raygun_ipfs_bindings.rg_ipfs_config_testing();

  G_FFIResult_RayGunAdapter result = _raygun_ipfs_bindings
      .warp_rg_ipfs_temporary_new(account.pointer, nullptr, config);

  if (result.error != nullptr) {
    throw WarpException(result.error.cast());
  }

  return Raygun(result.data);
}

Raygun raygun_ipfs_persistent(MultiPass account, String path) {
  G_FFIResult_RgIpfsConfig config = _raygun_ipfs_bindings
      .rg_ipfs_config_production(path.toNativeUtf8().cast<Char>());

  if (config.error != nullptr) {
    throw WarpException(config.error.cast());
  }

  G_FFIResult_RayGunAdapter result = _raygun_ipfs_bindings
      .warp_rg_ipfs_persistent_new(account.pointer, nullptr, config.data);

  if (result.error != nullptr) {
    throw WarpException(result.error.cast());
  }

  return Raygun(result.data);
}
