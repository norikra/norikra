# Build

There are two build args baked in:

* `jruby_version` which defaults to 9.2
* `norikra_version` which must be specified

Eg:

```
docker build --build-arg norikra_version=1.5.1 -t norikra:1.5.1
```

# Push

```
docker tag norikra:1.5.1 ${your_repo}/norikra:1.5.1
docker push ${your_repo}/norikra:1.5.1
```

