# Buildrunner

## What does this thing do?

So, you've got some Dart packages that are nested within subdirectories? Maybe a lot
of them? And you probably need to run "pub get" periodically.

Well, you could manually cd into each directory and run "pub get". Or you could automate
the whole process, and have this script do that for you.

## How does it work?

A cached snapshot of all projects is stored in a project.yaml file. If this file doesn't exist, it will be generated.

It keeps track of the hashes of all of your pubspec.yaml files, as well as the sources of any generated files. When pubspec.yaml changes, it will run "pub get" in that directory. If the source of a generated file changes, it will run "dart run build_runner build" in that directory.

## Arguments

If you run it with no arguments, it will determine what commands need to run automatically
and run them once.

If you run it with the argument `--watch`, it continue running until it detects
a change in any of the pubspec.yaml files or dart files. It will then determine
what commands need to run automatically and run them.
