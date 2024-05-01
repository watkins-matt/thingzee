import asyncio
import os

from project_scanner import ProjectScanner
from yaml_project_file import ProjectFile


async def main(base_directory: str):
    yaml_project_file = ProjectFile("project.yaml")
    scanner = ProjectScanner(base_directory, yaml_project_file)
    scanner.scan_projects()

    # Run commands depending on the project data


if __name__ == "__main__":
    # Get the absolute directory of the script
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Adjust relative path
    base_directory = os.path.join(script_dir, "../../")
    asyncio.run(main(base_directory))
