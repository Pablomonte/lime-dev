# Contributing to Lime-Dev

Thank you for your interest in contributing to Lime-Dev!

## How to Contribute

### Reporting Issues

1. Check existing issues first
2. Use issue templates when available
3. Include:
   - System information (OS, Docker version)
   - Steps to reproduce
   - Expected vs actual behavior
   - Relevant logs

### Submitting Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Test thoroughly
5. Commit with clear messages
6. Push to your fork
7. Submit a Pull Request

### Code Style

- Shell scripts: Follow Google Shell Style Guide
- Use shellcheck for validation
- Keep scripts POSIX-compliant when possible
- Document complex operations

### Testing

Before submitting:
- Test Docker builds
- Verify QEMU functionality
- Check cross-platform compatibility
- Run shellcheck on modified scripts

### Documentation

- Update README.md for user-facing changes
- Add inline comments for complex logic
- Update CLAUDE.md for AI assistance context
- Keep examples current

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/lime-dev
cd lime-dev

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL/lime-dev

# Create branch
git checkout -b feature/new-feature
```

## Pull Request Process

1. Update documentation
2. Add tests if applicable
3. Ensure all tests pass
4. Update CHANGELOG.md
5. PR description should include:
   - What changes were made
   - Why they were necessary
   - How they were tested

## Community

- Respect all contributors
- Be constructive in feedback
- Help others when possible
- Follow project Code of Conduct

Thank you for contributing!