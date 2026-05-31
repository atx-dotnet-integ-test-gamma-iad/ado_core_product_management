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

Review the output for any warnings about packages that do not fully support the target framework. Check for `NU1701` warnings, which indicate a package was restored using a compatibility fallback.

## 3. Build the Solution

Perform a clean build to confirm there are no errors in a fresh environment:

```bash
dotnet clean
dotnet build --configuration Release
```

Review all warnings in the build output, even if the build succeeds. Warnings related to obsolete APIs or platform compatibility should be addressed before deployment.

## 4. Run the Test Suite

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Pay attention to any tests that were previously passing and are now failing, as these may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining calls to Windows-only or legacy APIs. You can enable this in the project file:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild after adding these properties and review any new `CA1416` (platform compatibility) diagnostics.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS as applicable) to confirm there are no runtime exceptions caused by platform differences, such as file path handling, registry access, or Windows-specific libraries.

## 7. Review Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or equivalent .NET configuration mechanisms, as `System.Configuration` support is limited in cross-platform .NET.

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate RID (`win-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all required assets are present.