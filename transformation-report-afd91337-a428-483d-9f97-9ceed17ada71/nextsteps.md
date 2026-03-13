# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Review any warnings that surface during the build, as some warnings may indicate compatibility concerns that do not prevent compilation but could cause runtime issues.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether the failures are caused by the migration or pre-existing issues.

### 5. Check for Runtime-Only Issues
Some APIs that compiled successfully under .NET Framework may behave differently or throw `PlatformNotSupportedException` at runtime on cross-platform .NET. Exercise the main code paths of the application and pay particular attention to:

- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific APIs (WCF, WPF, Windows Forms if not explicitly targeted)
- `System.Security.Permissions` and Code Access Security (CAS)
- `AppDomain.CreateDomain` and related APIs
- Remoting APIs

### 6. Review NuGet Package Compatibility
Run the .NET Upgrade Assistant or the compatibility analyzer to flag any remaining package references that target only .NET Framework:

```bash
dotnet tool install -g dotnet-outdated-tool
dotnet outdated
```

Replace any packages that do not have a .NET-compatible version with supported alternatives.

### 7. Validate Platform-Specific Behavior
If the application is intended to run on Linux or macOS in addition to Windows, test it explicitly on those platforms. File path separators, line endings, and environment variable conventions differ across operating systems and can surface issues that are not visible on Windows alone.

### 8. Publish the Application
Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
# Framework-dependent publish
dotnet publish --configuration Release

# Self-contained publish for a specific platform
dotnet publish --configuration Release --runtime win-x64 --self-contained true
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Review the publish output directory to confirm all required assets and dependencies are present.