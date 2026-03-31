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
Run a full solution build to confirm the no-error state is consistent:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly `NU1701` (package compatibility) or `CS0618` (obsolete API usage), as these can indicate runtime risk even when the build succeeds.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests and investigate the cause of each.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any APIs that are Windows-only or otherwise platform-restricted. This is particularly relevant for `AdoCore` if it interacts with system-level resources.

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution>.sln
```

Review the generated report for `PlatformNotSupportedException` risks.

### 6. Verify Runtime Behavior
Run the application on each target platform (Windows, Linux, macOS as applicable) and exercise the primary code paths manually or through integration tests to confirm there are no platform-specific runtime failures that would not surface at compile time.

### 7. Review Configuration and File Paths
Check any hardcoded file paths, registry access, or Windows-specific configuration patterns (e.g., `app.config` sections relying on `System.Configuration`) and replace them with cross-platform equivalents such as `Microsoft.Extensions.Configuration` where necessary.

### 8. Publish the Application
Once validation is complete, produce a release publish artifact:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier (`win-x64`, `osx-x64`, etc.) and `--self-contained` flag to match your deployment target requirements.