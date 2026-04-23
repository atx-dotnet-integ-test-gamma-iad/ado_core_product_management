# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`).

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

Review the output for any warnings that may indicate deprecated APIs or compatibility concerns, even if they are not hard errors.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Address any failing tests before proceeding.

## 4. Validate Platform-Specific Code

Review the codebase for any APIs that were previously Windows-only and may now behave differently on Linux or macOS. Common areas to check include:

- File path separators (`\` vs `/`) — use `Path.Combine` and `Path.DirectorySeparatorChar`
- Registry access (`Microsoft.Win32.Registry`) — not available on non-Windows platforms
- Windows-specific interop (`DllImport` with system DLLs)
- `Environment.SpecialFolder` paths that differ across operating systems

## 5. Check NuGet Package Compatibility

Verify that all NuGet dependencies support the target framework. Run the following to identify any compatibility issues:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update packages where necessary using:

```bash
dotnet add package <PackageName> --version <LatestVersion>
```

## 6. Review Removed or Changed APIs

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any APIs that were available in .NET Framework but have been removed or altered in modern .NET.

## 7. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate RID (e.g., `linux-x64`, `osx-x64`) as needed. Review the contents of the `publish` output folder before deploying to confirm all required files are present.