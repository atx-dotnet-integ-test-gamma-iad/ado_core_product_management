# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

### 2. Restore Dependencies
Run a full NuGet restore from the solution root to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm the absence of errors is consistent:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types, obsolete APIs, or platform compatibility analyzers (CA1416, etc.).

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests and investigate the root cause of each.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to identify any calls to Windows-only APIs that may compile successfully but fail at runtime on Linux or macOS.

Run the application on each target platform to surface any platform-specific runtime exceptions.

### 6. Validate Runtime Behavior
Execute the application manually and exercise the primary workflows to confirm functional correctness after the migration. Pay particular attention to:

- File path handling (use `Path.Combine` rather than hardcoded separators)
- Environment variable access
- Any registry access, which is Windows-only
- Any use of `System.Drawing` or WinForms/WPF components, which require additional packages or are not cross-platform

### 7. Review NuGet Package Versions
Check that all third-party NuGet packages in use have versions that support the target framework. You can inspect compatibility on [nuget.org](https://www.nuget.org) or by reviewing the `lib` folders inside the `.nupkg` files.

### 8. Publish a Self-Contained Build
Produce a self-contained publish artifact for each target runtime to confirm the output is complete:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
dotnet publish --configuration Release --runtime win-x64 --self-contained true
```

Verify the output directories contain all required files and that the executable runs on the respective platform.