import asyncio
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %I:%M:%S %p",
)
logger = logging.getLogger(__name__)


class CommandRunner:
    """Handles execution of system commands using asynchronous code,
    allowing tasks to be queued and executed concurrently."""

    def __init__(self):
        self.tasks: list[asyncio.Task] = []

    async def run_command(self, command: str, tag: str, cwd: str | None = None) -> bool:
        """Run a system command with the specified tag and optional working directory."""
        logger.info(
            f"[{tag}] Starting command: {command} in {cwd if cwd else 'default directory'}"
        )
        process = await asyncio.create_subprocess_shell(
            command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            cwd=cwd,  # Set the working directory
        )

        # Handle stdout
        async for line in process.stdout:
            logger.info(f"[{tag}] {line.decode().strip()}")

        # Handle stderr
        async for line in process.stderr:
            logger.error(f"[{tag}] {line.decode().strip()}")

        await process.wait()  # Ensure the process has completed

        if process.returncode == 0:
            logger.info(f"[{tag}] Success: {command}")
        else:
            logger.error(f"[{tag}] Failure: {command}")

        return process.returncode == 0

    def queue_command(
        self, command: str, tag: str, cwd: str | None = None
    ) -> asyncio.Task:
        """Add a command with a tag and optional working directory to the queue to be executed."""
        task = asyncio.create_task(self.run_command(command, tag, cwd))
        self.tasks.append(task)
        return task

    async def execute_commands(self) -> dict[asyncio.Task, bool]:
        """Execute all queued commands and return a map of tasks to their success status."""
        results = await asyncio.gather(*self.tasks, return_exceptions=True)
        task_success_mapping = {
            task: not isinstance(result, Exception) and result
            for task, result in zip(self.tasks, results, strict=True)
        }
        self.tasks = []  # Clear tasks after execution
        return task_success_mapping
