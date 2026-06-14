# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net4x` or `netstandard` targets unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that lack support for the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no issues beyond what was captured in the transformation output:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or platform compatibility (`CA1416`), as these can indicate runtime issues on specific operating systems.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Windows-Specific API Usage
Run the .NET Compatibility Analyzer to identify any APIs that are Windows-only and may not function on Linux or macOS:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to warnings prefixed with `CA1416`. Any such APIs should either be guarded with `OperatingSystem.IsWindows()` checks or replaced with cross-platform alternatives.

### 6. Review `app.config` / `web.config` Migrations
If the original project used `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` and that `Microsoft.Extensions.Configuration` is being used to read those values at runtime.

### 7. Validate Runtime Behavior
Run the application directly and exercise its primary workflows:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Confirm that database connections, file I/O, and any network calls behave as expected on the target platform.

### 8. Publish a Release Build
Once validation is complete, produce a self-contained or framework-dependent publish artifact:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Verify the output in the `./publish` directory runs correctly on the intended target environment.