#!/usr/bin/env python3
"""Create an installed app shortcut without overwriting desktop files."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile

from test_file_copy import start_daemon, stop_daemon, request


def main():
    binary = os.path.abspath(sys.argv[1])
    with tempfile.TemporaryDirectory(prefix="desktop-shortcut-", dir="/tmp") as directory:
        root = Path(directory)
        home = root / "home"
        desktop = home / "Desktop"
        applications = root / "data" / "applications"
        for path in (desktop, applications, root / "config", root / "cache", root / "runtime"):
            path.mkdir(parents=True, exist_ok=True)
        (root / "runtime").chmod(0o700)

        fixture = applications / "kos-shortcut-fixture.desktop"
        fixture.write_text(
            "[Desktop Entry]\nType=Application\nName=KOS Shortcut Fixture\n"
            "Exec=/usr/bin/true %f\nIcon=application-x-executable\n"
            "Terminal=false\nCategories=Utility;\n"
        )
        fixture.chmod(0o644)
        env = dict(os.environ,
                   HOME=str(home),
                   XDG_CONFIG_HOME=str(root / "config"),
                   XDG_CACHE_HOME=str(root / "cache"),
                   XDG_DATA_HOME=str(root / "data"),
                   XDG_DATA_DIRS=str(root / "data") + ":/usr/local/share:/usr/share",
                   XDG_RUNTIME_DIR=str(root / "runtime"),
                   QT_QPA_PLATFORM="offscreen",
                   QT_QUICK_BACKEND="software")

        rebuilt = subprocess.run(["dbus-run-session", "--", "kbuildsycoca6", "--noincremental"],
                                 env=env, stdout=subprocess.PIPE,
                                 stderr=subprocess.STDOUT, text=True, timeout=30)
        if rebuilt.returncode != 0:
            raise RuntimeError("kbuildsycoca6 failed: " + rebuilt.stdout)

        os.environ.update(env)
        proc, output, ready = start_daemon(binary, str(root / "runtime"))
        try:
            assert ready, output
            sock = str(root / "runtime" / "kos-platform.sock")
            def call(tag):
                return request(sock, tag, "application.desktop-shortcut",
                               {"desktopId": "kos-shortcut-fixture.desktop"})

            occupied = desktop / "kos-shortcut-fixture.desktop"
            occupied.write_text("keep this unrelated file\n")
            first = call("shortcut-create")
            assert first["ok"], first
            shortcut = Path(first["result"]["path"])
            assert shortcut.parent == desktop and shortcut != occupied
            assert shortcut.is_file()
            contents = shortcut.read_text()
            assert "Exec=/usr/bin/true %f" in contents
            assert "X-KOS-SourceDesktopId=kos-shortcut-fixture.desktop" in contents
            assert shortcut.stat().st_mode & 0o100
            assert occupied.read_text() == "keep this unrelated file\n"

            second = call("shortcut-duplicate")
            assert second["ok"] and second["result"]["alreadyExists"], second
            assert Path(second["result"]["path"]) == shortcut
            print("Desktop shortcut creation, duplicate reuse and no-overwrite passed")
        finally:
            stop_daemon(proc, output)


if __name__ == "__main__":
    main()
