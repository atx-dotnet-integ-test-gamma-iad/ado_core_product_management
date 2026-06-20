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

Perform a clean build to confirm there are no issues that were not surfaced during the initial transformation analysis:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to deprecated APIs or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee runtime correctness, so test coverage is important at this stage.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or the following command to scan for APIs that may not be available on all target platforms:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay attention to any `CA1416` (platform compatibility) warnings, which indicate APIs that are Windows-only or otherwise platform-restricted.

## 6. Review `app.config` or `web.config` Migrations

If the original project used `app.config` or `web.config`, verify that configuration has been correctly migrated to `appsettings.json` or another supported configuration mechanism in .NET. Confirm that all configuration keys are being read correctly at runtime.

## 7. Validate Runtime Behavior

Run the application manually and exercise its primary workflows. Pay particular attention to:

- File I/O paths, which may behave differently across operating systems due to path separator differences.
- Registry access or Windows-specific APIs, which will not function on Linux or macOS.
- Any use of `System.Drawing` or other packages that may require additional native dependencies on non-Windows platforms.

## 8. Test on Target Platforms

If cross-platform support is a goal, build and run the application on each intended operating system (Windows, Linux, macOS) to confirm consistent behavior:

```bash
dotnet run --configuration Release
```

## 9. Publish the Application

Once validation is complete, publish the application for deployment:

```bash
dotnet publish --configuration Release --output ./publish
```

If a self-contained deployment is required (no .NET runtime needed on the target machine), use:

```bash
dotnet publish --configuration Release --self-contained true --runtime linux-x64 --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (`win-x64`, `osx-x64`, etc.).

## 10. Review Published Output

Inspect the contents of the `./publish` directory to confirm all expected assemblies, configuration files, and static assets are present before deploying to the target environment.