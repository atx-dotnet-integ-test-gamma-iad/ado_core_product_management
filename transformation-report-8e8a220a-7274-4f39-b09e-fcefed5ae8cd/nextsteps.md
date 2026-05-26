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
Run a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility issues even if they do not block the build.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Windows-Specific API Usage
Even with a successful build, certain APIs may compile but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer or the following command to surface platform-specific warnings:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to any `CA1416` warnings, which indicate platform-specific API calls.

### 6. Verify Runtime Behavior
Run the application directly and exercise its primary code paths:

```bash
dotnet run --project <YourEntryProject>.csproj --configuration Release
```

Confirm that file I/O, configuration loading, logging, and any external service connections behave as expected.

### 7. Review Removed or Changed APIs
Cross-reference the project against the [.NET Upgrade Assistant compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) for any breaking changes relevant to the APIs used in the codebase. Areas that commonly require attention include:

- `System.Web` references (not available on cross-platform .NET)
- `BinaryFormatter` (disabled by default in .NET 5+)
- `AppDomain` usage
- Registry access (`Microsoft.Win32.Registry`)
- WCF server-side components

### 8. Validate Configuration Files
Ensure that any `app.config` or `web.config` files have been properly migrated to `appsettings.json` or the appropriate .NET configuration model, and that the application reads configuration correctly at runtime.

### 9. Publish a Test Build
Produce a self-contained or framework-dependent publish output and verify it runs in the intended target environment:

```bash
dotnet publish --configuration Release --runtime <target-rid> --output ./publish
```

Replace `<target-rid>` with the appropriate Runtime Identifier, such as `win-x64`, `linux-x64`, or `osx-x64`.