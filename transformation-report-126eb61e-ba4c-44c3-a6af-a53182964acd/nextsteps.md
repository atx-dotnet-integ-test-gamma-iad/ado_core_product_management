# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they do not cause build failures.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Audit NuGet Package Compatibility

Check all NuGet dependencies to confirm they target .NET Standard 2.0+ or the specific .NET version you are using. Packages that only target .NET Framework may still restore successfully but can cause runtime errors. Use the following command to inspect packages:

```bash
dotnet list package --outdated
```

Replace any incompatible packages with their supported equivalents.

## 5. Check for Platform-Specific API Usage

Review the codebase for any APIs that were available in .NET Framework but are not supported in cross-platform .NET. Common areas to inspect include:

- `System.Web` references (not available in cross-platform .NET)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage with certain methods that are no longer supported
- `BinaryFormatter` (deprecated and disabled by default in .NET 5+)

The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package can assist in identifying these issues.

## 6. Test on Target Platforms

Since the goal is cross-platform support, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

Pay particular attention to file path handling (`Path.Combine` vs hardcoded separators), line ending differences, and case-sensitive file systems on Linux.

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime. For a self-contained deployment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the contents of the `./publish` output directory before deploying.

## 8. Review Configuration Files

Ensure that any `app.config` or `web.config` files have been migrated to `appsettings.json` or environment-based configuration as appropriate for cross-platform .NET. The legacy XML-based configuration system has limited support in modern .NET.