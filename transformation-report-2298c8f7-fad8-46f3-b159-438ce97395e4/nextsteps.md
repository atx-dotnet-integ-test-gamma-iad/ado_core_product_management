# Next Steps

The solution has no build errors following the transformation. Below are steps to validate and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the version of the .NET SDK you have installed. You can check your installed SDKs by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to ensure all packages are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages that may need to be updated.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate compatibility concerns.

## 4. Run the Test Suite

If the solution contains test projects, execute all tests to verify functional correctness after the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failures that were not present before the migration should be investigated, as they may indicate behavioral differences between .NET Framework and cross-platform .NET.

## 5. Validate Runtime Behavior

Run the application and exercise its primary workflows manually or through integration tests. Pay particular attention to the following areas that commonly differ between .NET Framework and cross-platform .NET:

- **File paths**: Ensure no hardcoded Windows-style paths (`\`) are used. Use `Path.Combine` or forward slashes where appropriate.
- **Registry access**: `Microsoft.Win32.Registry` is not available on Linux or macOS. If the project uses the registry, this code will need to be replaced.
- **Windows-specific APIs**: Any usage of `System.Drawing`, WCF, or other Windows-specific libraries should be reviewed and replaced with cross-platform alternatives if non-Windows support is required.
- **Configuration**: Confirm that any `App.config` or `Web.config` files have been migrated to `appsettings.json` or equivalent .NET configuration providers.
- **Database connectivity**: If the project uses ADO.NET (suggested by the project name `AdoCore`), verify that the database drivers and connection strings are compatible with the target platform and .NET version.

## 6. Review Removed or Changed APIs

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.ApiCompat` tool to check for any API usage that may be present but behave differently at runtime:

```bash
dotnet tool install -g dotnet-apicompat
```

Refer to the [.NET breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes) for the specific version you are targeting.

## 7. Publish the Application

Once validation is complete, publish the application for your target platform:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate RID, for example:

- `win-x64` for Windows 64-bit
- `linux-x64` for Linux 64-bit
- `osx-x64` for macOS Intel
- `osx-arm64` for macOS Apple Silicon

Review the contents of the publish output directory to confirm all required assets and dependencies are present before deploying.