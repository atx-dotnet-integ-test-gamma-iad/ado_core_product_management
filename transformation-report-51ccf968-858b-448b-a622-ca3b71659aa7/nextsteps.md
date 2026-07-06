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

Ensure there are no warnings that could indicate deprecated APIs or packages that may cause runtime issues.

## 3. Review NuGet Package Versions

Check all `<PackageReference>` entries in `AdoCore.csproj` and any other projects in the solution. Confirm that:

- No packages are pinned to versions targeting only .NET Framework.
- Packages have stable, non-prerelease versions unless intentionally using a prerelease.

```bash
dotnet list package --outdated
```

Update any outdated packages as appropriate.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior is consistent with the original project:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and modern .NET.

## 5. Check for Platform-Specific API Usage

Review the codebase for any APIs that were available in .NET Framework but behave differently or are unavailable in cross-platform .NET. Common areas to check include:

- `System.Web` usage (not available in modern .NET)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default)
- COM interop or P/Invoke calls

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 6. Validate Configuration Files

If the project previously relied on `App.config` or `Web.config`, confirm that settings have been migrated to the appropriate modern equivalents:

- `appsettings.json` for application configuration
- `Microsoft.Extensions.Configuration` for configuration access patterns

## 7. Test on Target Operating Systems

Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to identify any platform-specific runtime issues that would not surface during a build.

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag and `--self-contained` option based on your deployment target. Refer to the [.NET RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog) for available runtime identifiers.