# Ballerina Azure Data Lake connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-azure.datalake/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-azure.datalake/actions/workflows/ci.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-azure.datalake.svg)](https://github.com/ballerina-platform/module-ballerinax-azure.datalake/commits/master)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/azure.datalake.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%2Fazure.datalake)

## Overview

[Azure Data Lake Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction) is Microsoft Azure's storage for big data analytics. It adds a hierarchical namespace to Azure Blob Storage, so that data is organized in filesystems, directories and files with POSIX-style permissions and access control lists, and can be used by Hadoop, Spark and other analytics workloads.

The Azure Data Lake connector lets Ballerina programs work with Data Lake Storage through its REST API, version 2019-10-31. It covers filesystems in a storage account, and the files and directories inside them: creating, renaming, listing and deleting paths, uploading and reading file content, managing properties and access control, and leasing files for exclusive access.

## Setup guide

To use the Azure Data Lake connector, you need a storage account with a hierarchical namespace, permission to use its data, and a Microsoft Entra ID access token issued for Azure Storage.

1. Sign in to the [Azure portal](https://portal.azure.com/) with an account that has an active subscription.

2. Create a storage account: search for **Storage accounts**, select **Create**, and choose a subscription, resource group, region and a globally unique account name. On the **Advanced** tab, select **Enable hierarchical namespace**, then create the account. The connector sends every request to the account's Data Lake endpoint, `https://<storage-account-name>.dfs.core.windows.net`.

3. Grant the identity that will call the account access to its data. Open the storage account's **Access control (IAM)** page and assign **Storage Blob Data Contributor** to read and write data, or **Storage Blob Data Owner** to also change owners, permissions and access control lists.

4. Obtain an access token for the `https://storage.azure.com/` resource. For local development, sign in with the [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) and run:

    ```bash
    az account get-access-token --resource https://storage.azure.com/ --query accessToken --output tsv
    ```

    For an unattended service, register an application in Microsoft Entra ID, create a client secret for it, and grant its service principal a role as in step 3. Then request a token with the OAuth 2.0 client credentials flow from `https://login.microsoftonline.com/<tenant-id>/oauth2/v2.0/token`, using the scope `https://storage.azure.com/.default`.

> **Note:** The connector authenticates with a bearer token and does not refresh it. Access tokens expire, typically after about an hour, so a long-running program must obtain a fresh token and create a new client when the token expires.

## Quickstart

To use the Azure Data Lake connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `azure.datalake` module.

```ballerina
import ballerinax/azure.datalake;
```

### Step 2: Instantiate a new connector

Create a `datalake:Client` with the storage account's Data Lake endpoint and an access token.

```ballerina
configurable string storageAccount = ?;
configurable string token = ?;

final datalake:Client datalake = check new ({auth: {token}}, string `https://${storageAccount}.dfs.core.windows.net`);
```

Provide the values in a `Config.toml` file:

```toml
storageAccount = "<storage-account-name>"
token = "<access-token>"
```

### Step 3: Invoke the connector operation

List the filesystems in the storage account. Account-level operations take `'resource = "account"`.

```ballerina
public function main() returns error? {
    datalake:FilesystemList _ = check datalake->listFilesystems('resource = "account");
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```

## Examples

The `Azure Data Lake` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-azure.datalake/tree/main/examples/), covering the following use cases:

1. [Daily extract ingestion](https://github.com/ballerina-platform/module-ballerinax-azure.datalake/tree/main/examples/daily_extract_ingestion) - Upload a local extract into a dated directory in chunks, then list the directory and read the file back.

## Build from the source

### Setting up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 21. You can download it from either of the following sources:

    * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
    * [OpenJDK](https://adoptium.net/)

   > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/).

3. Download and install [Docker](https://www.docker.com/get-started).

   > **Note**: Ensure that the Docker daemon is running before executing any tests.

4. Export Github Personal access token with read package permissions as follows,

    ```bash
    export packageUser=<Username>
    export packagePAT=<Personal access token>
    ```

### Build options

Execute the commands below to build from the source.

1. To build the package:

   ```bash
   ./gradlew clean build
   ```

2. To run the tests:

   ```bash
   ./gradlew clean test
   ```

3. To build the without the tests:

   ```bash
   ./gradlew clean build -x test
   ```

4. To run tests against different environments:

   ```bash
   ./gradlew clean test -Pgroups=<Comma separated groups/test cases>
   ```

5. To debug the package with a remote debugger:

   ```bash
   ./gradlew clean build -Pdebug=<port>
   ```

6. To debug with the Ballerina language:

   ```bash
   ./gradlew clean build -PbalJavaDebug=<port>
   ```

7. Publish the generated artifacts to the local Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

8. Publish the generated artifacts to the Ballerina Central repository:

   ```bash
   ./gradlew clean build -PpublishToCentral=true
   ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`azure.datalake` package](https://central.ballerina.io/ballerinax/azure.datalake/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
