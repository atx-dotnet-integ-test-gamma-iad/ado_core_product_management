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

Review any warnings that appear, as some may indicate compatibility concerns that do not block the build but could cause runtime issues.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior is consistent with expectations:

```bash
dotnet test --configuration Release
```

Pay attention to any tests that were previously passing under .NET Framework but now fail, as these may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in globalization, reflection, or threading).

### 5. Check for Runtime-Only Issues
Some incompatibilities do not surface at compile time. Review the following areas manually:

- **P/Invoke and native interop**: Any calls to Windows-specific native libraries will not work on Linux or macOS.
- **Registry access**: `Microsoft.Win32.Registry` APIs are Windows-only.
- **`System.Drawing`**: If used, it requires the `System.Drawing.Common` package and has platform restrictions on non-Windows systems.
- **`AppDomain`**: Some `AppDomain` members are no longer supported and will throw `PlatformNotSupportedException` at runtime.
- **Configuration**: If the project used `System.Configuration.ConfigurationManager`, verify the NuGet package for it has been added and that `.config` files have been migrated appropriately.

### 6. Validate Output Artifacts
After a successful Release build, inspect the output directory (typically `bin/Release/net8.0/`) and confirm:

- The expected assemblies and dependencies are present.
- No unexpected `.dll` files from legacy references remain.

### 7. Smoke Test the Application
Run the application manually against a representative set of inputs or workflows to confirm end-to-end behavior is correct before broader deployment.

```bash
dotnet run --configuration Release --project ./AdoCore/AdoCore.csproj
```

Adjust the project path as appropriate for your solution structure.