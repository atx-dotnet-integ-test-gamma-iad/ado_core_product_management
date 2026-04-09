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

Ensure there are no warnings that could indicate deprecated APIs or compatibility issues that were not surfaced as errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have changed behavior on non-Windows platforms. Review the code for usage of the following, which are common sources of cross-platform issues:

- `System.Drawing` (GDI+ is not fully supported on Linux/macOS without additional packages)
- `Microsoft.Win32` registry APIs
- Windows-specific file path assumptions (backslashes, drive letters)
- `AppDomain` usage
- COM interop

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to surface any remaining compatibility concerns.

## 5. Validate NuGet Package Compatibility

Check that all NuGet dependencies referenced in `AdoCore.csproj` have versions that support your target framework. Run:

```bash
dotnet list package --outdated
```

Update any packages that have newer versions with cross-platform support.

## 6. Test on Target Operating Systems

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime-only issues that do not surface during compilation.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) as needed. Review the output in the `publish` folder before deploying to the target environment.

## 8. Review Configuration Files

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables where applicable, as `System.Configuration` support is limited in cross-platform .NET.