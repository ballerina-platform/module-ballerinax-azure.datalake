# Examples

The `ballerinax/azure.datalake` connector provides practical examples illustrating usage in various scenarios.

1. [Daily extract ingestion](https://github.com/ballerina-platform/module-ballerinax-azure.datalake/tree/main/examples/daily_extract_ingestion) - Upload a local extract into a dated directory, then list and read it back.

## Prerequisites

1. Follow the [setup guide](https://github.com/ballerina-platform/module-ballerinax-azure.datalake/tree/main/README.md#setup-guide) to create a storage account with a hierarchical namespace and obtain an access token.

2. For each example, create a `Config.toml` file with the storage account name, the access token and the example's own values. Each example's `.md` file lists them. For example:

    ```toml
    storageAccount = "<storage-account-name>"
    token = "<access-token>"
    ```

## Running an example

Execute the following commands to build an example from the source:

* To build an example:

    ```bash
    bal build
    ```

* To run an example:

    ```bash
    bal run
    ```

## Building the examples with the local module

**Warning**: Due to the absence of support for reading local repositories for single Ballerina files, the Bala of the module is manually written to the central repository as a workaround. Consequently, the bash script may modify your local Ballerina repositories.

Execute the following commands to build all the examples against the changes you have made to the module locally:

* To build all the examples:

    ```bash
    ./build.sh build
    ```

* To run all the examples:

    ```bash
    ./build.sh run
    ```
