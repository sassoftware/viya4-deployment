# Minimal Logging Sample

This sample demonstrates how you can customize a logging deployment
to minimize resource usage. The sample deployment configures single instances of each logging 
component. This configuration could save CPU and memory resources and could be useful in development and test environments.

## Installation

Follow these steps:

1. Copy this sample directory to a separate local path.

2. Set the `USER_DIR` environment variable to the local path:

```bash
export USER_DIR=/your/path/to/min-logging
```

3. Deploy logging using the standard deployment script:

```bash
logging/bin/deploy_logging_open.sh
```
