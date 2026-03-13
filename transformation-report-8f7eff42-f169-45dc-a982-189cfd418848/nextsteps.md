# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

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

Review the output for any warnings that may indicate deprecated APIs or packages that could cause runtime issues even if they do not produce build errors.

## 3. Review NuGet Package Versions

Check all `<PackageReference>` entries in `AdoCore.csproj` and any other projects in the solution. Ensure that packages targeting `.NET Framework` have been replaced with their .NET-compatible equivalents. You can use the following command to check for outdated packages:

```bash
dotnet list package --outdated
```

Update any packages that have newer stable versions compatible with your target framework.

## 4. Run Existing Tests

If the solution contains test projects, execute the test suite to verify runtime behavior:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET (e.g., differences in globalization, threading, or reflection behavior).

## 5. Check for Platform-Specific APIs

Search the codebase for any APIs that were Windows-specific under .NET Framework and may behave differently or throw `PlatformNotSupportedException` on non-Windows platforms. Common areas include:

- `System.Drawing` (use `System.Drawing.Common` NuGet package or an alternative)
- `Microsoft.Win32.Registry`
- WCF server-side components
- `System.Security.Permissions`

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to identify these at compile time.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build.

```bash
dotnet run --configuration Release
```

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
# Framework-dependent deployment
dotnet publish --configuration Release --output ./publish

# Self-contained deployment for a specific platform
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Review the contents of the `./publish` directory to confirm all expected files are present before deploying to the target environment.