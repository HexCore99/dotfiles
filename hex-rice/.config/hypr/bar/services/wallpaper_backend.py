#!/usr/bin/env python3
"""Wallpaper I/O only: thumbnails, Hyprpaper IPC, and atomic login state.

QML calls this with argument arrays and consumes one JSON result per invocation.
No filenames enter a shell. Safe symlinks also avoid Hyprpaper's comma delimiter.
Requires the already installed Hyprpaper 0.8+ and Python Pillow.
"""
import argparse
import fcntl
import hashlib
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time

from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[2]
STATE = ROOT / "wallpaper" / "state.json"
CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "hypr-wallpapers"
EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}


def run(args):
    return subprocess.run(args, capture_output=True, text=True, timeout=8, check=False)


def read_state(path):
    try:
        data = json.loads(path.read_text())
        return data if isinstance(data, dict) else {}
    except (OSError, ValueError):
        return {}


def save_state(path, data):
    # Rename only after a successful backend change, keeping the last good choice.
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        try:
            json.dump(data, stream, ensure_ascii=True)
            stream.flush()
            os.fsync(stream.fileno())
        except BaseException:
            temporary.unlink(missing_ok=True)
            raise
    try:
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def fingerprint(path):
    stat = path.stat()
    return hashlib.sha256(os.fsencode(str(path)) + f"/{stat.st_mtime_ns}/{stat.st_size}".encode()).hexdigest()


def publish_lock_wallpaper(path, state):
    """Expose the chosen source to native Hyprlock without JSON parsing at lock time."""
    pointer = state.parent / "current"
    temporary = state.parent / f".current-{os.getpid()}"
    try:
        temporary.symlink_to(path)
        temporary.replace(pointer)
    finally:
        temporary.unlink(missing_ok=True)


def active_wallpaper(monitor):
    """Query actual backend state, not the remembered selection (which may be stale)."""
    result = run(["hyprctl", "hyprpaper", "listactive"])
    if result.returncode:
        return ""
    for line in result.stdout.splitlines():
        name, separator, image = line.partition(": ")
        if separator and name.strip() == monitor:
            return str(Path(image.strip()).resolve())
    return ""


def available_monitors():
    """Return connected output names, putting the focused output first."""
    result = run(["hyprctl", "monitors", "-j"])
    if result.returncode:
        return []
    try:
        monitors = json.loads(result.stdout)
        if not isinstance(monitors, list):
            return []
        monitors = [item for item in monitors if isinstance(item, dict) and item.get("name")]
        monitors.sort(key=lambda item: not item.get("focused", False))
        return [item["name"] for item in monitors]
    except (ValueError, TypeError, KeyError):
        return []


def resolve_monitor(requested):
    monitors = available_monitors()
    if requested in monitors:
        return requested
    if monitors:
        return monitors[0]
    if requested:
        return requested
    raise RuntimeError("No connected Hyprland monitor was found.")


def catalog(folder, cache, size, monitor, progress=None):
    if not folder.is_dir():
        raise ValueError(f"Wallpaper folder does not exist: {folder}")
    cache.mkdir(parents=True, exist_ok=True)
    candidates = []
    # os.walk does not follow directory symlinks; nested collections are supported.
    for directory, dirs, names in os.walk(folder):
        dirs[:] = sorted(d for d in dirs if not d.startswith("."))
        for name in names:
            source = Path(directory) / name
            if source.suffix.lower() not in EXTENSIONS or name.startswith("."):
                continue
            candidates.append(source)
    candidates.sort(key=lambda path: (path.name.casefold(), str(path)))
    entries, batch, skipped = [], [], 0
    if progress:
        progress({"ok": True, "event": "start", "folder": str(folder), "total": len(candidates)})
    for processed, candidate in enumerate(candidates, 1):
        try:
            source = candidate.resolve(strict=True)
            thumbnail = cache / f"{fingerprint(source)}-{size[0]}x{size[1]}.jpg"
            if not thumbnail.exists():
                with Image.open(source) as image:
                    # JPEG can decode at reduced resolution. Shrink other formats
                    # before copying/orienting/converting full-size pixel buffers.
                    image.draft("RGB", size)
                    image.thumbnail((size[0] * 2, size[1] * 2), Image.Resampling.LANCZOS, reducing_gap=3)
                    image = ImageOps.exif_transpose(image)
                    image = ImageOps.fit(image.convert("RGB"), size, Image.Resampling.LANCZOS)
                    with tempfile.NamedTemporaryFile(dir=cache, suffix=".jpg", delete=False) as stream:
                        temporary = Path(stream.name)
                    try:
                        image.save(temporary, "JPEG", quality=85)
                        temporary.replace(thumbnail)
                    finally:
                        temporary.unlink(missing_ok=True)
            item = {"path": str(source), "name": candidate.name, "thumbnail": thumbnail.as_uri()}
            entries.append(item)
            batch.append(item)
        except (OSError, ValueError, Image.DecompressionBombError):
            skipped += 1
        # The first screen arrives after six images. Later batches append without
        # resetting the grid, so scrolling/selection work during a large first scan.
        if progress and (processed == 6 or processed % 24 == 0 or processed == len(candidates)):
            progress({"ok": True, "event": "batch", "items": batch,
                      "processed": processed, "skipped": skipped})
            batch = []
    return {"ok": True, "items": entries, "folder": str(folder), "skipped": skipped,
            "active": active_wallpaper(monitor)}


def ensure_backend():
    if run(["hyprctl", "hyprpaper", "listactive"]).returncode == 0:
        return
    # Start only on first apply or a saved login restore. Never kill another backend.
    runtime = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "hypr-minimal"
    runtime.mkdir(parents=True, exist_ok=True)
    with (runtime / "hyprpaper.log").open("a") as log:
        child = subprocess.Popen(["hyprpaper", "--config", str(ROOT / "wallpaper" / "hyprpaper.conf")],
                                 stdout=log, stderr=log, start_new_session=True, close_fds=True)
    for _ in range(40):
        if run(["hyprctl", "hyprpaper", "listactive"]).returncode == 0:
            return
        if child.poll() is not None:
            break
        time.sleep(0.1)
    raise RuntimeError(f"Hyprpaper did not become ready. See {runtime / 'hyprpaper.log'}")


def apply_wallpaper(path, monitor, fit, state, cache):
    path = path.expanduser().resolve(strict=True)
    if path.suffix.lower() not in EXTENSIONS:
        raise ValueError("Choose a JPG, PNG, WebP or BMP image.")
    with Image.open(path) as image:
        image.verify()
    # Serialize login restore and clicks, including daemon startup and state writes.
    state.parent.mkdir(parents=True, exist_ok=True)
    with (state.parent / "apply.lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        cache.mkdir(parents=True, exist_ok=True)
        alias = cache / (fingerprint(path) + path.suffix.lower())
        if not alias.exists():
            alias.symlink_to(path)
        if any(char in str(alias) + monitor for char in ",\n\r"):
            raise ValueError("The cache directory and monitor name must not contain commas or newlines.")
        ensure_backend()
        result = run(["hyprctl", "hyprpaper", "wallpaper", f"{monitor},{alias},{fit}"])
        if result.returncode or "error" in result.stdout.lower():
            raise RuntimeError((result.stderr or result.stdout).strip() or "Hyprpaper rejected this image.")
        # Hyprpaper decodes asynchronously; don't mark a rejected image active.
        for _ in range(30):
            if active_wallpaper(monitor) == str(path):
                save_state(state, {"path": str(path), "monitor": monitor, "fit": fit})
                publish_lock_wallpaper(path, state)
                return {"ok": True, "active": str(path)}
            time.sleep(0.1)
        raise RuntimeError("Hyprpaper did not confirm the new wallpaper; the saved choice was kept.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["list", "status", "apply", "restore"])
    parser.add_argument("--folder", default="~/Pictures/Wallpapers")
    parser.add_argument("--path", default="")
    parser.add_argument("--monitor", default="")
    parser.add_argument("--fit", choices=["cover", "contain", "tile", "fit"], default="cover")
    parser.add_argument("--width", type=int, default=480)
    parser.add_argument("--height", type=int, default=270)
    parser.add_argument("--stream", action="store_true", help="Emit incremental thumbnail batches for QML")
    parser.add_argument("--state", type=Path, default=STATE)
    parser.add_argument("--cache", type=Path, default=CACHE)
    args = parser.parse_args()
    try:
        if args.action == "list":
            if not 1 <= args.width <= 2048 or not 1 <= args.height <= 2048:
                raise ValueError("Thumbnail dimensions must be between 1 and 2048.")
            emit = (lambda packet: print(json.dumps(packet, ensure_ascii=True), flush=True)) if args.stream else None
            result = catalog(Path(args.folder).expanduser().resolve(), args.cache,
                             (args.width, args.height), resolve_monitor(args.monitor), emit)
            if args.stream:
                del result["items"]
                result["event"] = "complete"
        elif args.action == "status":
            result = {"ok": True, "active": active_wallpaper(resolve_monitor(args.monitor))}
        elif args.action == "restore":
            saved = read_state(args.state)
            result = apply_wallpaper(Path(saved["path"]), resolve_monitor(saved.get("monitor", args.monitor)),
                                     saved.get("fit", "cover"), args.state, args.cache) if saved.get("path") else {"ok": True, "active": ""}
        else:
            path = Path(args.path).expanduser().resolve(strict=True)
            folder = Path(args.folder).expanduser().resolve(strict=True)
            # Entries are resolved during scanning, allowing collections of image symlinks.
            if not any(path == entry.resolve() for entry in folder.rglob("*") if entry.is_file()):
                raise ValueError("This image is no longer in the configured wallpaper folder. Refresh the grid.")
            result = apply_wallpaper(path, resolve_monitor(args.monitor), args.fit, args.state, args.cache)
        # Terminal theming is optional and asynchronous: selecting a wallpaper
        # stays responsive even while pywal extracts colors from a large image.
        if args.action in {"apply", "restore"} and result.get("active"):
            theme = ROOT / "scripts" / "terminal-theme"
            if theme.is_file():
                try:
                    runtime = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "hypr-minimal"
                    runtime.mkdir(parents=True, exist_ok=True)
                    with (runtime / "terminal-theme.log").open("a") as log:
                        subprocess.Popen(["sh", str(theme)], stdout=log, stderr=log,
                                         start_new_session=True, close_fds=True)
                except OSError:
                    pass  # A terminal theme failure must not fail wallpaper selection.
        print(json.dumps(result, ensure_ascii=True), flush=True)
        return 0
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError, Image.DecompressionBombError) as error:
        print(json.dumps({"ok": False, "error": str(error)}, ensure_ascii=True), flush=True)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
