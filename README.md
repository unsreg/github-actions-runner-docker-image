# GitHub Actions Runner in Docker

This repository provides a Docker image to run a self-hosted GitHub Actions runner. The image is automatically built and published to GitHub Packages.

## Features

-   **Ubuntu-based**: The image is based on the latest Ubuntu LTS release.
-   **Automatic Runner Updates**: The included `start.sh` script automatically handles the registration and removal of the runner.
-   **Docker-in-Docker Ready**: The Docker CLI is pre-installed, allowing your workflows to build and run Docker containers.
-   **Secure**: The runner is executed as a non-root user.
-   **Automated Builds**: A GitHub Actions workflow automatically builds and publishes the Docker image.
-   **Image Signing and SBOM**: The published image is signed with Cosign, and a Software Bill of Materials (SBOM) is generated using Syft.

## How to Use

To use this Docker image, you need to provide the necessary environment variables for the runner to register with your repository or organization.

### Required Environment Variables

-   `RUNNER_NAME`: The name of the runner.
-   `ACCESS_TOKEN` or `REGISTRATION_TOKEN`:
    -   `ACCESS_TOKEN`: A Personal Access Token (PAT) with `repo` scope (for repository runners) or `admin:org` scope (for organization runners). This will be used to automatically generate a registration token.
    -   `REGISTRATION_TOKEN`: A pre-generated registration token. If you provide this, you do not need to provide an `ACCESS_TOKEN`.
-   `ORGANIZATION` or `OWNER`/`REPOSITORY`:
    -   `ORGANIZATION`: The name of your GitHub organization.
    -   `OWNER` and `REPOSITORY`: The owner and name of your repository (e.g., `OWNER=my-username` and `REPOSITORY=my-cool-project`).

### Optional Environment Variables

-   `RUNNER_LABELS`: A comma-separated list of labels to apply to the runner (e.g., `self-hosted,docker,production`).

### Example Usage

```bash
docker run -it --rm \
  -e RUNNER_NAME="my-awesome-runner" \
  -e ACCESS_TOKEN="your-github-pat" \
  -e OWNER="your-username" \
  -e REPOSITORY="your-repo" \
  -e RUNNER_LABELS="self-hosted,docker" \
  ghcr.io/unsreg/github-actions-runner-docker-image:latest
```

## GitHub Actions Workflow

The `.github/workflows/create-publish-docker-image.yml` workflow automates the building and publishing of the Docker image.

### Workflow Triggers

The workflow is triggered on every push to the `main` branch.

### Workflow Steps

1.  **Checkout Repository**: Checks out the source code.
2.  **Get Latest Runner Version**: Fetches the latest version of the GitHub Actions runner.
3.  **Set up QEMU and Docker Buildx**: Configures the environment for multi-platform builds.
4.  **Log in to GitHub Container Registry**: Logs in to `ghcr.io` using a `GITHUB_TOKEN`.
5.  **Extract Docker Metadata**: Extracts tags and labels for the Docker image.
6.  **Build and Push Docker Image**: Builds the Docker image and pushes it to `ghcr.io`. The image is tagged with the runner version, `latest`, and the Git SHA.
7.  **Image Signing**: Signs the published image using Cosign in keyless mode.
8.  **Generate SBOM**: Generates a Software Bill of Materials (SBOM) using Syft.
9.  **Create GitHub Release**: Creates a GitHub release and uploads the SBOM as an artifact.
10. **Generate Artifact Attestation**: Generates a provenance attestation for the build.