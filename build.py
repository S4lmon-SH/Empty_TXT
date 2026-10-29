from pathlib import Path
import argparse
import plistlib
import subprocess

root = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description="Build the Blank TXT Finder extension.")
parser.add_argument("--output", type=Path, required=True, help="Temporary build directory")
build = parser.parse_args().output.resolve()
app = build / "Blank TXT.app"
extension = app / "Contents" / "PlugIns" / "BlankTXTFinder.appex"
for bundle in (app, extension):
    (bundle / "Contents" / "MacOS").mkdir(parents=True, exist_ok=True)
    (bundle / "Contents" / "Resources").mkdir(exist_ok=True)

base = {
    "CFBundleDevelopmentRegion": "ko",
    "CFBundleInfoDictionaryVersion": "6.0",
    "CFBundleSupportedPlatforms": ["MacOSX"],
    "CFBundleShortVersionString": "1.2",
    "CFBundleVersion": "3",
    "LSMinimumSystemVersion": "13.0",
    "NSHighResolutionCapable": True,
}
host = base | {
    "CFBundleIdentifier": "local.codex.blanktxt",
    "CFBundleName": "빈 TXT 만들기",
    "CFBundleDisplayName": "빈 TXT 만들기",
    "CFBundleExecutable": "BlankTXT",
    "CFBundlePackageType": "APPL",
    "NSPrincipalClass": "NSApplication",
    "LSUIElement": True,
    "CFBundleURLTypes": [{
        "CFBundleURLName": "local.codex.blanktxt.create",
        "CFBundleURLSchemes": ["codex-blanktxt"],
        "CFBundleTypeRole": "Editor",
    }],
}
plugin = base | {
    "CFBundleIdentifier": "local.codex.blanktxt.finder",
    "CFBundleName": "빈 TXT 만들기",
    "CFBundleDisplayName": "빈 TXT 만들기",
    "CFBundleExecutable": "BlankTXTFinder",
    "CFBundlePackageType": "XPC!",
    "NSExtension": {
        "NSExtensionAttributes": {},
        "NSExtensionPointIdentifier": "com.apple.FinderSync",
        "NSExtensionPrincipalClass": "BlankTXTFinder",
    },
}
for bundle, info in ((app, host), (extension, plugin)):
    (bundle / "Contents" / "Info.plist").write_bytes(plistlib.dumps(info))
(app / "Contents" / "PkgInfo").write_bytes(b"APPL????")
entitlements = build / "finder.entitlements"
entitlements.write_bytes(plistlib.dumps({"com.apple.security.app-sandbox": True}))
common = ["xcrun", "clang", "-fobjc-arc", "-O2", "-Wall", "-Wextra",
          "-Wno-unused-parameter", "-mmacosx-version-min=13.0", "-framework", "Cocoa",
          "-framework", "FinderSync"]
subprocess.run(common + [str(root / "src" / "BlankTXT.m"), "-o", str(app / "Contents" / "MacOS" / "BlankTXT")], check=True)
subprocess.run(common + ["-fapplication-extension", "-e", "_NSExtensionMain",
                        str(root / "src" / "BlankTXTFinder.m"), "-o", str(extension / "Contents" / "MacOS" / "BlankTXTFinder")], check=True)
subprocess.run(["codesign", "--force", "--sign", "-", "--entitlements", str(entitlements), str(extension)], check=True)
subprocess.run(["codesign", "--force", "--sign", "-", str(app)], check=True)
subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
print(app)
