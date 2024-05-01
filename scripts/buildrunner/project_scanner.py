import os
import re
from pathlib import Path

import yaml

from file_hasher import FileHasher
from yaml_project_file import ProjectData


class ProjectScanner:
    """Scans directories to find projects and their relevant files."""

    def __init__(self, base_directory: str):
        self.base_directory = Path(base_directory).resolve()

    def scan_projects(self) -> dict:
        """Walk through directories and collect file data, then save it using YamlProjectFile."""
        projects = {}

        for root, dirs, files in os.walk(self.base_directory, topdown=True):
            # Edit the dirs list in-place to skip dot directories
            dirs[:] = [d for d in dirs if not d.startswith('.')]

            if "pubspec.yaml" in files:
                pubspec_path = os.path.normpath(os.path.join(root, "pubspec.yaml"))
                project_name = self.extract_project_name(pubspec_path)

                # Focus only on the 'lib' directory under the current root if it exists
                lib_path = os.path.join(root, "lib")
                all_dart_files = []
                if os.path.exists(lib_path):
                    for subdir, _, subfiles in os.walk(lib_path):
                        # Avoid dot directories in the lib path
                        if subdir.split(os.sep)[-1].startswith('.'):
                            continue

                        all_dart_files.extend(
                            os.path.join(subdir, f)
                            for f in subfiles
                            if f.endswith(".dart")
                        )

                # Process the collected Dart files
                dart_files = self.find_dart_files(root, all_dart_files)

                # Convert file paths in dart_files to be relative for storage
                final_dart_files = {
                    os.path.relpath(file_path, start=self.base_directory): file_hash
                    for file_path, file_hash in dart_files.items()
                }

                project_data = ProjectData(
                    pubspec_path=os.path.relpath(
                        pubspec_path, start=self.base_directory
                    ),
                    pubspec_hash=FileHasher.generate_hash(pubspec_path),
                    files=final_dart_files,
                )

                projects[project_name] = project_data

        return projects

    def find_dart_files(self, directory, all_files):
        """Identify and process .dart files based on associated generated files or part directive."""
        dart_files = {}
        dart_file_paths = [file for file in all_files if file.endswith(".dart")]

        # Split into base and generated files
        base_files = {}
        generated_files = {}

        for file_path in dart_file_paths:
            file_name = os.path.basename(file_path)
            base_name = file_name[:-5]  # Strip the '.dart' extension

            # Check for an additional suffix by checking for last dot before '.dart'
            last_dot_index = base_name.rfind(".")
            if last_dot_index != -1:
                original_base = base_name[:last_dot_index]
                generated_files[original_base] = file_path
            else:
                base_files[base_name] = file_path

        # Match base files with their generated counterparts
        for base_name, base_path in base_files.items():
            if base_name in generated_files:
                dart_files[base_path] = FileHasher.generate_hash(base_path)
            else:
                # Check if the base file contains a part directive
                with open(base_path, "r") as file:
                    content = file.read()
                if re.search(r"part\s+'[\w./]+\.\w+\.dart'", content):
                    dart_files[base_path] = FileHasher.generate_hash(base_path)

        # Handle orphan generated files
        for gen_base_name, gen_path in generated_files.items():
            if gen_base_name not in base_files:
                # Exclude explicitly ignored patterns like '.g.dart'
                if not gen_path.endswith(".g.dart"):
                    dart_files[gen_path] = FileHasher.generate_hash(gen_path)

        return dart_files

    @staticmethod
    def extract_project_name(pubspec_path: str) -> str:
        """Extract the project name from pubspec.yaml."""
        with open(pubspec_path, "r") as file:
            pubspec_data = yaml.safe_load(file)
        return pubspec_data.get("name", "unknown_project")
