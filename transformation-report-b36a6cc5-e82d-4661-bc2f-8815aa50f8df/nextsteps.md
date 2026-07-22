# Next Steps

## Build Status

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including `AdoCore.csproj`.

## Validation Steps

### 1. Verify Target Framework
Open `AdoCore.csproj` and confirm the target framework is set to the intended cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore Dependencies
Run a NuGet restore to ensure all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any dependency conflicts or packages that may have been resolved to unexpected versions.

### 3. Build the Solution
Perform a full solution build from the command line to confirm there are no errors outside of the IDE:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Runtime-Specific APIs
Even with a clean build, certain APIs that were available in .NET Framework may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Review the code for usage of the following:

- `System.Web` namespaces
- Windows Registry access (`Microsoft.Win32.Registry`)
- WCF server-side components
- `AppDomain.CreateDomain`
- COM interop or P/Invoke calls targeting Windows-specific libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining compatibility concerns.

### 6. Validate Configuration Files
If the project previously used `app.config` or `web.config`, confirm that configuration has been migrated appropriately to `appsettings.json` or equivalent mechanisms supported by `Microsoft.Extensions.Configuration`.

### 7. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended target operating system (e.g., Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a build.

### 8. Review Package Versions
Check that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with the target framework. Packages targeting `net45` or similar legacy monikers may function via compatibility shims but should be replaced with actively maintained cross-platform equivalents where possible:

```bash
dotnet list package --outdated
```