# Release Process for the Azure Kubernetes Service (AKS) Terraform Module

This document captures the process and steps required to create a new release.

## Process

> **Important**
> This process assumes that the release version has been agreed on, for this example we'll use `v1.1.0`, and that all of the issues have been completed for the release milestone.

Use the following steps to release a version of the module, after the steps have been completed you might want to send a message to the OG-RBA Kubernetes Working Group MS Teams group [General channel](https://teams.microsoft.com/l/channel/19%3a27e66f24235b48dd8b14bf784f1a4e6a%40thread.skype/General?groupId=dc4762e6-314d-4645-9919-bff7cc54b91c&tenantId=9274ee3f-9425-4109-a27f-9fb15c10675d) to inform the community. Use `@OG-RBA Kubernetes Working Group` to flag it to users Activity tab.

- Create release issue
- Create release branch
- Update release information
- Open PR
- Merge PR
- Create GH release
- Add tags
- Close release issue & milestone

### Create Release Issue

Check that there isn't already an issue created for the release and assuming not [create a new issue](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/issues/new/choose) to track the release process. The issue should be added to the release milestone and have tasks added for each of the following steps to be ticked off as they are completed. The person assigned to the issue should complete the following steps and record them as completed.

### Create Release Branch

Create a release branch from the `main` branch to make the release changes on.

```shell
git checkout main
git pull
git checkout -b release-v1-1-0
git push --set-upstream origin release-v1-1-0
```

### Update Release Information

Replace `UNRELEASED` with the release date (usually today) in [CHANGELOG.md](./CHANGELOG.md) using the `yyyy-MM-dd` format.

Set the `module_version` in [local.tf](./local.tf) (in this example to `1.1.0`). If this is a pre-release version don't add the pre-release ordinal, so `v1.1.0-rc.7` would be coded as `v1.1.0-rc`.

Push the code up to GitHub.

```shell
git add .
git commit -m "chore: Release v1.1.0"
git push
```

### Open PR

Open a [PR](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/pulls) to merge the release branch in the `main` branch and add it to the release milestone. Add any additional content for the release to the PR. Assign a reviewer with the correct permissions to merge the changes and create the tags.

### Merge PR

The PR assignee can merge the branch into `main` once they are happy with the release.

### Create GH Release

[Create a new GH release](https://github.com/LexisNexis-RBA/terraform-azurerm-aks/releases/new), enter the release into the input provided by clicking `Choose a tag` and click `Create new tag` at the bottom of the dropdown. Don't add a title and add any additional release content into the description followed by the release notes from [CHANGELOG.md](./CHANGELOG.md). Publish the release.

### Add Tags

Additional tags should be made for convenience once the GH release is completed. For production releases these tags should be in the format `v{major}` & `v{major}.{minor}`, for pre-production releases they should be in the form `{major}.{minor}.{patch}-{type}`. If the tag already exists it needs to be deleted before it is re-created.

### Close Release Issue & Milestone

Once these steps have been completed the release issue should be closed and then the release milestone should be closed.
