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
Perform a full build to confirm the clean state holds outside of the transformation environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly `NU1701` warnings which indicate packages were restored for a different framework and may not be fully compatible.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Windows-Specific API Usage
Even with a successful build, certain APIs may compile but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code for usages of:
- `Microsoft.Win32` registry APIs
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- P/Invoke calls targeting Windows-only native libraries
- `AppDomain` APIs with limited cross-platform support

### 6. Validate Configuration and File Paths
Check that any hardcoded file paths use `Path.Combine` or `Path.DirectorySeparatorChar` rather than hardcoded backslashes, which will cause failures on Linux and macOS.

### 7. Review Removed `App.config` / `Web.config` Behavior
If the original project relied on `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` or another supported mechanism, and that the application reads it correctly at runtime.

### 8. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to catch any platform-specific runtime issues that static analysis may not surface.

### 9. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value for your target platform, for example `win-x64`, `linux-x64`, or `osx-x64`. Review the output directory to confirm all required assets are present before deploying.