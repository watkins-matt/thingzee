import os

import yaml

from file_hasher import FileHasher
from yaml_project_file import ProjectData, ProjectFile


class ProjectScanner:
    """Scans directories to find projects and their relevant files."""

    def __init__(self, base_directory: str, yaml_project_file: ProjectFile):
        self.base_directory = base_directory
        self.yaml_project_file = yaml_project_file

    def scan_projects(self):
        """Walk through directories and collect file data, then save it using YamlProjectFile."""
        for root, _dirs, files in os.walk(self.base_directory):
            if "pubspec.yaml" in files:
                pubspec_path = os.path.normpath(os.path.join(root, "pubspec.yaml"))
                project_name = self.extract_project_name(pubspec_path)

                # Focus only on the 'lib' directory under the current root if it exists
                lib_path = os.path.join(root, "lib")
                all_dart_files = []
                if os.path.exists(lib_path):
                    for subdir, _, subfiles in os.walk(lib_path):
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
                self.yaml_project_file.update_project_data(project_name, project_data)

    def find_dart_files(self, directory, all_files):
        """Identify and process .dart files based on associated generated files."""
        dart_files = {}
        dart_file_paths = [file for file in all_files if file.endswith(".dart")]

        # Extract base and generated filenames
        base_files = {}
        generated_files = {}

        for file_path in dart_file_paths:
            # Strip the directory and '.dart' suffix to simplify further processing
            base_name = os.path.basename(file_path)[:-5]
            # Identify if there's an additional suffix indicating it's a generated file
            if "." in base_name:
                # It's a generated file, remove the last part to get the original base filename
                original_base = base_name.rsplit(".", 1)[0]
                generated_files[original_base] = file_path
            else:
                # It's a base file
                base_files[base_name] = file_path

        # Check for base files that have a corresponding generated version
        for base_name, base_path in base_files.items():
            if base_name in generated_files:
                # Add the base file since it has a generated counterpart
                dart_files[base_path] = FileHasher.generate_hash(base_path)

        # Check for orphan generated files
        for gen_base_name, gen_path in generated_files.items():
            if gen_base_name not in base_files and not gen_base_name.endswith(".g"):
                # It's an orphan generated file
                dart_files[gen_path] = FileHasher.generate_hash(gen_path)

        return dart_files

    @staticmethod
    def extract_project_name(pubspec_path: str) -> str:
        """Extract the project name from pubspec.yaml."""
        with open(pubspec_path, "r") as file:
            pubspec_data = yaml.safe_load(file)
        return pubspec_data.get("name", "unknown_project")