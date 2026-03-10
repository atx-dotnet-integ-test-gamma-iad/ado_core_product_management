# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

## 2. Restore Dependencies

Run a NuGet package restore to ensure all dependencies are resolved correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or unlisted packages that may need to be updated.

## 3. Build the Solution

Perform a full build in Release configuration to confirm there are no configuration-specific issues:

```bash
dotnet build --configuration Release
```

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not been broken during migration:

```bash
dotnet test --configuration Release
```

Review test results carefully, paying attention to any tests that were previously passing but now fail.

## 5. Check for Platform-Specific API Usage

Review the codebase for any APIs that were available in .NET Framework but are not available or behave differently in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (e.g., backslash separators)
- `AppDomain` usage
- COM interop dependencies

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility issues.

## 6. Review NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework. Packages targeting only `net45` or similar legacy monikers may not function correctly. Update packages where newer versions with cross-platform support are available:

```bash
dotnet list package --outdated
```

## 7. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example:
- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS

Review the publish output directory to confirm all required files are present before deployment.