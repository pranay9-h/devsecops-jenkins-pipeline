# Security

## Never commit

- AWS access keys
- kubeconfig files
- registry tokens
- SonarQube tokens
- NVD API keys
- private keys
- passwords
- Kubernetes Secret manifests containing real values

## Pipeline controls demonstrated

- automated unit tests
- SonarQube quality gate before deployment
- OWASP Dependency-Check
- Trivy image scanning
- non-root container execution
- Kubernetes security context
- readiness and liveness probes
- resource requests and limits
- automated rollback after failed deployment validation

## Secrets

All sensitive values are expected to come from Jenkins Credentials or an external secret-management solution.

## Container images

Use immutable image tags or digests for real environments. The pipeline tags images with the Jenkins build number instead of deploying `latest`.
