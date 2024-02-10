<div align='center'>
<img src="docs/flynnt-logo.svg" width=200 />

# Flynnt Agent & Node Installation Script

This repository contains scripts to install flynnt on an agent node.

---

</div>

The script is to be executed on the server that should be added to the flynnt cluster.
Functionality contains installing, upgrading and removing the flynnt kubernetes agent from the node.

- [Flynnt](https://flynnt.io)
- [Flynnt: How to add a node](https://docs.flynnt.io/basics/adding-a-node)

## Used Tooling

We used these tools
- [Bashly](https://bashly.dannyb.co/) for generating boilerplate CLI code
- [ShellCheck](https://www.shellcheck.net/) for code quality

## Supported Operating Systems

These operating systems are currently tested and supported

- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS

## Getting Started

Either download the script from the [releases](https://github.com/flynnt-io/flynnt-agent-install/releases/latest) page or execute it directly, like this:

```bash
curl -sL https://github.com/flynnt-io/flynnt-agent-install/releases/latest/download/flynnt.sh | bash -s - install -c <clustername> -n <nodename>
```
OR
```bash
curl -OL https://github.com/flynnt-io/flynnt-agent-install/releases/latest/download/flynnt.sh
chmod +x flynnt.sh
./flynnt.sh install -c <clustername> -n <nodename>
```

## Authentication

You need to authenticate yourself to Flynnt before you can add a new node to your cluster.

You can do this either by supplying a env var or by opening the authentication link printed out by the script.
```bash
export API_KEY=<api-key-from-flynnt-dashboard>
./flynnt.sh install -c <clustername> -n <nodename>
// or
API_KEY=<api-key-from-flynnt-dashboard> ./flynnt.sh install -c <clustername> -n <nodename>

```

## Compiling
We are using [bashly](https://github.com/DannyBen/bashly) to compile this.

This project was created like this:
```bash
docker run --rm -it --user $(id -u):$(id -g) --volume "$PWD:/app" dannyben/bashly:1.1.6 init
```

To recompile the project, use this:
```bash
docker run --rm -it --user $(id -u):$(id -g) --volume "$PWD:/app" dannyben/bashly:1.1.6 generate
```

Static analysis with shellcheck:
```bash
docker run --rm -v "$PWD:/mnt" koalaman/shellcheck:stable src/*.sh
```