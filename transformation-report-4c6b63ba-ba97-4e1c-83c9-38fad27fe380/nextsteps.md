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

Address any warnings that appear, particularly `NU1701` (package compatibility) or `CS0618` (obsolete API usage), as these can indicate areas that may cause runtime issues.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify behavioral correctness has been preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate API behavioral differences between .NET Framework and modern .NET.

### 5. Check for Windows-Specific APIs
Even without build errors, certain APIs that compiled successfully may not function correctly on non-Windows platforms at runtime. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code for usages of:
- `Microsoft.Win32` registry APIs
- `System.Drawing` (requires additional packages on Linux/macOS)
- `System.Windows.Forms` or `System.Web` (not supported cross-platform)

### 6. Validate Configuration and App Settings
If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables as appropriate for modern .NET applications.

### 7. Run the Application
Execute the application directly and exercise its primary workflows to confirm runtime behavior matches expectations:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Monitor the output for any runtime exceptions, particularly around database connectivity, file I/O paths, or reflection-based operations that may behave differently on modern .NET.

### 8. Review Nullable Reference Type Warnings
Modern .NET projects often enable nullable reference types by default. If the project has `<Nullable>enable</Nullable>` in the `.csproj`, review any `CS8600`–`CS8625` warnings to prevent potential null reference exceptions at runtime.