# Unhelm

Helm unfortunately became a de-facto standard for defining Kubernetes applications
as a set of kubernetes resources (or corresponding yaml).

Charts are usually fit for "quick start" use cases, but for Operations teams they tend to:

- Get in the way of understanding the system that's operated; things like how it scales.
- Limit tuning and configuration to use cases the chart author envisions.

The [unhelm](https://github.com/Yolean/unhelm/) repo avoids the endless back and forth between values files and chart source by treating charts as best practices, and enabling tweaks through [Kustomize](https://kustomize.io/).

## To add an application

Submit a new `[chart name].[config name].values.yaml` in the root of this repo,
containing a line prefixed `# unhelm-template-repo: [repo URL]`.

## Namespaces

Please pay attention to where chart-generated yaml contains namespace strings.
That's frequently hard to spot if you use namespace "app" for your App app,
which is why this repo consistently uses `unhelm-namespace-placeholder`.

Each generated kustomize base gets a file `unhelm-namespace-placeholder.txt`
which helps point out these strings.
They typically call for specific Kustomize patches.
Or use this repo only as examples and maintain your own yaml.
