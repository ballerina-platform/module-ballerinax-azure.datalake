# Change Log
This file contains all the notable changes done to the Ballerina Azure Data Lake connector through the releases.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0]

The connector moves to its own repository, `module-ballerinax-azure.datalake`, and is regenerated. It keeps all 12 operations of version 1.5.1.

### Changed

- **Breaking:** the minimum Ballerina distribution is now 2201.13.4 (was 2201.4.1).
- **Breaking:** remote methods are renamed:

    | 1.5.1 | 2.0.0 |
    |---|---|
    | `filesystemList` | `listFilesystems` |
    | `pathList` | `listPaths` |
    | `filesystemCreate` | `createFilesystem` |
    | `filesystemDelete` | `deleteFilesystem` |
    | `filesystemSetproperties` | `setFilesystemProperties` |
    | `filesystemGetproperties` | `getFilesystemProperties` |
    | `pathRead` | `readFile` |
    | `pathCreate` | `createPath` |
    | `pathLease` | `leasePath` |
    | `pathDelete` | `deletePath` |
    | `pathUpdate` | `updatePath` |
    | `pathGetproperties` | `getPathProperties` |

- **Breaking:** optional headers and query parameters are no longer positional arguments. Each method takes a `<Method>Headers` record and named `<Method>Queries` arguments, and path parameters stay positional. For example, `filesystemList("account", prefix = "raw")` becomes `listFilesystems('resource = "account", prefix = "raw")`, and `pathLease(fs, path, "acquire", ...)` becomes `leasePath(fs, path, {xMsLeaseAction: "acquire", ...})`.
- **Breaking:** `readFile` returns the file content as `byte[]` (was `string`).
- **Breaking:** operations that return no body now return `error?` (was `http:Response|error`): `createFilesystem`, `deleteFilesystem`, `setFilesystemProperties`, `createPath`, `leasePath`, `deletePath` and `updatePath`. `getFilesystemProperties` and `getPathProperties` still return `http:Response`, because their results are carried in response headers.
- The `x-ms-version` header now defaults to `2019-10-31`, which Azure Storage requires for bearer-token requests.
- The package README replaces `Module.md` and `Package.md`.

### Removed

- **Breaking:** the `DataLakeStorageError` and `DatalakestorageerrorError` records. No operation returned them. A failed call returns an `http:ClientRequestError` or `http:RemoteServerError` whose detail carries the service's error body.
- The `Cost/Paid`, `Business Intelligence/Analytics` and `Area/Developer Tools` keywords. The package is now tagged `Vendor/Microsoft`, `Area/Storage & File Management` and `Type/Connector`.
