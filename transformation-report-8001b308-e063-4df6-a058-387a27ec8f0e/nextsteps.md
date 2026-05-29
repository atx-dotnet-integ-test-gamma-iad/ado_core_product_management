# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy the migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific APIs

Review the codebase for any APIs that were previously available in .NET Framework but may behave differently or be unavailable in cross-platform .NET. Common areas to check include:

- `System.Configuration` (use `Microsoft.Extensions.Configuration` as a replacement)
- `System.Web` (not available outside of Windows)
- Windows Registry access (`Microsoft.Win32.Registry`)
- WCF server-side components (only client-side is supported via `System.ServiceModel`)
- `AppDomain` usage beyond the single default domain

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 5. Run on Target Platforms

If cross-platform support is a goal, test the application explicitly on each intended operating system (Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, line endings, and OS-specific behavior in file I/O operations.

## 6. Review Target Framework Monikers

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If multi-targeting is required, use:

```xml
<TargetFrameworks>net8.0;net472</TargetFrameworks>
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment environment. Review the output directory to confirm all required assets are present before deploying.