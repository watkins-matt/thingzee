from datetime import datetime
from pathlib import Path

from command_runner import CommandRunner
from project_scanner import ProjectScanner
from yaml_project_file import ProjectData, ProjectFile


class ProjectManager:
    def __init__(self, base_directory: str, yaml_filename: str):
        self.base_directory = base_directory
        self.project_file = ProjectFile(yaml_filename)
        self.command_runner = CommandRunner()

    async def run(self):
        existing_data = self.project_file.data

        scanner = ProjectScanner(self.base_directory)
        scanned_data = scanner.scan_projects()

        # Determine what needs to be updated based on the scanned data
        updates_needed, new_data = self.determine_updates(scanned_data, existing_data)

        # Queue commands based on what needs to be updated
        await self.execute_updates(updates_needed, new_data)

        # Write out the new data, now with updated timestamps where changes were made
        self.project_file.data = new_data
        self.project_file.save()

    def determine_updates(self, scanned_data, existing_data):
        updates_needed = {}
        new_data = {}
        for project_name, scanned_project in scanned_data.items():
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

            # Assume dirty if new or hashes differ
            pub_get_dirty = (
                project.pubspec_hash != scanned_project.pubspec_hash
                or project.last_pub_get is None
            )
            build_run_dirty = (
                any(
                    scanned_project.files.get(f) != project.files.get(f)
                    for f in scanned_project.files
                )
                or project.last_build_run is None
            )

            # Update the project with scanned data for later saving
            new_data[project_name] = scanned_project

            if pub_get_dirty or build_run_dirty:
                updates_needed[project_name] = {
                    "pub_get": pub_get_dirty,
                    "build_run": build_run_dirty,
                }

        return updates_needed, new_data

    async def execute_updates(self, updates_needed, new_data):
        now = datetime.now().isoformat()
        for project_name, flags in updates_needed.items():
            project_data = new_data[project_name]
            project_path = Path(project_data.pubspec_path).parent.resolve()

            if flags["pub_get"]:
                self.command_runner.queue_command(
                    f"cd {project_path} && flutter pub get", f"PubGet-{project_name}"
                )
                project_data.last_pub_get = (
                    now  # Update the timestamp after command execution
                )

            if flags["build_run"]:
                self.command_runner.queue_command(
                    f"cd {project_path} && flutter run build_runner build",
                    f"Build-{project_name}",
                )
                project_data.last_build_run = (
                    now  # Update the timestamp after command execution
                )
