import logging
import time

from watchdog.observers import Observer

from change_handler import ChangeHandler
from project_manager import ProjectManager

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %I:%M:%S %p",
)
logger = logging.getLogger(__name__)


class ProjectWatcher:
    def __init__(self, base_directory: str, yaml_filename: str):
        self.base_directory = base_directory
        self.yaml_filename = yaml_filename

    def start(self):
        """Starts the directory watcher and runs the project manager on changes."""
        self.project_manager = ProjectManager(self.base_directory, self.yaml_filename)
        event_handler = ChangeHandler(self.project_manager)

        observer = Observer()
        observer.schedule(event_handler, self.base_directory, recursive=True)
        observer.start()

        logger.info("Watcher started. Monitoring for changes...")
        logger.info(f"Monitoring started in: {self.base_directory}")
        logger.info("Press Ctrl+C to stop.")

        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            logger.info("Watcher stopped by user.")
            observer.stop()

        observer.join()
        logger.info("Watcher has been cleanly shutdown.")
