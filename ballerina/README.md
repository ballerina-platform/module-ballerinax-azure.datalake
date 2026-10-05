## Overview

[Azure Data Lake Storage](https://learn.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction) is Microsoft Azure's storage for big data analytics. It adds a hierarchical namespace to Azure Blob Storage, so that data is organized in filesystems, directories and files with POSIX-style permissions and access control lists, and can be used by Hadoop, Spark and other analytics workloads.

The Azure Data Lake connector lets Ballerina programs work with Data Lake Storage through its REST API, version 2019-10-31. It covers filesystems in a storage account, and the files and directories inside them: creating, renaming, listing and deleting paths, uploading and reading file content, managing properties and access control, and leasing files for exclusive access.

### Key features

- Create, list, configure and delete filesystems in a storage account
- Create, rename, list and delete files and directories in a hierarchical namespace
- Upload large files in chunks with append and flush, and read whole files or byte ranges
- Read and update path properties, owners, POSIX permissions and access control lists
- Acquire, renew, change, break and release leases for exclusive write access to a file

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
