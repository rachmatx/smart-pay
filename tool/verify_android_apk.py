"""Verify the release contains required native plugins, not only Dart code.
Usage: python tool/verify_android_apk.py path/to/app-release.apk
Run Android SDK apksigner/zipalign separately to verify signatures/alignment.
"""
import sys
import zipfile
from pathlib import Path

apk = Path(sys.argv[1])
required = [
    b'Lio/flutter/plugins/GeneratedPluginRegistrant;',
    b'Lcom/it_nomads/fluttersecurestorage/FlutterSecureStoragePlugin;',
    b'Ldev/steenbakker/mobile_scanner/MobileScannerPlugin;',
    b'Lio/flutter/plugins/localauth/LocalAuthPlugin;',
]
with zipfile.ZipFile(apk) as archive:
    dex = b''.join(archive.read(n) for n in archive.namelist() if n.endswith('.dex'))
    missing = [name.decode() for name in required if name not in dex]
    if missing:
        raise SystemExit('Missing native registration/classes: ' + ', '.join(missing))
    libraries = [n for n in archive.namelist() if n.startswith('lib/') and n.endswith('.so')]
    if not any('arm64-v8a' in n and 'jni' in n for n in libraries):
        raise SystemExit('ARM64 JNI library missing')
print('Native plugin registration, secure storage, scanner, biometrics and ARM64 JNI present.')
