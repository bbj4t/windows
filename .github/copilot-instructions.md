# GitHub Copilot Instructions for Windows-in-Docker

## Project Overview

This repository contains a Docker-based Windows virtualization solution that runs Windows inside a Docker container using QEMU/KVM. The project enables users to run various Windows versions (from Windows 2000 to Windows 11 and Server editions) in a containerized environment with web-based viewing and RDP access.

## Technology Stack

- **Primary Language**: Bash shell scripts
- **Virtualization**: QEMU/KVM
- **Containerization**: Docker, Docker Compose, Kubernetes
- **Base Image**: qemux/qemu
- **Key Dependencies**: Samba, wimtools, dos2unix, cabextract, libxml2-utils

## Project Structure

- `src/`: Core shell scripts that handle installation, configuration, and runtime
  - `entry.sh`: Main entry point that orchestrates the startup process
  - `define.sh`: Version definitions and Windows edition mappings (1944 lines)
  - `install.sh`: Windows installation automation (1336 lines)
  - `mido.sh`: Windows ISO download functionality (834 lines)
  - `power.sh`: Power management and shutdown handling (241 lines)
  - `samba.sh`: Samba file sharing configuration (228 lines)
- `assets/`: XML configuration files for automated Windows installations (unattended.xml files)
- `.github/workflows/`: CI/CD workflows for building, testing, and releasing
- `Dockerfile`: Multi-stage Docker build configuration
- `compose.yml`: Docker Compose configuration example
- `kubernetes.yml`: Kubernetes deployment configuration

## Coding Standards

### Shell Script Standards

1. **Shebang and Options**:
   - Always use `#!/usr/bin/env bash` as the shebang
   - Enable strict error handling: `set -Eeuo pipefail`
   - This ensures scripts exit on errors, undefined variables, and pipe failures

2. **ShellCheck Compliance**:
   - All shell scripts must pass ShellCheck validation
   - Excluded checks (as per workflow configuration):
     - SC1091: Not following sourced files
     - SC2001: Regex usage patterns
     - SC2002: Useless cat usage
     - SC2034: Unused variables
     - SC2064: Quoting in traps
     - SC2153: Variable name typos
     - SC2317: Unreachable commands
     - SC2028: Echo patterns
   - Run ShellCheck with: `shellcheck -x --source-path=src -e SC1091 -e SC2001 -e SC2002 -e SC2034 -e SC2064 -e SC2153 -e SC2317 -e SC2028 src/*.sh`

3. **Variable Declarations**:
   - Use parameter expansion with defaults: `: "${VAR:="default_value"}"`
   - Quote all variable references: `"$VAR"` not `$VAR`
   - Use lowercase with case-insensitive matching: `"${VERSION,,}"`

4. **Function Definitions**:
   - Use descriptive function names in camelCase (e.g., `parseVersion`, `downloadImage`)
   - Document complex functions with comments explaining their purpose

5. **Error Handling**:
   - Use `error` function for error messages (defined in utils.sh)
   - Use `info` function for informational messages
   - Check command exit codes explicitly when needed

### Docker and Configuration Files

1. **Dockerfile**:
   - Use syntax directive: `# syntax=docker/dockerfile:1`
   - Follow hadolint best practices
   - Excluded hadolint checks: DL3006 (FROM version), DL3008 (apt-get pinning)
   - Always clean up apt cache: `rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*`

2. **XML Files**:
   - Must be valid XML (validated in CI)
   - Located in `assets/` directory
   - Named according to Windows version pattern: `win{version}x{arch}-{edition}.xml`

3. **JSON/YAML Files**:
   - Must pass JSON/YAML validation
   - Kubernetes YAML files are excluded from validation regex

## Build and Test Process

### Linting

The repository uses multiple linters in the check workflow:

```bash
# Run all checks (matches CI)
# This uses the check.yml workflow which runs:
# 1. ShellCheck on all .sh files
shellcheck -x --source-path=src -e SC1091 -e SC2001 -e SC2002 -e SC2034 -e SC2064 -e SC2153 -e SC2317 -e SC2028 src/*.sh

# 2. Hadolint on Dockerfile
hadolint Dockerfile --ignore DL3006 --ignore DL3008

# 3. XML validation on assets
# (requires xml linter tool)

# 4. JSON/YAML validation
# (requires json-yaml-validate tool)
```

### Building

```bash
# Build the Docker image locally
docker build -t windows:local .

# Build with Docker Compose
docker compose build
```

### Testing

The repository includes a test workflow (`test.yml`) for basic functionality testing. Always test changes by:

1. Building the Docker image
2. Running the container with basic configuration
3. Verifying startup and initialization logs
4. Testing specific features affected by your changes

## Key Concepts and Conventions

### Windows Version Handling

- The `VERSION` environment variable controls which Windows version to download/install
- Version aliases are extensive (e.g., "11", "win11", "windows 11" all map to "win11x64")
- Version parsing happens in `define.sh` - be careful when modifying version logic

### Automatic Installation

- The project performs fully automated Windows installations
- Unattended XML files in `assets/` directory configure Windows setup
- Installation scripts handle drivers, language settings, and user creation
- Default credentials: username "Docker", password "admin"

### File Organization

- Runtime scripts are sourced in sequence from `entry.sh`
- Scripts use shared utility functions from `utils.sh`
- Configuration is passed via environment variables

### Environment Variables

Key environment variables include:
- `VERSION`: Windows version to install
- `DISK_SIZE`: Virtual disk size (default 64GB)
- `RAM_SIZE`: RAM allocation (default 4GB)
- `CPU_CORES`: CPU core count (default 2)
- `USERNAME`/`PASSWORD`: Windows user credentials
- `LANGUAGE`: Windows language (default English)
- `KEYBOARD`/`REGION`: Locale settings

## Security Considerations

1. **Never commit secrets**: No API keys, passwords, or tokens in code
2. **Use GitHub Secrets**: Sensitive data in workflows must use repository secrets
3. **Validate inputs**: Always validate and sanitize environment variables
4. **Quote variables**: Prevent injection attacks by properly quoting shell variables
5. **Minimal permissions**: Follow principle of least privilege in Docker configurations

## Pull Request and Contribution Guidelines

1. **Keep changes minimal**: Make surgical, focused changes
2. **Test thoroughly**: Verify your changes don't break existing functionality
3. **Update documentation**: If adding features or changing behavior, update README.md
4. **Follow existing patterns**: Match the coding style of existing files
5. **Lint before committing**: Run ShellCheck and other linters on your changes
6. **Descriptive commits**: Write clear commit messages explaining what and why

## Common Tasks

### Adding a New Windows Version

1. Add version alias mapping in `define.sh` (in the `parseVersion` function)
2. Create corresponding XML unattended file in `assets/`
3. Test the download and installation process
4. Update README.md with new version in the table

### Modifying Installation Process

1. Changes typically go in `install.sh`
2. Ensure compatibility with all supported Windows versions
3. Test with at least Windows 10 and 11
4. Verify unattended installation still works

### Updating Dependencies

1. Modify `Dockerfile` apt-get packages
2. Test Docker build succeeds
3. Verify container still functions correctly
4. Update version if needed

## Documentation

- Main documentation is in `README.md`
- Keep FAQ section updated with common questions
- Include examples for new features
- Update version tables when adding support for new Windows versions

## Workflow and CI/CD

- **Build workflow**: Builds and publishes Docker images to Docker Hub and GHCR
- **Check workflow**: Runs linters and validation (ShellCheck, hadolint, XML, JSON/YAML)
- **Test workflow**: Runs basic functionality tests
- **Review workflow**: Handles code review automation

Always ensure CI checks pass before merging changes.

## Additional Resources

- QEMU documentation: https://www.qemu.org/docs/master/
- Windows unattended installation: https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/
- Docker best practices: https://docs.docker.com/develop/dev-best-practices/
- Bash best practices: https://www.gnu.org/software/bash/manual/

## Notes for Copilot

- This is a specialized virtualization project - understand QEMU and Windows installation concepts
- Shell scripts are complex and interdependent - be cautious with changes
- The project serves a large user base - stability and compatibility are critical
- Always consider the impact on different Windows versions (7, 8, 10, 11, Server editions)
- Performance matters - container startup and Windows installation should be optimized
- Error messages should be clear and actionable for end users
