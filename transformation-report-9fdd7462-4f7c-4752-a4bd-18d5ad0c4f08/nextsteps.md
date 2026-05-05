# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy the migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net4x` or `netstandard` targets unless that is intentional.

## 2. Restore Dependencies

Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

## 3. Build the Solution

Perform a clean build to confirm there are no residual issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete API usage, as these can indicate compatibility concerns.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failing or skipped tests. Investigate and resolve failures before proceeding.

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that were Windows-specific in the original .NET Framework project. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- Windows-only interop (`[DllImport]` with Windows system DLLs)
- `AppDomain` usage patterns that differ in .NET Core and later

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to surface any remaining compatibility issues.

## 6. Check Configuration Files

If the project previously used `app.config` or `web.config`, verify that settings have been migrated to the appropriate modern equivalents:

- `appsettings.json` for application configuration
- `Microsoft.Extensions.Configuration` for configuration binding

Confirm that connection strings, environment-specific settings, and logging configuration are all functioning as expected.

## 7. Smoke Test the Application

Run the application manually against a representative set of use cases to confirm runtime behavior matches the original. Pay particular attention to:

- Data access and database connectivity
- File I/O paths (path separators differ between Windows and Linux/macOS)
- Serialization and deserialization behavior
- Any third-party library integrations

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory before deploying to the target environment.