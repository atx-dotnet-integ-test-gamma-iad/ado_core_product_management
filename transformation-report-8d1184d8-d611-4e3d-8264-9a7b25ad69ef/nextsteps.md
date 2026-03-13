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

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no issues beyond what was captured in the transformation output:

```bash
dotnet build --configuration Release
```

Review all warnings in addition to errors, as warnings may indicate compatibility concerns that could surface at runtime.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

### 5. Check for Windows-Specific API Usage
Even if the project builds successfully, certain APIs that compiled under .NET Framework may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually for usages of:
- `System.Windows.Forms` or `System.Web`
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop (`DllImport` targeting Windows-only DLLs)
- `System.Drawing` (GDI+) without the `System.Drawing.Common` package

### 6. Validate Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS) if cross-platform support is a requirement. Pay particular attention to:
- File path separators (`\` vs `/`)
- Case sensitivity of the file system
- Environment variable names and availability
- Line ending differences (`\r\n` vs `\n`)

### 7. Review `app.config` / `web.config` Migration
If the original project used `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or another supported mechanism, and that the application reads configuration correctly at runtime.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all required assets are present.