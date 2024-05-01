import hashlib


class FileHasher:
    """Utility class to generate file hashes."""

    @staticmethod
    def generate_hash(file_path: str) -> str:
        """Generate SHA-256 hash of a file."""
        with open(file_path, "rb") as file:
            file_hash = hashlib.sha256()
            chunk = file.read(4096)
            while chunk:
                file_hash.update(chunk)
                chunk = file.read(4096)
            return file_hash.hexdigest()
