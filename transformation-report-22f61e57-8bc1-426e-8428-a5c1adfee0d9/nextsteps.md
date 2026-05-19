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
Run a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Review any warnings that appear, as some may indicate runtime issues even if the build succeeds.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee that runtime behavior is unchanged from the original .NET Framework version.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to scan for any APIs that may have been silently replaced or that behave differently on Linux and macOS compared to Windows. You can run the analyzer with:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Only add this package if Windows-specific APIs are required. Otherwise, treat any usage of it as a signal to refactor toward cross-platform alternatives.

### 6. Review Configuration and App Settings
If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables where appropriate, as `System.Configuration.ConfigurationManager` has limited support in cross-platform .NET.

### 7. Validate Runtime Behavior on Target Platforms
Run the application on each intended target operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that static analysis would not catch. Pay particular attention to:

- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Registry access (not available on non-Windows platforms)
- Windows-specific interop or COM dependencies

### 8. Publish the Application
Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate RID for your environment (e.g., `win-x64`, `osx-x64`). Review the publish output directory to confirm all expected assets are present.