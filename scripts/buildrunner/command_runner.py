import asyncio
import logging

logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


class CommandRunner:
    """Handles execution of system commands using asynchronous code,
    allowing tasks to be queued and executed concurrently."""

    def __init__(self):
        self.tasks = []

    async def run_command(self, command: str, tag: str):
        logging.info(f"[{tag}] Starting command: {command}")
        process = await asyncio.create_subprocess_shell(
            command, stdout=asyncio.subprocess.PIPE, stderr=asyncio.subprocess.PIPE
        )

        # Handle stdout
        async for line in process.stdout:
            logging.info(f"[{tag} STDOUT] {line.decode().strip()}")

        # Handle stderr
        async for line in process.stderr:
            logging.error(f"[{tag} STDERR] {line.decode().strip()}")

        await process.wait()  # Ensure the process has completed
        logging.info(f"[{tag}] Completed command: {command}")

    def queue_command(self, command: str, tag: str):
        """Add a command to the queue to be executed."""
        task = asyncio.create_task(self.run_command(command, tag))
        self.tasks.append(task)

    async def execute_commands(self):
        """Execute all queued commands concurrently."""
        if self.tasks:
            await asyncio.gather(*self.tasks)
            self.tasks = []
