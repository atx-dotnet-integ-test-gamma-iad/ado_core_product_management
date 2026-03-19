# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore and Build Locally
Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Review the output for any warnings that may indicate compatibility concerns, even if they are not hard errors.

### 3. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether they are caused by API differences between .NET Framework and modern .NET.

### 4. Check for Removed or Changed APIs
Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` compatibility tooling to identify any APIs used in the code that behave differently on modern .NET. Pay particular attention to:

- `System.Web` usages (not available on .NET Core/.NET 5+)
- `AppDomain` APIs with limited support
- Reflection APIs that have changed behavior
- `BinaryFormatter` which is disabled by default in .NET 7+

### 5. Review NuGet Package Versions
Open each `.csproj` and verify that all NuGet package references are compatible with the target framework. Run the following to check for outdated packages:

```bash
dotnet list package --outdated
```

Update packages that have newer versions with cross-platform support.

### 6. Validate Platform-Specific Behavior
If `AdoCore` or any dependent project previously relied on Windows-specific functionality (such as the registry, COM interop, or Windows authentication), test explicitly on the target platform(s) to confirm those code paths work as expected or have been replaced with cross-platform alternatives.

### 7. Review Output Artifacts
After a successful Release build, inspect the output directory (typically `bin/Release/net8.0/`) to confirm:

- The expected assemblies are present
- No unintended `.dll` files from old framework dependencies remain
- Any configuration files (e.g., `appsettings.json`) have been carried over correctly

### 8. Smoke Test the Application
Run the application directly from the build output to perform a basic smoke test:

```bash
dotnet ./bin/Release/net8.0/AdoCore.dll
```

Adjust the path and entry point as appropriate for your project type. Confirm the application starts and core functionality operates correctly before proceeding to any further deployment steps.