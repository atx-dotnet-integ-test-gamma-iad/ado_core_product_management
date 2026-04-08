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

Address any warnings that surface, particularly `NU1701` warnings, which indicate a package was restored for a different framework and may not be fully compatible.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in globalization, threading, or reflection behavior).

### 5. Review Removed or Changed APIs
Check the code for any APIs that were available in .NET Framework but have changed or been removed in modern .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) can assist with this.

Common areas to review:
- `System.Web` usages (not available in modern .NET)
- `BinaryFormatter` (deprecated and disabled by default)
- `AppDomain` APIs with limited support
- Windows-specific registry or COM interop calls

### 6. Test on Target Platforms
Since the goal is cross-platform support, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific issues:

```bash
dotnet run --configuration Release
```

Pay attention to:
- File path separator differences (`\` vs `/`)
- Case sensitivity on Linux file systems
- Platform-specific native library dependencies

### 7. Review Output Artifacts
Confirm the build output in the `bin/Release` folder contains the expected assemblies and that no unintended `.exe` or platform-specific artifacts are present unless they are required.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier and `--self-contained` flag based on your deployment target. A full list of runtime identifiers is available in the [Microsoft documentation](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).