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

Address any warnings that appear, particularly `NU1701` (package compatibility) or `CS0618` (obsolete API usage), as these may indicate areas that need further attention.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures after a framework migration often point to behavioral differences in APIs between .NET Framework and modern .NET.

### 5. Check for Windows-Specific APIs
Even with a successful build, some APIs that compiled successfully may not function correctly on non-Windows platforms at runtime. Use the .NET Compatibility Analyzer to identify these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code for usages of:
- `Microsoft.Win32` registry APIs
- `System.Drawing` (requires additional packages on Linux/macOS)
- P/Invoke calls to Windows-specific native libraries
- `System.Windows.Forms` or `System.Web` references

### 6. Review `App.config` / `Web.config` Migrations
If the original project used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate .NET configuration system. Configuration files from .NET Framework are not automatically processed in modern .NET.

### 7. Validate Runtime Behavior
Run the application manually and exercise its primary workflows. Pay particular attention to:
- File I/O paths, as path separator behavior differs across operating systems
- Reflection-based code, which may be affected by changes in assembly loading
- Serialization/deserialization logic, particularly if `BinaryFormatter` was in use (it is disabled by default in modern .NET)

### 8. Review Removed or Changed APIs
Cross-reference the project's API usage against the [.NET Upgrade Assistant compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/porting/net-framework-tech-unavailable) to identify any APIs that were available in .NET Framework but have been removed or significantly changed in modern .NET.