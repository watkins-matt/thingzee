import os

import pytest

import project_scanner


@pytest.fixture
def base_directory(tmp_path):
    # Create a base directory in a temporary path
    base_dir = tmp_path / "mock_directory"
    base_dir.mkdir()

    # Define mock projects and files
    projects = {
        "project1": ["main.dart", "main.g.dart", "utils.dart"],
        "project2": [
            "api.dart",
            "api.g.dart",
            "api.merge.dart",
            "helper.ob.dart",
            "model.db.dart",
            "model.db.g.dart",
        ],
    }

    # Create projects and files
    for project, files in projects.items():
        project_dir = base_dir / project
        project_dir.mkdir()
        for file in files:
            file_path = project_dir / file
            file_path.touch()  # Creates an empty file

    return base_dir


def test_find_dart_files(base_directory):
    # Initialize ProjectScanner with None or a mock for yaml_project_file
    scanner = project_scanner.ProjectScanner(str(base_directory), None)
    all_files = []
    for root, _dirs, files in os.walk(str(base_directory)):
        all_files.extend(
            [os.path.join(root, file) for file in files if file.endswith(".dart")]
        )

    # Act
    found_files = scanner.find_dart_files(str(base_directory), all_files)

    # Prepare expected results
    expected_files = {
        os.path.normpath(os.path.join(base_directory, "project1/main.dart")),
        os.path.normpath(os.path.join(base_directory, "project2/api.dart")),
        os.path.normpath(os.path.join(base_directory, "project2/helper.ob.dart")),
        os.path.normpath(os.path.join(base_directory, "project2/model.db.dart")),
    }

    # Assert
    found_file_paths = {file_path for file_path in found_files.keys()}
    assert (
        found_file_paths == expected_files
    ), "The lists of files should match exactly."
