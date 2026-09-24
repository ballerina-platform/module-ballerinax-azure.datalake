_Author_: @DimuthuMadushan \
_Created_: 2026/09/24 \
_Updated_: 2026/09/24 \
_Edition_: Swan Lake

# Sanitation for OpenAPI specification

This document records the sanitation done on top of the official OpenAPI specification from Azure Data Lake. 
The OpenAPI specification is obtained from the [Azure Data Lake Storage 2019-10-31 specification](https://github.com/wso2/api-specs/blob/main/openapi/azure/datalake/2019-10-31/openapi.yml) (`openapi/azure/datalake/2019-10-31/` in `api-specs`), which is the upstream `DataLakeStorageClient` Swagger 2.0 document.
These changes are done in order to improve the overall usability, and as workarounds for some known language limitations.

1. **Added the `azure_auth` security scheme** (applied to `docs/spec/openapi.json`, before flatten and align)

   **Location**: top level — `securityDefinitions` and `security`

   **Original**: The specification declared no security scheme. The upstream document relies on AutoRest's host-side authentication, so the generated `ConnectionConfig` had no `auth` field.

   **Updated**: Added an `azure_auth` OAuth 2.0 scheme (implicit flow, authorization URL `https://login.microsoftonline.com/common/oauth2/authorize`, scope `user_impersonation`) and a top-level `security: [{"azure_auth": ["user_impersonation"]}]`. This is the same scheme the previously published connector (`ballerinax/azure.datalake` 1.5.1) declared.

   **Reason**: Data Lake Storage calls are authorized with a Microsoft Entra ID bearer token. With the scheme in place, the generated `ConnectionConfig` carries `http:BearerTokenConfig auth`.

2. **Gave `x-ms-version` a default of `2019-10-31`** (applied to `docs/spec/aligned_ballerina_openapi.json`)

   **Location**: `components.parameters.Version` (the `x-ms-version` header, shared by all 12 operations)

   **Original**: An optional header with no default, described as "required when using shared key authorization".

   **Updated**: `schema.default: "2019-10-31"`, and a description stating that the header is required for every authorized request, including those that use a bearer token.

   **Reason**: Azure Storage rejects Microsoft Entra ID requests that do not send `x-ms-version` 2017-11-09 or later. With the default, every generated `*Headers` record has `string xMsVersion = "2019-10-31"`, so the header is sent even when the caller passes no headers.

3. **Typed the append payload of `updatePath` as binary** (applied to `docs/spec/aligned_ballerina_openapi.json`)

   **Location**: `PATCH /{filesystem}/{path}` — `requestBody.content` (`application/octet-stream` and `text/plain`)

   **Original**: `{"type": "object", "format": "file"}`, which is how the Swagger 2.0 to OpenAPI 3.0 conversion renders the upstream `body` parameter.

   **Updated**: `{"type": "string", "format": "binary"}`.

   **Reason**: The request body is the raw file data to append. The binary schema generates a `byte[] payload` parameter, which is what the previously published connector took.

4. **Narrowed the `readFile` response to `application/octet-stream`** (applied to `docs/spec/aligned_ballerina_openapi.json`)

   **Location**: `GET /{filesystem}/{path}` — `responses.200.content` and `responses.206.content`

   **Original**: Three content types (`application/json`, `application/octet-stream`, `text/plain`), each with a `string`/`binary` schema.

   **Updated**: `application/octet-stream` only, with the same `string`/`binary` schema.

   **Reason**: With three binary content types the generator returned `record {byte[] fileContent; string fileName;}`. The HTTP client cannot bind raw file bytes to that record, so every live read would fail. The service returns the file's own stored content type, whichever it is. The single binary content type generates `returns byte[]|error`, and binding to `byte[]` does not depend on the response content type.

5. **Added descriptions to undocumented schemas and fields** (applied to `docs/spec/aligned_ballerina_openapi.json`)

   **Location**: `components.schemas` — `Path`, `PathList`, `Filesystem`, `FilesystemList` and `DataLakeStorageError`, and every field of the first four

   **Original**: No `description`.

   **Updated**: Short descriptions, for example "The path of the file or directory, relative to the filesystem root" for `Path.name`. `DataLakeStorageError.error` was a bare `$ref`, so its description ("The service error response object") is kept by wrapping it as `{"allOf": [{"$ref": "..."}], "description": "..."}`.

   **Reason**: The descriptions become the doc comments of the generated records. `DataLakeStorageError` is referenced only by the `default` error responses, which the client maps to `error`, so it is not generated into the package; its descriptions document the spec and the test mock.

## OpenAPI cli command

The following command was used to generate the Ballerina client from the OpenAPI specification. The command should be executed from the repository root directory.

```bash
bal openapi -i docs/spec/aligned_ballerina_openapi.json -o ballerina --mode client --client-methods remote --license docs/license.txt
```

Note: The license year is hardcoded to 2026, change if necessary.
