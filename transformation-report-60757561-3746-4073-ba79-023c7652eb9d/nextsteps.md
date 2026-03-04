# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and test the migrated project before deploying it.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net4x` or `netstandard` targets unless that is intentional.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that could not be resolved.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 4. Run Existing Tests

Execute the test suite to verify that existing behavior has been preserved after the migration:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` results files for any failed or skipped tests. Investigate and resolve failures before proceeding.

## 5. Check for Platform-Specific API Usage

Search the codebase for APIs that were Windows-only in .NET Framework and may behave differently or be unavailable on Linux and macOS. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (backslashes, drive letters)
- `AppDomain` usage patterns that changed in .NET Core and later

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining platform-specific calls.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay particular attention to:

- File I/O paths and directory separators
- Culture and encoding defaults, which differ between .NET Framework and modern .NET
- Configuration file loading (e.g., migration from `app.config` to `appsettings.json`)

## 7. Review NuGet Package Versions

Confirm that all third-party NuGet packages in use have versions compatible with the target framework. Check the NuGet package pages or changelogs for any breaking changes introduced between the versions used in the legacy project and the versions now referenced.

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent release build:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained for a specific runtime
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and perform a smoke test by running the published output directly.