# KubectlXtra

"📰 Extra! Extra! Read all about it! KubectlXtra is Here for your convenience."

"💁 So this is kubectl but extra, Yeah, pretty much."

`kubectlxtra` is a wrapper that extends the functionality of `kubectl` command-line tool, providing additional
features and simplifications for managing Kubernetes clusters.

## Features

- Login to Kubernetes clusters with ease using enhanced login/logout functionality.
- Display available namespaces with detailed information about access rights.
- Switch between namespaces seamlessly for efficient cluster management.

## Notes

- KubectlXtra simplifies Kubernetes cluster management tasks by providing enhanced functionalities on top of `kubectl`.
- It aims to improve user experience and efficiency when working with Kubernetes clusters.
- The script is designed to seamlessly integrate with existing Kubernetes workflows.

## Requirements

- `kubectl` installed.
- `awk` installed.

## Installation

To install KubectlXtra, follow these simple steps:

```shell
curl -LO "https://github.com/alexbaeza/kubectlxtra/raw/main/kubectlxtra.sh"
chmod +x kubectlxtra.sh
mv kubectlxtra.sh /usr/local/bin/kubectlxtra
```

**Note:** 
If you do not have root access on the target system, you can still install `kubectlxtra` to the `~/.local/bin` directory:

```shell
curl -LO "https://github.com/alexbaeza/kubectlxtra/raw/main/kubectlxtra.sh"
chmod +x kubectlxtra.sh
mv ./kubectlxtra.sh ~/.local/bin/kubectl
# and then append (or prepend) ~/.local/bin to $PATH
```

## Usage and Examples

To use `kubectlxtra`, execute the script with desired commands:

```shell
# Login to a Kubernetes cluster with a service-account-token
kubectlxtra login --server=<server_url> --token=<service_account_token> [other_options...]

> kubectlxtra login --server=https://example.com --token=XXXXXXXXXXXXX
```

```shell
# Logout from a Kubernetes cluster and delete credentials
kubectlxtra logout
```

```shell
# Display available namespaces
kubectlxtra namespaces
```

```shell
# Switch to a different namespace
kubectlxtra namespace <target_namespace>

> kubectlxtra namespace kube-system
```

```shell
# Read help
kubectlxtra help
```

### Kubectl Native commands are still supported

_kubectlxtra only aims to enhance the functionality of kubectl building on top of it, therefore the native kubectl
functions are supported and untouched._

```shell
# Display cluster info
kubectlxtra cluster-info
kubectlxtra get pods
```

```shell
# List resources
kubectlxtra get nodes
kubectlxtra get pods
kubectlxtra get deployments
kubectlxtra get svc
...and others
```

```shell
# With namespace selectors
kubectlxtra get pods -A
kubectlxtra get pods --all-namespaces
kubectlxtra get pods -n kube-system
```

```shell
# Logs
kubectlxtra logs mypod-5b6f77bb46-vp6ms
```

```shell
# Describe resources
kubectlxtra describe pod mypod-5b6f77bb46-vp6ms
kubectlxtra describe deployment mypod-5b6f77bb46-vp6ms
kubectlxtra describe rs mypod-5b6f77bb46-vp6ms
```

These commands showcase common usage scenarios for managing Kubernetes clusters with KubectlXtra.

## Recommendations

I personally highly recommend adding the `k` alias to kubectlxtra.

_🚀 You'll feel like you're saving precious seconds by typing at the speed of light._

```shell
alias k='kubectlxtra'
```

## ❤️ Contributing

We welcome contributions from the community! If you have any feature suggestions or bug fixes, please feel free to raise
an issue to discuss it. You can also open a pull request (PR) to contribute your changes. Before submitting a PR, make
sure to check the existing issues and PRs to avoid duplication. We appreciate your contributions!

## License

This project is licensed under the MIT License.
See the [LICENSE](https://github.com/example/kubectlxtra/raw/main/LICENSE) file for details.
