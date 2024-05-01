import asyncio
import os

from project_manager import ProjectManager


async def main(base_directory: str):
    project_manager = ProjectManager(base_directory, "project.yaml")
    await project_manager.run()


if __name__ == "__main__":
    # Get the absolute directory of the script
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Adjust relative path
    base_directory = os.path.join(script_dir, "../../")
    asyncio.run(main(base_directory))
