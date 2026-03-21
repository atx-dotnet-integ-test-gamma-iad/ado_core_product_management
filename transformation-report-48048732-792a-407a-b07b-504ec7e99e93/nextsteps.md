# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other legacy .NET Framework moniker unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full build to confirm the no-error state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check both `Debug` and `Release` configurations if your project has configuration-specific code paths.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests that may indicate behavioral differences introduced by the migration.

### 5. Verify Platform-Specific APIs
Search the codebase for any APIs that were available in .NET Framework but have been removed or altered in cross-platform .NET. Common areas to check include:

- `System.Web` usages
- `AppDomain` members that are no longer supported
- Windows Registry access (`Microsoft.Win32.Registry`)
- `BinaryFormatter` (deprecated and disabled by default in .NET 5+)
- `System.Drawing` (requires the `System.Drawing.Common` package and may have platform restrictions)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.ApiCompat` tool to surface any remaining compatibility concerns.

### 6. Run the Application
Execute the application directly to confirm it starts and operates correctly on the target platform:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

If the project is a library rather than an executable, write or run an integration test that exercises its public API surface.

### 7. Publish a Self-Contained Build
Produce a publish output to confirm the application packages correctly for the intended runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) for your deployment target. Review the publish output directory to confirm all expected assets are present.

### 8. Review Warnings
Even with zero errors, the build may emit warnings that indicate future problems. Run the build with a higher diagnostic verbosity to surface them:

```bash
dotnet build --configuration Release --verbosity normal
```

Address any warnings related to nullable reference types, obsolete API usage, or package compatibility.