import os
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Optional

import yaml


@dataclass
class ProjectData:
    pubspec_path: str
    pubspec_hash: str
    last_pub_get: Optional[str] = None
    last_build_run: Optional[str] = None
    files: Dict[str, str] = field(default_factory=dict)  # Change to dictionary


class ProjectFile:
    """Manages reading, writing, and updating project
    data in YAML format using structured data."""

    def __init__(self, filename: str):
        self.filename = self.find_file_path(filename)
        self.data: Dict[str, ProjectData] = self.load()

    def find_file_path(self, filename: str) -> str:
        """Find the path to the project file in the script or current working directory."""
        current_path = Path(filename)
        if current_path.is_absolute():
            return str(current_path)

        # Check script directory and current working directory
        script_directory = Path(__file__).parent
        script_dir_path = script_directory / filename
        current_dir_path = Path.cwd() / filename

        if script_dir_path.exists():
            return str(script_dir_path)
        elif current_dir_path.exists():
            return str(current_dir_path)

        # Default to using the path in the script directory if file does not exist
        return str(script_dir_path)

    def load(self) -> Dict[str, ProjectData]:
        """Load YAML data from the file, converting it to structured data."""
        if os.path.exists(self.filename):
            with open(self.filename, "r") as file:
                raw_data = yaml.safe_load(file) or {}
                return {
                    k: ProjectData(
                        pubspec_path=v.get("pubspec_path", ""),
                        pubspec_hash=v.get("pubspec_hash", ""),
                        last_pub_get=v.get("last_pub_get"),
                        last_build_run=v.get("last_build_run"),
                        files=v.get("files", {}),
                    )
                    for k, v in raw_data.items()
                }
        else:
            return {}

    def update_project_data(self, project_name: str, project_data: ProjectData):
        """Update project data in memory."""
        self.data[project_name] = project_data

    def save(self):
        """Save the current data to the YAML file."""
        with open(self.filename, "w") as file:
            yaml.dump(
                {
                    k: {
                        "pubspec_path": v.pubspec_path,
                        "pubspec_hash": v.pubspec_hash,
                        **({"last_pub_get": v.last_pub_get} if v.last_pub_get else {}),
                        **(
                            {"last_build_run": v.last_build_run}
                            if v.last_build_run
                            else {}
                        ),
                        **({"files": v.files} if v.files else {}),
                    }
                    for k, v in self.data.items()
                },
                file,
                sort_keys=False,
                default_flow_style=False,
            )
