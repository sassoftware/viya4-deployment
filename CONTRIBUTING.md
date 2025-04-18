# How to Contribute
We'd love to accept your patches and contributions to this project.
We just ask that you follow our contribution guidelines when you do.

## Contributor License Agreement
Contributions to this project must be accompanied by a signed [Contributor Agreement](ContributorAgreement.txt).
You (or your employer) retain the copyright to your contribution; this simply grants us permission to use and redistribute your contributions as part of the project.

## Pull Request Requirement

## Code reviews
All submissions to this project—including submissions from project members—require review.
Our review process typically involves performing unit tests, development tests, integration tests, and security scans using internal SAS infrastructure.
For this reason, we don’t often merge pull requests directly from GitHub.

Instead, we work with submissions internally first, vetting them to ensure they meet our security and quality standards.
We’ll do our best to work with contributors in public issues and pull requests; however, to ensure our code meets our internal compliance standards, we may need to incorporate your submission into a solution we push ourselves.

This does not mean we don’t value or appreciate your contribution.
We simply need to review your code internally before merging it.
We work to ensure all contributors receive appropriate recognition for their contributions, at least by acknowledging them in our release notes.

### Conventional Commits
All pull requests must follow the [Conventional Commit](https://www.conventionalcommits.org/en/v1.0.0/)
standard for commit messages. This helps maintain a consistent and meaningful
commit history. Pull requests with commits that do not follow the Conventional
Commit format will not be merged.

### Developer Certificate of Origin Sign-Off
This project requires all commits to be signed off in accordance with the [Developer Certificate of Origin (DCO)](https://developercertificate.org/).
By signing off your commits, you certify that you have the right to submit the
contribution under the open source license used by this project.

To sign off your commits, use the --signoff flag with git commit:

```bash
git commit --signoff -m "Your commit message"
```

This will add a Signed-off-by line to your commit message, e.g.:

```bash
Signed-off-by: You Name <your.email@example.com>
```

For more information, please refer to https://probot.github.io/apps/dco/

### Linter Analysis Checks
All pull requests must pass our automated analysis checks before they can be
merged. These checks include:

- **Hadolint** – for Dockerfile best practices
- **ShellCheck** – for shell script issues
- **Ansible-lint** – for Ansible playbook and role validation
