# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check that all NuGet dependencies in `AdoCore.csproj` reference current, non-deprecated package versions compatible with your target framework. You can audit packages with:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update any flagged packages accordingly.

## 4. Run Existing Tests

If the solution contains test projects, execute them to confirm existing functionality is preserved:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output for any failing or skipped tests and address them before proceeding.

## 5. Check for Platform-Specific API Usage

Since this was a legacy project, scan the codebase for any Windows-specific APIs that may not behave correctly on Linux or macOS. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` references
- Registry access (`Microsoft.Win32.Registry`)
- Windows file path assumptions (backslashes, drive letters)
- P/Invoke calls to Windows native libraries

Use the .NET Compatibility Analyzer or the following command to surface platform compatibility warnings:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS as applicable) and verify core functionality manually or through integration tests. Pay particular attention to:

- File I/O operations
- Database connectivity (if applicable)
- Configuration file loading (`appsettings.json`, environment variables)

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent (requires .NET runtime installed on target)
dotnet publish --configuration Release --output ./publish

# Self-contained (bundles the runtime)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application starts correctly from that output folder before deploying to the target environment.