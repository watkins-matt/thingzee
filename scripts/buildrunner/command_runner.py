import asyncio
import logging


class CommandRunner:
    """Handles execution of system commands using asynchronous code."""

    async def run_command(self, command: str):
        """Run a system command asynchronously."""
        process = await asyncio.create_subprocess_shell(
            command, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
        )
        stdout, stderr = await process.communicate()
        if stdout:
            logging.info(f"[STDOUT]\n{stdout.decode()}")
        if stderr:
            logging.error(f"[STDERR]\n{stderr.decode()}")

    async def run_commands(
        self, project_path: str, needs_pub_get: bool, needs_build_runner: bool
    ):
        """Manage the execution of necessary commands asynchronously."""
        tasks = []
        if needs_pub_get:
            tasks.append(self.run_command(f"cd {project_path} && flutter pub get"))
        if needs_build_runner:
            tasks.append(
                self.run_command(f"cd {project_path} && flutter run build_runner build")
            )
        await asyncio.gather(*tasks)
