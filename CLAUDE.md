# CLAUDE.md - lime-dev Development Environment

This repository provides a comprehensive development environment for LibreMesh ecosystem projects. It solves critical development challenges including firmware building, legacy device support, QEMU virtualization, and automated workflows for LibreMesh, LibreRouterOS, and lime-app development.

## Memories and Notes

- remember to use 10.13.0.1 as router ip on examples that require an example
- se cautelosa, siempre comprueba la necesidad y utilidad de lo que estemos haciendo antes de hacer cambios

## Core Problem Solved

**Main Achievement**: Rescued legacy LibreRouter v1 devices (pre-1.5 firmware) that couldn't upgrade firmware normally due to outdated safe-upgrade scripts and SSH/transfer limitations.

**Result**: Legacy routers can now upgrade firmware via web interface after running the safe-upgrade update script.
