import asyncio
import logging
import time

from watchdog.events import FileSystemEventHandler

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %I:%M:%S %p",
)
logger = logging.getLogger(__name__)


class ChangeHandler(FileSystemEventHandler):
    """Handles filesystem events by re-running the project manager
    on changes to specific files, with debouncing."""

    def __init__(self, project_manager):
        self.project_manager = project_manager
        self.last_run = 0
        self.debounce_delay = 10  # seconds

    def on_modified(self, event):
        """Called when a file or directory is modified."""
        if event.is_directory or not (
            event.src_path.endswith("pubspec.yaml") or event.src_path.endswith(".dart")
        ):
            return

        current_time = time.time()
        if current_time - self.last_run < self.debounce_delay:
            logger.info("Change detected but waiting due to debounce delay.")
            return

        logger.info(f"Detected change in: {event.src_path}, running project manager.")
        asyncio.run(self.project_manager.run())
        self.last_run = current_time
