# Empty_TXT

**English** | [한국어](README.ko.md)

A small macOS tool that **creates an empty TXT file when you right-click empty space inside a Finder folder**.

Choose **빈 TXT 만들기** ("Create Empty TXT") from the context menu to create and select `새 텍스트 파일.txt`. The file contains no data (0 bytes). If that name already exists, the app adds a number, such as `새 텍스트 파일 2.txt`, without overwriting existing files.

The menu label and default filenames are currently in Korean.

## Installation

Requirements: a Mac with macOS 13 or later, Python 3.9 or later, and Apple Command Line Tools. The app is built for the CPU architecture of the Mac that runs the build. Other macOS versions and Intel Macs require separate validation; see [Verified behavior](#verified-behavior) for the tested environment.

```bash
git clone https://github.com/S4lmon-SH/Empty_TXT.git
cd Empty_TXT
python3 build.py --output ./build
```

1. Move the generated `build/Blank TXT.app` into **Applications**.
2. Open the app once to register and enable its Finder extension.
3. Open a folder in Finder, right-click empty space, and choose **빈 TXT 만들기**.

If Command Line Tools are missing, install them first with `xcode-select --install`. This repository distributes source code for local builds, not a distribution-signed or notarized installer.

## Optional: right-click a folder icon

`extras/빈 TXT 만들기.workflow` is an optional Automator Quick Action. Double-click it in Finder to install it, then use **Right-click a folder icon → Quick Actions → 빈 TXT 만들기**.

The Finder extension for empty space and the Quick Action for folder icons work independently.

## How it works

An Automator Quick Action alone cannot add an item to Finder's empty-space context menu, so this tool uses Apple's [Finder Sync](https://developer.apple.com/documentation/findersync) extension API.

```text
Right-click empty space inside a folder
  → The Finder extension displays the menu and icon
  → Selecting the command passes the current folder to the host app
  → The app creates an empty TXT file and exits
```

The icon is drawn using the current theme's text color whenever the menu opens. File creation uses an exclusive "create a new file" operation, so an existing file or symbolic link with the same name is never overwritten.

| File | Purpose |
| --- | --- |
| `src/BlankTXTFinder.m` | Empty-space context menu and icon |
| `src/BlankTXT.m` | File creation, selection of the new file, and extension reactivation |
| `build.py` | App bundle assembly, compilation, local signing, and signature verification |
| `extras/빈 TXT 만들기.workflow` | Optional Quick Action for folder icons |

## System impact

| Area | Impact |
| --- | --- |
| System changes | Adds the app and its Finder extension registration. Does not modify macOS or Finder's original files. |
| Processes | Finder extension processes may remain idle. The host app opens when the menu command runs and exits afterward. |
| Folder access | Registers the root directory to offer the menu across folders, but does not traverse folder trees or read existing document contents. |
| Permissions | The menu extension is sandboxed; the host app runs with normal user permissions. The code does not elevate privileges or grant Full Disk Access. |
| Network | No internet communication, data collection, or automatic updates. |
| Automatic startup | Does not add separate login items, scheduled tasks, or LaunchAgents. macOS manages the Finder extension. |

A snapshot in the development environment showed two extension processes, each at 0% CPU, with a combined reported RSS of about 53 MiB. RSS can count shared memory more than once; this is not a guarantee of actual additional memory use or resource usage on other Macs.

## If the menu is missing

Open `Blank TXT.app` in Applications again to register and enable the extension. Remove duplicate test copies of the app from other locations, then close and reopen the context menu.

## Uninstallation

Disable and unregister the extension in Terminal:

```bash
pluginkit -e ignore -i local.codex.blanktxt.finder
pluginkit -r "/Applications/Blank TXT.app/Contents/PlugIns/BlankTXTFinder.appex"
```

Then move `Blank TXT.app` from Applications to the Trash. If you also installed the optional Quick Action, remove `~/Library/Services/빈 TXT 만들기.workflow`. TXT files you already created are kept.

## Verified behavior

Verified on macOS 26.6.2 / Apple Silicon: build and signature verification, 0-byte file creation, numbered filenames on collisions, protection of existing files and symbolic links, the actual Finder empty-space menu command, and icon rendering in dark mode. Not all macOS versions or environments have been tested.
