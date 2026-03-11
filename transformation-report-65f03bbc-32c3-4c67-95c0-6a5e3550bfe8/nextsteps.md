# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the following command to scan for platform-specific API calls that may fail on Linux or macOS:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to any `CA1416` warnings, which flag APIs that are only supported on specific platforms.

### 6. Run the Application
Execute the application directly to confirm it starts and behaves as expected:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Test all major code paths, particularly any that involve file I/O, database access, or network communication, as these areas are most commonly affected by cross-platform migrations.

### 7. Verify NuGet Package Compatibility
Review the packages listed in each `.csproj` or `packages.config` and confirm that each package supports the target framework. The NuGet package page for each dependency lists its supported frameworks. Replace any packages that do not support cross-platform .NET with maintained alternatives where necessary.

### 8. Review Configuration Files
If the project previously used `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or environment variables, as `System.Configuration` has limited support in cross-platform .NET.