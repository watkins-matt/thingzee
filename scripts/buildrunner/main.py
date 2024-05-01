import argparse
import asyncio
import os
import sys

from project_manager import ProjectManager
from project_watcher import ProjectWatcher


def parse_args():
    parser = argparse.ArgumentParser(description="Run the project management script.")
    parser.add_argument("--watch", action="store_true",
                        help="Run in watch mode to monitor file changes.")
    return parser.parse_args()

async def main(base_directory: str, watch: bool):
    loop = asyncio.get_running_loop()
    if watch:
        watcher = ProjectWatcher(base_directory, "project.yaml", loop)
        await watcher.start()
    else:
        project_manager = ProjectManager(base_directory, "project.yaml")
        await project_manager.run()

if __name__ == "__main__":
    args = parse_args()
    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_directory = os.path.join(script_dir, "../../")

    try:
        asyncio.run(main(base_directory, args.watch))
    except KeyboardInterrupt:
        try:
            # Attempt a graceful shutdown
            for task in asyncio.all_tasks():
                task.cancel()
            asyncio.get_event_loop().run_until_complete(asyncio.sleep(0.1))
        except asyncio.CancelledError:
            pass  # Suppress asyncio.CancelledError caused by task cancellations
        finally:
            sys.exit(0)
