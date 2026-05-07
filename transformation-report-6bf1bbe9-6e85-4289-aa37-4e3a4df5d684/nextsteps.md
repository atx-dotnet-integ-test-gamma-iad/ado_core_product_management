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
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm the clean state holds outside of the transformation environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly `NU1701` (package compatibility) warnings, as these can indicate packages that were restored using compatibility fallbacks and may not behave correctly at runtime.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures after a framework migration often point to behavioral differences in APIs between .NET Framework and modern .NET.

### 5. Audit Removed APIs
Check the code for any usage of APIs that are not available in cross-platform .NET. Common areas to inspect include:

- `System.Web` references (not available outside of ASP.NET on .NET Framework)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain.CreateDomain`
- Binary serialization (`BinaryFormatter`)
- `System.Drawing` (requires additional packages on non-Windows platforms)

The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package can assist in identifying these automatically.

### 6. Verify Configuration System
If the project previously used `System.Configuration` (`app.config` / `web.config`), confirm that configuration has been migrated to the appropriate modern equivalent, such as `Microsoft.Extensions.Configuration` with `appsettings.json`.

### 7. Test on Target Platforms
If cross-platform support (Linux, macOS) is a goal, run the application on those operating systems to surface any platform-specific runtime issues that would not appear during a Windows-only build.

### 8. Review Output Artifacts
Confirm the compiled output is placed in the expected location and that all required assets, content files, and embedded resources are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Inspect the `./publish` directory to ensure all runtime dependencies are included.