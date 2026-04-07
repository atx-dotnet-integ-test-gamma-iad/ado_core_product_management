# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only frameworks unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify existing behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test output for any failures or skipped tests that may indicate platform-specific code paths that were not accounted for during transformation.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer to identify any remaining Windows-specific API calls that may compile successfully but fail at runtime on non-Windows platforms. This is already included in the SDK, and warnings will appear during build if platform-specific attributes are present.

You can also manually search for usages of namespaces such as:
- `Microsoft.Win32`
- `System.Windows.Forms`
- `System.Drawing` (without the `Common` variant)
- P/Invoke calls targeting Windows-only system libraries

### 6. Run the Application on Target Platforms
Execute the application on each platform you intend to support (Linux, macOS, Windows) to catch any runtime issues that static analysis may not surface:

```bash
dotnet run --configuration Release
```

Pay attention to file path separators, environment variable differences, and any configuration file loading logic that may behave differently across operating systems.

### 7. Review Output Artifacts
Publish the project and inspect the output to confirm all expected files are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify that no Windows-only native binaries or registry-dependent configurations are included in the published output.