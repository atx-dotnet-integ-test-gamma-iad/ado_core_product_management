# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on all machines that will build or run this project.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been resolved through compatibility shims.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings introduced by the restored packages:

```bash
dotnet build --configuration Release
```

Address any warnings related to deprecated APIs or platform compatibility attributes before proceeding.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully, paying attention to any tests that were previously passing but now fail, as these may indicate subtle behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining calls to Windows-only or legacy APIs. This can be enabled by adding the following to your project file if not already present:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild and review any `CA1416` (platform compatibility) warnings that surface.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) where deployment is intended. Confirm that:

- File path handling works correctly, as path separator differences can cause runtime issues.
- Any configuration files (e.g., `app.config`) have been migrated to `appsettings.json` or equivalent if necessary.
- Any registry access, COM interop, or Windows-specific APIs have been replaced or conditionally compiled.

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example `win-x64`, `linux-x64`, or `osx-x64`. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

Review the publish output directory to confirm all required assets are present before deploying to the target environment.