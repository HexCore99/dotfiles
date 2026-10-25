"""Backend regression tests. All IPC is mocked; no desktop state is changed."""
import importlib.util
import json
from pathlib import Path
from types import SimpleNamespace
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image

spec = importlib.util.spec_from_file_location("wallpaper_backend", Path(__file__).parents[1] / "services/wallpaper_backend.py")
backend = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backend)


class WallpaperTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.folder = self.root / "Wallpapers"
        self.folder.mkdir()
        self.cache = self.root / "cache"
        self.state = self.root / "state" / "state.json"

    def image(self, name="a wallpaper.png", color="red"):
        path = self.folder / name
        path.parent.mkdir(parents=True, exist_ok=True)
        Image.new("RGB", (100, 80), color).save(path)
        return path

    @patch.object(backend, "active_wallpaper", return_value="")
    def test_recursive_catalog_skips_corrupt_and_partial_downloads(self, _):
        self.image("nested/Z image.PNG")
        self.image("a # image, ' quote.png")
        (self.folder / "bad.jpg").write_text("not an image")
        (self.folder / "wallpapers.zip.part").write_text("partial")
        result = backend.catalog(self.folder, self.cache, (80, 45), "eDP-1")
        self.assertEqual([item["name"] for item in result["items"]], ["a # image, ' quote.png", "Z image.PNG"])
        self.assertEqual(result["skipped"], 1)
        self.assertEqual(len(list(self.cache.glob("*.jpg"))), 2)
        for item in result["items"]:
            self.assertTrue(item["thumbnail"].startswith("file:///"))
        for thumbnail in self.cache.glob("*.jpg"):
            with Image.open(thumbnail) as image:
                self.assertEqual(image.size, (80, 45))

    @patch.object(backend, "active_wallpaper", return_value="")
    def test_cache_reused_and_invalidated_when_source_changes(self, _):
        image = self.image()
        first = backend.catalog(self.folder, self.cache, (80, 45), "eDP-1")
        thumbnail = next(self.cache.glob("*.jpg"))
        stamp = thumbnail.stat().st_mtime_ns
        self.assertEqual(first, backend.catalog(self.folder, self.cache, (80, 45), "eDP-1"))
        self.assertEqual(thumbnail.stat().st_mtime_ns, stamp)
        self.image(color="blue")
        second = backend.catalog(self.folder, self.cache, (80, 45), "eDP-1")
        self.assertNotEqual(first["items"][0]["thumbnail"], second["items"][0]["thumbnail"])

    def test_active_state_comes_from_backend_and_resolves_alias(self):
        image = self.image("colon: and space.png")
        alias = self.root / "alias.png"
        alias.symlink_to(image)
        response = SimpleNamespace(returncode=0, stdout=f"DP-1: /other.png\neDP-1: {alias}\n")
        with patch.object(backend, "run", return_value=response):
            self.assertEqual(backend.active_wallpaper("eDP-1"), str(image))
        with patch.object(backend, "run", return_value=SimpleNamespace(returncode=1)):
            self.assertEqual(backend.active_wallpaper("eDP-1"), "")

    def test_apply_uses_argument_array_and_safe_alias_then_saves_original(self):
        image = self.image("a space, ' $(touch NEVER) #.png")
        with patch.object(backend, "ensure_backend"), \
             patch.object(backend, "run", return_value=SimpleNamespace(returncode=0, stdout="", stderr="")) as run, \
             patch.object(backend, "active_wallpaper", return_value=str(image)):
            result = backend.apply_wallpaper(image, "eDP-1", "cover", self.state, self.cache)
        command = run.call_args.args[0]
        self.assertEqual(command[:3], ["hyprctl", "hyprpaper", "wallpaper"])
        self.assertEqual(len(command), 4)
        monitor, alias, fit = command[3].split(",")
        self.assertEqual((monitor, fit), ("eDP-1", "cover"))
        self.assertEqual(Path(alias).resolve(), image)
        self.assertEqual(json.loads(self.state.read_text())["path"], str(image))
        self.assertEqual(result["active"], str(image))
        self.assertTrue((self.state.parent / "current").is_symlink())
        self.assertEqual((self.state.parent / "current").resolve(), image)

    def test_lock_background_pointer_updates_without_copying_wallpaper(self):
        self.state.parent.mkdir(parents=True)
        first = self.image("First wallpaper.png")
        second = self.image("Second wallpaper with spaces.png")
        backend.publish_lock_wallpaper(first, self.state)
        backend.publish_lock_wallpaper(second, self.state)
        pointer = self.state.parent / "current"
        self.assertTrue(pointer.is_symlink())
        self.assertEqual(pointer.resolve(), second)
        self.assertEqual(list(self.state.parent.glob(".current-*")), [])

    def test_failed_apply_preserves_saved_selection(self):
        backend.save_state(self.state, {"path": "previous.png"})
        with patch.object(backend, "ensure_backend"), \
             patch.object(backend, "run", return_value=SimpleNamespace(returncode=1, stdout="error", stderr="")):
            with self.assertRaises(RuntimeError):
                backend.apply_wallpaper(self.image(), "eDP-1", "cover", self.state, self.cache)
        self.assertEqual(backend.read_state(self.state)["path"], "previous.png")

    def test_unconfirmed_apply_does_not_persist(self):
        with patch.object(backend, "ensure_backend"), patch.object(backend.time, "sleep"), \
             patch.object(backend, "run", return_value=SimpleNamespace(returncode=0, stdout="", stderr="")), \
             patch.object(backend, "active_wallpaper", return_value=""):
            with self.assertRaises(RuntimeError):
                backend.apply_wallpaper(self.image(), "eDP-1", "cover", self.state, self.cache)
        self.assertFalse(self.state.exists())

    def test_missing_and_corrupt_images_never_start_backend(self):
        corrupt = self.folder / "broken.png"
        corrupt.write_text("not a picture")
        with patch.object(backend, "ensure_backend") as start:
            for path in [self.folder / "missing.png", corrupt]:
                with self.assertRaises((OSError, ValueError)):
                    backend.apply_wallpaper(path, "eDP-1", "cover", self.state, self.cache)
            start.assert_not_called()

    def test_restore_without_state_does_not_start_backend(self):
        with patch("sys.argv", ["wallpaper_backend.py", "restore", "--state", str(self.state)]), \
             patch.object(backend, "apply_wallpaper") as apply, patch("builtins.print"):
            self.assertEqual(backend.main(), 0)
            apply.assert_not_called()

    def test_restore_reapplies_saved_path_monitor_and_fit(self):
        image = self.image()
        backend.save_state(self.state, {"path": str(image), "monitor": "DP-1", "fit": "contain"})
        with patch("sys.argv", ["wallpaper_backend.py", "restore", "--state", str(self.state)]), \
             patch.object(backend, "apply_wallpaper", return_value={"ok": True}) as apply, patch("builtins.print"):
            self.assertEqual(backend.main(), 0)
            self.assertEqual(apply.call_args.args[:3], (image, "DP-1", "contain"))

    def test_stale_saved_monitor_uses_focused_connected_output(self):
        response = SimpleNamespace(returncode=0, stdout=json.dumps([
            {"name": "HDMI-A-1", "focused": False},
            {"name": "DP-2", "focused": True},
        ]))
        with patch.object(backend, "run", return_value=response):
            self.assertEqual(backend.resolve_monitor("eDP-1"), "DP-2")
            self.assertEqual(backend.resolve_monitor("HDMI-A-1"), "HDMI-A-1")

    def test_apply_rejects_image_outside_collection(self):
        outside = self.root / "outside.png"
        Image.new("RGB", (20, 20), "red").save(outside)
        with patch("sys.argv", ["wallpaper_backend.py", "apply", "--folder", str(self.folder), "--path", str(outside)]), \
             patch.object(backend, "apply_wallpaper") as apply, patch("builtins.print") as output:
            self.assertEqual(backend.main(), 1)
            apply.assert_not_called()
            self.assertIn("no longer in", json.loads(output.call_args.args[0])["error"])

    @patch.object(backend, "active_wallpaper", return_value="")
    def test_stream_shows_first_six_before_finishing_collection(self, _):
        for index in range(30):
            self.image(f"{index:03d}.png")
        packets = []

        def progress(packet):
            packets.append(packet)
            if packet.get("processed") == 6:
                # This callback runs while the remaining images are still uncached.
                self.assertEqual(len(list(self.cache.glob("*.jpg"))), 6)

        result = backend.catalog(self.folder, self.cache, (80, 45), "eDP-1", progress)
        self.assertEqual(packets[0]["event"], "start")
        self.assertEqual(packets[0]["total"], 30)
        batches = [p for p in packets if p["event"] == "batch"]
        self.assertEqual([p["processed"] for p in batches], [6, 24, 30])
        self.assertEqual([item for p in batches for item in p["items"]], result["items"])

    @patch.object(backend, "active_wallpaper", return_value="")
    def test_empty_collection_stream_still_emits_start(self, _):
        packets = []
        result = backend.catalog(self.folder, self.cache, (80, 45), "eDP-1", packets.append)
        self.assertEqual(result["items"], [])
        self.assertEqual(packets, [{"ok": True, "event": "start", "folder": str(self.folder), "total": 0}])


if __name__ == "__main__":
    unittest.main()
