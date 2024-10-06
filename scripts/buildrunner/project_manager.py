import asyncio
import logging
from datetime import datetime
from pathlib import Path

from command_runner import CommandRunner
from project_scanner import ProjectScanner
from yaml_project_file import ProjectData, ProjectFile

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %I:%M:%S %p",
)
logger = logging.getLogger(__name__)


class ProjectManager:
    def __init__(self, base_directory: str, yaml_filename: str):
        self.base_directory = Path(base_directory).resolve()
        self.project_file = ProjectFile(yaml_filename)
        self.command_runner = CommandRunner()

    async def run(self):
        existing_data = self.project_file.data

        scanner = ProjectScanner(self.base_directory)
        scanned_data = scanner.scan_projects()

        # Determine what needs to be updated based on the scanned data
        updates_needed, new_data = self.determine_updates(scanned_data, existing_data)

        # Queue commands based on what needs to be updated
        command_futures = self.execute_updates(updates_needed, new_data)

        # Await execution of commands and get the success map
        results: dict[asyncio.Task, bool] = await self.command_runner.execute_commands()

        # Log the results for how many commands succeeded or failed
        logger.info(
            f"Command execution results: {sum(results.values())} succeeded, "
            f"{len(results) - sum(results.values())} failed"
        )

        # Get the current timestamp in ISO format
        now = datetime.now().isoformat()

        # Update timestamps based on the success of each command
        for (project_name, update_type), future in command_futures.items():
            success = results[future]

            # Command succeeded
            if success:
                if update_type == "pub_get":
                    new_data[project_name].last_pub_get = now
                elif update_type == "build_run":
                    new_data[project_name].last_build_run = now
            # Command failed: pub_get
            elif update_type == "pub_get":
                new_data[project_name].last_pub_get = None
            # Command failed: build_run
            elif update_type == "build_run":
                new_data[project_name].last_build_run = None

        # Write out the new data, now with updated timestamps where changes were made
        self.project_file.data = new_data
        self.project_file.save()

    def determine_updates(self, scanned_data, existing_data):
        updates_needed = {}
        new_data = {}
        for project_name, scanned_project in scanned_data.items():
            # Fetch existing project data or initialize if not present
            project = existing_data.get(
                project_name,
                ProjectData(
                    pubspec_path=scanned_project.pubspec_path,
                    pubspec_hash="",
                    last_pub_get=None,
                    last_build_run=None,
                    files={},
                ),
            )

            # Check if pubspec hash or any file hash has changed
            pub_get_dirty = (
                project.pubspec_hash != scanned_project.pubspec_hash
                or project.last_pub_get is None
            )
            build_run_dirty = (
                (
                    any(
                        scanned_project.files.get(f) != project.files.get(f)
                        for f in scanned_project.files
                    )
                    or project.last_build_run is None
                )
                if scanned_project.files
                else False
            )

            # Create new project data including existing timestamps if not dirty
            new_data[project_name] = ProjectData(
                pubspec_path=scanned_project.pubspec_path,
                pubspec_hash=scanned_project.pubspec_hash,
                last_pub_get=project.last_pub_get if not pub_get_dirty else None,
                last_build_run=project.last_build_run if not build_run_dirty else None,
                files=scanned_project.files,
            )

            if pub_get_dirty or build_run_dirty:
                updates_needed[project_name] = {
                    "pub_get": pub_get_dirty,
                    "build_run": build_run_dirty,
                }

        return updates_needed, new_data

    def execute_updates(self, updates_needed, new_data):
        command_futures = {}
        for project_name, flags in updates_needed.items():
            project_data = new_data[project_name]
            project_path = (
                (self.base_directory / project_data.pubspec_path).resolve().parent
            )

            if flags["pub_get"]:
                future = self.command_runner.queue_command(
                    "flutter pub get", f"PubGet-{project_name}", str(project_path)
                )
                command_futures[(project_name, "pub_get")] = future

            if flags["build_run"]:
                future = self.command_runner.queue_command(
                    "dart run build_runner build --delete-conflicting-outputs",
                    f"BuildRun-{project_name}",
                    str(project_path),
                    input_condition={
                        r"Delete these files\?\s+1 - Delete\s+2 - Cancel build\s+3 - List conflicts": "1"
                    },
                )
                command_futures[(project_name, "build_run")] = future

        return command_futures
