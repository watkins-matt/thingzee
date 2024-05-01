import argparse
import asyncio
import os

from project_manager import ProjectManager
from project_watcher import ProjectWatcher


def parse_args():
    parser = argparse.ArgumentParser(description="Run the project management script.")
    parser.add_argument("--watch", action="store_true",
                        help="Run in watch mode to monitor file changes.")
    return parser.parse_args()

async def main(base_directory: str, watch: bool):
    if watch:
        watcher = ProjectWatcher(base_directory, "project.yaml")
        watcher.start()  # Block and watch indefinitely until Ctrl+C
    else:
        project_manager = ProjectManager(base_directory, "project.yaml")
        await project_manager.run()

if __name__ == "__main__":
    args = parse_args()
    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_directory = os.path.join(script_dir, "../../")
    if args.watch:
        # Run in watch mode, use synchronous blocking call
        main(base_directory, watch=True)
    else:
        # Run normally in async mode
        asyncio.run(main(base_directory, watch=False))
