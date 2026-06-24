# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). Example:

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

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Review the codebase for any APIs that were available in .NET Framework but are not fully supported or behave differently in cross-platform .NET. Common areas to check include:

- `System.Drawing` (requires additional packages on Linux/macOS)
- `Microsoft.Win32` registry APIs (Windows-only)
- WCF server-side components (not fully supported; consider CoreWCF)
- `AppDomain` usage
- Reflection-based serialization (e.g., `BinaryFormatter`, which is obsolete)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface any remaining compatibility issues.

## 5. Validate NuGet Package Compatibility

Check that all referenced NuGet packages target `netstandard2.0`, `netstandard2.1`, or the specific .NET version you are targeting. Packages that only target `net45` or similar legacy monikers may not function correctly.

```bash
dotnet list package --outdated
```

Update any outdated packages where applicable.

## 6. Perform Runtime Validation

Run the application and exercise its primary workflows. Pay attention to:

- File path handling (use `Path.Combine` and avoid hardcoded backslashes)
- Configuration loading (ensure `app.config` has been migrated to `appsettings.json` if applicable)
- Database connectivity if ADO.NET is in use (verify connection strings and driver compatibility)

## 7. Review Output Artifacts

Confirm the build output is placed in the expected directory and that all necessary runtime dependencies are included:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` folder to ensure all required files are present before deploying to the target environment.

## 8. Deploy to Target Environment

Copy the published output to the target machine or server. Ensure the correct .NET runtime version is installed on that machine:

```bash
dotnet --list-runtimes
```

If a self-contained deployment is preferred (no runtime dependency on the target machine), publish with the following options:

```bash
dotnet publish --configuration Release --self-contained true --runtime win-x64 --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target platform (e.g., `linux-x64`, `osx-x64`).