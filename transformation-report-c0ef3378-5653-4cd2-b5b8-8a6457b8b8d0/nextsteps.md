# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version installed on your machine. Run the following to confirm:

```bash
dotnet --version
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that may have been replaced during the transformation (e.g., `System.Data.SqlClient` replaced by `Microsoft.Data.SqlClient`).

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate runtime issues even when the build succeeds.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify that behavior has not changed after the transformation:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

If no tests exist, consider writing unit tests for the core data access logic in `AdoCore` to establish a baseline before further changes.

## 5. Validate ADO.NET Functionality

Since this project appears to be ADO.NET-based, manually verify the following at runtime:

- Database connections open and close correctly.
- Commands execute without throwing exceptions related to provider incompatibilities.
- Connection strings are correctly sourced from configuration (e.g., `appsettings.json` rather than `app.config` or `web.config`, which may not be fully supported cross-platform).

If `app.config` is still in use, consider migrating connection strings and settings to `appsettings.json` using `Microsoft.Extensions.Configuration`:

```xml
<PackageReference Include="Microsoft.Extensions.Configuration.Json" Version="8.0.0" />
```

## 6. Check Platform-Specific Code

Review the codebase for any Windows-specific APIs that may have been carried over, such as:

- `System.Windows` namespaces
- Windows Registry access
- COM interop

These will compile but will throw `PlatformNotSupportedException` at runtime on non-Windows systems. Use `RuntimeInformation.IsOSPlatform` guards or replace with cross-platform alternatives where needed.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended target runtime identifier (e.g., `win-x64`, `osx-x64`). Use `--self-contained true` if the target machine does not have the .NET runtime installed.