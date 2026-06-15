# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and test the migrated project before deploying it.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless explicitly required.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts and update them as needed.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that were not surfaced during the transformation:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers.

## 4. Run the Test Suite

Execute all unit and integration tests to verify that behavior has not changed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` result files for any failures or skipped tests. Pay particular attention to tests that cover platform-specific functionality, as these are the most likely areas to have been affected by the migration.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining Windows-only API calls that may compile successfully but fail at runtime on Linux or macOS:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Review any `CA1416` (platform compatibility) warnings and add appropriate runtime guards or replace the APIs with cross-platform alternatives.

## 6. Run the Application Locally on Each Target Platform

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) and verify core functionality manually or through smoke tests.

```bash
dotnet run --configuration Release
```

## 7. Publish a Self-Contained or Framework-Dependent Build

Produce a release build artifact to confirm the publish process works end to end:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish-linux
```

Verify the output directory contains the expected files and that the application starts correctly from the published output.

## 8. Review Configuration and Environment Variables

Confirm that any configuration previously handled by `app.config` or `web.config` has been correctly migrated to `appsettings.json` or environment variables, and that the application reads these values correctly at runtime.