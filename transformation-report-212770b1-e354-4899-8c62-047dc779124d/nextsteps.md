# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it does not match your intended target, update it and rebuild the solution.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages that may need to be updated.

## 3. Build the Solution

Perform a clean build to confirm there are no hidden warnings or issues:

```bash
dotnet build --configuration Release
```

Review any warnings in the output, as some may indicate compatibility concerns that do not prevent compilation but could cause runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated before proceeding.

## 5. Validate Platform-Specific Code

Check the codebase for any APIs that were previously Windows-only and may now behave differently or be unavailable on other platforms. Common areas to review include:

- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (e.g., backslashes, drive letters)
- `System.Drawing` usage (requires additional packages on non-Windows platforms)
- COM interop or P/Invoke calls targeting Windows libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package where applicable.

## 6. Run the Application on Target Platforms

Execute the application on each platform you intend to support (Windows, Linux, macOS) and verify runtime behavior:

```bash
dotnet run --configuration Release
```

Pay attention to file I/O, environment variable handling, and any third-party library behavior that may differ across operating systems.

## 7. Publish the Application

Once validation is complete, publish the application for your target platform. For a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your target platform (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

For a framework-dependent deployment:

```bash
dotnet publish --configuration Release
```

Review the contents of the `publish` output directory to confirm all required files are present before distribution.