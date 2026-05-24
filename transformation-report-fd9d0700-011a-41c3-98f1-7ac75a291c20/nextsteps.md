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
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them in the `.csproj` files.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Review any warnings, particularly those related to nullable reference types, platform compatibility (`CA1416`), or obsolete APIs.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Investigate any test failures, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer to identify any APIs that are Windows-only. These will surface as `CA1416` warnings during the build. If the application must run cross-platform, replace or conditionally compile those APIs.

You can also use the `dotnet-apicompat` tool or the Microsoft Platform Compatibility Analyzer NuGet package for a more thorough audit:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

### 6. Verify Runtime Behavior
Run the application directly and exercise its primary workflows:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Pay particular attention to:
- File path handling (use `Path.Combine` rather than hardcoded separators)
- Configuration file loading (e.g., `app.config` is not automatically supported; migrate to `appsettings.json` if needed)
- Any reflection-based code, which may behave differently under the new runtime

### 7. Review NuGet Package Versions
Open the `.csproj` files and confirm all referenced NuGet packages have versions that support your target framework. Cross-reference against [nuget.org](https://www.nuget.org) if needed. Replace any packages that only support .NET Framework with their modern equivalents.

### 8. Validate Configuration System
If the project previously relied on `System.Configuration.ConfigurationManager`, confirm you have added the compatibility NuGet package or migrated to the modern configuration system:

```bash
dotnet add package System.Configuration.ConfigurationManager
```

Or migrate to `Microsoft.Extensions.Configuration` for a fully modern approach.