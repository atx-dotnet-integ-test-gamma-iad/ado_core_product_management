# Next Steps

The solution appears to have transformed successfully — no build errors were reported across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other .NET Framework monikers unless a multi-targeting scenario is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no hidden warnings or errors:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings (CA1416).

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify functional correctness after the transformation:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests that may indicate behavioral regressions.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the built-in Roslyn analyzers to identify any remaining Windows-specific API calls that may not behave correctly on Linux or macOS:

```bash
dotnet add package Microsoft.DotNet.PlatformCompat.Analyzer
dotnet build
```

Pay particular attention to APIs in the `System.Windows`, `Microsoft.Win32`, or `System.Drawing` namespaces, as these may require replacement packages such as `System.Drawing.Common` or alternative libraries.

### 6. Verify Configuration and App Settings
Confirm that any `App.config` files have been migrated to `appsettings.json` where applicable, and that the application reads configuration correctly using `Microsoft.Extensions.Configuration`.

### 7. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time.

### 8. Review Output Artifacts
Check the `bin/Release` output directory to confirm the expected assemblies, runtime identifiers, and any self-contained publish artifacts are present as intended.

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag to match your deployment target.