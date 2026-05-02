# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that could not be resolved.

## 3. Build the Solution

Perform a full build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types or obsolete APIs, as these can indicate potential runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test output and investigate any failures. Pay particular attention to tests that cover data access or platform-specific functionality, as these areas are most commonly affected by cross-platform migrations.

## 5. Validate Runtime Behavior

Run the application and manually exercise its core functionality, focusing on:

- **Database connectivity**: ADO.NET connection strings and provider names may need to be updated for cross-platform drivers (e.g., replacing `System.Data.SqlClient` with `Microsoft.Data.SqlClient`).
- **File paths**: Ensure no hardcoded Windows-style paths (backslashes) exist in the codebase. Use `Path.Combine` or `Path.DirectorySeparatorChar` where applicable.
- **Configuration**: Verify that any `app.config` or `web.config` files have been migrated to `appsettings.json` or equivalent .NET configuration mechanisms.

## 6. Review Removed Windows-Specific APIs

Check the codebase for any APIs that were previously available in .NET Framework but have limited or no support in cross-platform .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package can assist with identifying these.

## 7. Publish the Application

Once validation is complete, publish the application for the target platform:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value for your target environment, for example:

- `win-x64` for Windows 64-bit
- `linux-x64` for Linux 64-bit
- `osx-x64` for macOS 64-bit

Review the publish output directory to confirm all required files and dependencies are present before deploying.