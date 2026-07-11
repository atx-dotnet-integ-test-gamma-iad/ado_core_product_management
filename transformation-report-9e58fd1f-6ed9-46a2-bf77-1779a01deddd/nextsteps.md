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

Run a NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been resolved using compatibility fallbacks.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface at this stage, particularly those related to obsolete APIs or platform-specific code paths.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify functional correctness:

```bash
dotnet test --configuration Release
```

Review test output carefully. Failures that did not exist in the legacy project may indicate behavioral differences between .NET Framework and cross-platform .NET, particularly in areas such as:

- `System.Configuration` usage (replaced by `Microsoft.Extensions.Configuration`)
- Windows-specific APIs (e.g., registry access, WCF server-side, `System.Drawing`)
- Globalization and encoding defaults
- File path separator differences on non-Windows systems

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining platform-specific API calls. This is included in the SDK and will surface diagnostics during build. Additionally, you can run the API compatibility tool manually:

```bash
dotnet tool install -g Microsoft.DotNet.ApiCompat.Tool
```

Review any reported incompatibilities and replace them with cross-platform equivalents where applicable.

## 6. Review `app.config` or `web.config` Usage

.NET no longer uses `app.config` or `web.config` in the same way as .NET Framework. If `AdoCore` reads configuration from these files, migrate the configuration logic to use `Microsoft.Extensions.Configuration` with `appsettings.json` or environment variables.

## 7. Validate ADO.NET Connectivity

Since the project name suggests ADO.NET usage, verify that database connectivity works as expected:

- Confirm the correct database driver NuGet package is referenced (e.g., `Microsoft.Data.SqlClient` instead of the legacy `System.Data.SqlClient` where applicable).
- Test connection strings and ensure they are being loaded from the updated configuration system.
- Execute integration tests or manual queries against a test database instance to confirm data access behavior is unchanged.

## 8. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be pre-installed on the target machine:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (RID) for your target platform (e.g., `linux-x64`, `osx-x64`).

## 9. Smoke Test the Published Output

After publishing, run the output directly from the publish directory to confirm the application starts and operates correctly outside of the development environment:

```bash
cd ./publish
dotnet AdoCore.dll
```

Or, if published as a self-contained executable, run the generated binary directly.