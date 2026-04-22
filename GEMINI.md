# Little Automation

A comprehensive suite of automation tools for AWS, Chef, and Docker. This repository serves as a mono-repo for managing infrastructure, deployment scripts, and operational documentation.

## Project Overview

*   **Primary Entry Point**: `AWS/little.sh` - A wrapper script that manages AWS credentials (MFA, role assumption) and delegates to sub-commands.
*   **Technologies**: Bash (4+), AWS CLI, jq, Node.js, Chef, Docker, CloudFormation.
*   **Key Directories**:
    *   `AWS/`: AWS-specific automation, including CloudFormation templates and management scripts.
    *   `Chef/`: Infrastructure-as-Code using Chef cookbooks and roles.
    *   `Docker/`: Docker stack configurations for local and server environments.
    *   `Notes/`: Deep-dive documentation on architecture, contribution, and how-to guides.
    *   `Scripts/`: Miscellaneous utility scripts.

## Building and Running

### Setup

To use the `little` CLI tools, add an alias to your shell configuration:

```bash
alias little='bash /path/to/little-automation/AWS/little.sh'
```

### Common Commands

The `little` wrapper automatically injects AWS credentials based on your `AWS_PROFILE`.

*   **List Profiles**: `little profiles`
*   **CloudFormation Stack Management**: `little stack [sub-command]`
*   **Lambda Management**: `little lambda [sub-command]`
*   **Secrets Manager**: `little secret [sub-command]`
*   **Systems Manager (SSM)**: `little ssm [sub-command]`

Documentation for specific commands can be found in `AWS/doc/`.

### Testing

Tests are located in `AWS/test/` and primarily use `shunit.sh` (embedded in `AWS/lib/bash/`).

```bash
# Example: Run unit tests
bash AWS/test/utilsTest.sh
```

## Development Conventions

### Scripting Standards

*   **Bash Version**: Use Bash 4+ features.
*   **Utility Library**: Source `AWS/lib/bash/utils.sh` in all automation scripts for shared functions (logging, semver checks, path management).
*   **Environment Variables**:
    *   `LITTLE_HOME`: Root directory of the `AWS` automation suite.
    *   `AWS_PROFILE`: Determines the active AWS context.
*   **Tagging Strategy**: Resources managed by these tools should adhere to the standard tagging strategy: `org`, `project`, `stack`, `stage`, and `role`.

### Documentation

The project follows a structured documentation approach based on [Diátaxis](https://diataxis.fr/):
*   `Notes/tutorial/`: Learning-oriented guides.
*   `Notes/howto/`: Task-oriented guides.
*   `Notes/explanation/`: Understanding-oriented discussions.
*   `Notes/reference/`: Information-oriented technical descriptions.

### Repository Structure

Sub-commands are organized by their requirements:
*   `AWS/bin/`: Scripts requiring AWS credentials.
*   `AWS/bin/basic/`: Scripts that do not require AWS credentials.
