# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net472`, `netstandard2.0`, or other legacy monikers unless intentionally kept for compatibility.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them in the relevant `.csproj` files.

### 3. Build the Solution
Perform a clean build to confirm there are no hidden warnings or errors:

```bash
dotnet build --configuration Release
```

Review any warnings in the output, particularly `CS0618` (obsolete API usage) or platform-compatibility warnings (`CA1416`), as these may indicate runtime issues on non-Windows platforms.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the migration:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Investigate any test failures, as they may point to behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer to identify any remaining platform-specific API calls that may not behave correctly on Linux or macOS:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay particular attention to APIs in namespaces such as `Microsoft.Win32`, `System.Drawing`, and `System.Windows.Forms`, which have limited or no cross-platform support.

### 6. Verify Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) to confirm consistent behavior. Pay attention to:

- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Environment variable differences across operating systems
- Culture and encoding defaults, which can differ between .NET Framework and modern .NET

### 7. Review `app.config` / `web.config` Migrations
If the original project used `app.config` or `web.config`, confirm that settings have been migrated to the appropriate modern configuration system, such as `appsettings.json` with `Microsoft.Extensions.Configuration`.

### 8. Publish the Application
Once validation is complete, publish the application for the desired target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your deployment target. Review the output directory to confirm all required assets are present.