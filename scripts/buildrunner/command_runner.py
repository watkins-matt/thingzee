import asyncio
import logging
import re
from collections import deque
from typing import Dict, List, Optional

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %I:%M:%S %p",
)
logger = logging.getLogger(__name__)


class CommandRunner:
    """
    A class for asynchronously running shell commands with the ability to
    automatically respond to prompts in the command output.
    """

    def __init__(self):
        """Initialize the CommandRunner with an empty list of tasks."""
        self.tasks: List[asyncio.Task] = []

    async def read_stream(
        self,
        stream: asyncio.StreamReader,
        tag: str,
        is_error: bool,
        input_condition: Optional[Dict[str, str]],
        buffer_size: int,
        process: asyncio.subprocess.Process,
    ):
        """
        Read from a stream (stdout or stderr) line by line, log the output,
        and check for conditions to automatically send input.

        Args:
            stream (asyncio.StreamReader): The stream to read from.
            tag (str): A tag to identify the command in logs.
            is_error (bool): True if reading from stderr, False for stdout.
            input_condition (Optional[Dict[str, str]]): Mapping of regex patterns to inputs.
            buffer_size (int): Number of recent lines to keep in buffer.
            process (asyncio.subprocess.Process): The subprocess to send input to.
        """
        buffer = deque(maxlen=buffer_size)
        while True:
            line = await stream.readline()
            if not line:
                break
            decoded_line = line.decode().strip()
            buffer.append(decoded_line)

            # Log the line
            if is_error:
                logger.error(f"[{tag}] {decoded_line}")
            else:
                logger.info(f"[{tag}] {decoded_line}")

            # Check for input conditions
            if input_condition:
                buffer_str = "\n".join(buffer)
                for pattern, input_text in input_condition.items():
                    if re.search(pattern, buffer_str, re.MULTILINE):
                        logger.info(f"[{tag}] Sending input: {input_text}")
                        process.stdin.write(input_text.encode() + b"\n")
                        await process.stdin.drain()
                        buffer.clear()  # Clear buffer after sending input

    async def run_command(
        self,
        command: str,
        tag: str,
        cwd: Optional[str] = None,
        input_condition: Optional[Dict[str, str]] = None,
        buffer_size: int = 10,
    ) -> bool:
        """
        Run a shell command asynchronously.

        Args:
            command (str): The command to run.
            tag (str): A tag to identify the command in logs.
            cwd (Optional[str]): The working directory to run the command in.
            input_condition (Optional[Dict[str, str]]): Mapping of regex patterns to inputs.
            buffer_size (int): Number of recent lines to keep in buffer.

        Returns:
            bool: True if the command succeeded (return code 0), False otherwise.
        """
        logger.info(
            f"[{tag}] Starting command: {command} in {cwd if cwd else 'default directory'}"
        )
        process = await asyncio.create_subprocess_shell(
            command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            stdin=asyncio.subprocess.PIPE,
            cwd=cwd,
        )

        # Create tasks for reading stdout and stderr
        stdout_task = asyncio.create_task(
            self.read_stream(
                process.stdout, tag, False, input_condition, buffer_size, process
            )
        )
        stderr_task = asyncio.create_task(
            self.read_stream(
                process.stderr, tag, True, input_condition, buffer_size, process
            )
        )

        # Wait for both streams to be fully read
        await asyncio.gather(stdout_task, stderr_task)
        await process.wait()  # Wait for the process to finish

        # Log the result
        if process.returncode == 0:
            logger.info(f"[{tag}] Success: {command}")
        else:
            logger.error(f"[{tag}] Failure: {command}")
        return process.returncode == 0

    def queue_command(
        self,
        command: str,
        tag: str,
        cwd: Optional[str] = None,
        input_condition: Optional[Dict[str, str]] = None,
        buffer_size: int = 10,
    ) -> asyncio.Task:
        """
        Queue a command to be run asynchronously.

        Args:
            command (str): The command to run.
            tag (str): A tag to identify the command in logs.
            cwd (Optional[str]): The working directory to run the command in.
            input_condition (Optional[Dict[str, str]]): Mapping of regex patterns to inputs.
            buffer_size (int): Number of recent lines to keep in buffer.

        Returns:
            asyncio.Task: The queued task.
        """
        task = asyncio.create_task(
            self.run_command(command, tag, cwd, input_condition, buffer_size)
        )
        self.tasks.append(task)
        return task

    async def execute_commands(self) -> Dict[asyncio.Task, bool]:
        """
        Execute all queued commands and return their results.

        Returns:
            Dict[asyncio.Task, bool]: A mapping of tasks to their success status.
        """
        results = await asyncio.gather(*self.tasks, return_exceptions=True)
        task_success_mapping = {
            task: not isinstance(result, Exception) and result
            for task, result in zip(self.tasks, results, strict=True)
        }
        self.tasks = []  # Clear tasks after execution
        return task_success_mapping
