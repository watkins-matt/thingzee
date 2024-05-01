import asyncio
import logging
import time
from asyncio import AbstractEventLoop

from watchdog.events import FileSystemEventHandler

from project_manager import ProjectManager

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %I:%M:%S %p",
)
logger = logging.getLogger(__name__)

class ChangeHandler(FileSystemEventHandler):
    """Handles filesystem events by re-running the project manager
    on changes to specific files, with debouncing."""

    def __init__(self, project_manager: ProjectManager, loop: AbstractEventLoop):
        self.project_manager = project_manager
        self.loop = loop
        self.last_run = 0
        self.debounce_delay = 10  # seconds
        self.debouncing = False
        self.last_path = ""

    def on_modified(self, event):
        """Called when a file or directory is modified."""
        # We only care about changes to pubspec.yaml and .dart files
        if event.is_directory or not (
            event.src_path.endswith("pubspec.yaml") or event.src_path.endswith(".dart")
        ):
            return

        # We don't want to re-run the project manager on generated files
        if event.src_path.endswith(".merge.dart") or event.src_path.endswith(".g.dart"):
            return

        current_time = time.time()
        if current_time - self.last_run < self.debounce_delay:
            if not self.debouncing:
                logger.info(f"Change detected in {event.src_path},"
                            " but waiting due to debounce delay.")
                self.debouncing = True
                self.last_path = event.src_path
            return

        if self.debouncing:
            logger.info(f"Debounce period is over, now processing change in {self.last_path}.")
            self.debouncing = False

        logger.info(f"Detected change in: {event.src_path}, scheduling project manager run.")
        self.loop.call_soon_threadsafe(self.schedule_run)
        self.last_run = current_time

    def schedule_run(self):
        """Schedule the project manager run using asyncio's event loop."""
        asyncio.run_coroutine_threadsafe(self.project_manager.run(), self.loop)
