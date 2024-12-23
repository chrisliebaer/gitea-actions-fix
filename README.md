This action works around various shortcomings when using the default `actions/checkout` action in a Gitea workflow.
It is supposed to be used before the `actions/checkout` action.

The main source of theses challenges is a much more restricted access token in Gitea compared to GitHub.
The default access token for Gitea runners only has read access to the repository, it can't write the package registry or access other repositories owned by the same user.
Furthermore, if you run a private Gitea instance, you will not even be able to use your own actions, since the runner can't access their repository.
In most of your workflows, you will have something like this, with `secret.ACCESS_TOKEN` replacing the usual `secrets.GITHUB_TOKEN` practically everywhere:

```yaml
name: Turn water into wine
on:
  push:
    branches:
      - master
    [...]
  
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: chrisliebaer/gitea-actions-fix@vXX
        with:
          token: ${{ secrets.ACCESS_TOKEN }}
      - uses: actions/checkout@vXX
        with:
          # token: ${{ secrets.ACCESS_TOKEN }} you dont need this, gitea-actions-fix configures the credential helper
          submodules: recursive
          lfs: true
      - name: Most perfect build steps
      [...]
```

You can work around most of these limitations with a lot of band-aid fixes inside your workflows, but I prefer a more consise, which can be used in all workflows, hence this action.

## Rewrite Submodule URLs from SSH to HTTP(s)
When running a private Gitea instance, all repositories are inaccessable without authentication.
I assume the majority of users will access and push to their repositories via SSH.
Since we generally assume to use a user provided access token, instead of the runner token, it makes sense to assume that this token is also valid for submodules.
For this reason, we rewrite the submodule URLs from SSH to HTTPS, so that the user provided token can be used for authentication.

Admittedly, I never had to deal with private submodules in GitHub actions and it seems like you can use a PAT to authenticate via SSH on GitHub.
However, on my Gitea instance, I have a lot of private submodules that I want to check out.
If you run a private Gitea instance (one without public access), you will have the same problem even for *public* submodules.


## Fix LFS checkout
The git-lfs checkout involves a status request against the lfs endpoint, in which the lfs server may reply with an authentication token.
The client then has to use this token for download requests.
On Github, the URL of the lfs server is on a separate subdomain, so that the `.extraheader` does not apply to the lfs server, but this is not the case for Gitea.
During the execution of the `actions/checkout` action, both tokens are then used, causing malformed requests to the lfs server.
The details of this problem have been documented by various users:

* https://gitea.com/gitea/act_runner/issues/164
* https://github.com/actions/checkout/issues/1830

Since `actions/checkout` is otherwise very reliable and well-maintained, we want to keep using it.
The workaround in this action is to *poison* the execution environment of the `actions/checkout` action, so that we remain in control of the authentication token.

## Checking out private actions
Whether you are using a private Gitea instance or simply want to use private actions, you will run into the problem that the runner token can't access the repository.
This issue can sadly not be fixed from within actions, since the checkout of an action is done in preparation of the workflow execution by the act runner.
Act runner also seems to keep a cache of the action repository, so that it can be used in subsequent runs, which would make it difficult to check if the provided workflow should even have access to the action repository.
A potential workaround is to check out the action repository in the workflow itself, and then run the action from the checked out directory:

```yaml
[...]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: chrisliebaer/gitea-actions-fix@vXX
        with:
          token: ${{ secrets.ACCESS_TOKEN }}
      - uses: actions/checkout@vXX
      [...]
      # checkout the action repository with the more powerful access token
      - uses: actions/checkout@vXX
        with:
          repository: https://your.gitea.tld/<owner>/<action-repo>
          ref: vXX
          token: ${{ secrets.ACCESS_TOKEN }}
          path: .github/actions/<action-repo>
      # call the action from the checked out directory (no need to specify binary path)
      - uses: .github/actions/<action-repo>
[...]
```

Which is more verbose and harder to maintain, since it hides the actual action call in the workflow from tools like `dependabot` or `renovate`.
An alternative solution which I haven't fully explored yet is to put the act runner itself behind an HTTP proxy, to inject a runner token into the requests in order to at least allow the checkout of *non-private* actions.


# Tracking Issues
This action is a workaround for a problem that should be fixed by `actions/checkout`, Gitea (and Forgejo).
The following list contains issues closely related to the issue of access tokens in both Gitea and Forgejo:

`actions/checkout`
* https://github.com/actions/checkout/pull/1754
* https://github.com/actions/checkout/issues/415

Gitea
* https://github.com/go-gitea/gitea/issues/29398
* https://github.com/go-gitea/gitea/issues/23642
* https://github.com/go-gitea/gitea/issues/29398
* https://github.com/go-gitea/gitea/issues/24635

Forgejo
* https://codeberg.org/forgejo/forgejo/issues/5877
* https://codeberg.org/forgejo/forgejo/issues/6094
* https://codeberg.org/forgejo/forgejo/issues/5841
* https://codeberg.org/forgejo/forgejo/issues/3571
