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

Check the output for any warnings that may indicate compatibility issues, even if they are not hard errors.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to scan for any APIs that are present but throw `PlatformNotSupportedException` at runtime on non-Windows platforms:

```bash
dotnet add package Microsoft.DotNet.Compatibility
```

Pay particular attention to areas such as:
- `System.Drawing` (requires `libgdiplus` on Linux/macOS or replacement with `SkiaSharp`/`ImageSharp`)
- Windows Registry access (`Microsoft.Win32.Registry`)
- WCF server-side components
- `System.Security.Permissions` and Code Access Security APIs

### 6. Validate Configuration Files
Confirm that any `app.config` or `web.config` files have been migrated to `appsettings.json` or the appropriate .NET configuration model. Legacy XML-based configuration is not automatically processed in cross-platform .NET projects.

### 7. Review `AdoCore.csproj` Specifically
Since `AdoCore` is the project referenced in the transformation output, open its `.csproj` and verify:
- All ADO.NET-related NuGet packages (e.g., database drivers) have been updated to versions that support the target framework.
- Any `System.Data` usage that relied on .NET Framework-specific behavior (such as `DataSet` serialization) is tested explicitly.

### 8. Run on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only platform compatibility issues that static analysis would not catch.