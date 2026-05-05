# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 2. Restore NuGet Packages
Run the following command from the solution root to ensure all dependencies resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved dependencies.

### 3. Build the Solution
Perform a full build to confirm there are no errors in the restored state:

```bash
dotnet build --configuration Release
```

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review test output carefully, paying attention to any tests that were previously passing but now fail, as these may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Platform-Specific API Usage
Even without build errors, some APIs that compiled successfully may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review any warnings produced and replace affected APIs with cross-platform alternatives where necessary.

### 6. Review `app.config` / `web.config` Usage
Legacy configuration files are not fully supported in cross-platform .NET. Confirm that any configuration previously handled by these files has been migrated to `appsettings.json` or another supported mechanism such as `IConfiguration`.

### 7. Verify Runtime Behavior
Execute the application manually and exercise its primary workflows. Pay particular attention to:

- File system path handling (use `Path.Combine` rather than hardcoded separators)
- Registry access (not available on non-Windows platforms)
- Windows Communication Foundation (WCF) server-side components (not supported in cross-platform .NET)
- Any use of `System.Drawing` (requires additional native dependencies on Linux/macOS)

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example `win-x64`, `linux-x64`, or `osx-x64`. Review the published output directory to confirm all expected files are present before deploying.