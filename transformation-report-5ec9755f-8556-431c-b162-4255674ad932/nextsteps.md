# Next Steps

The solution appears to have transformed successfully — no build errors were reported across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless intentionally targeting multiple frameworks.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Resolve any warnings about deprecated or unlisted packages by updating them to their current equivalents.

### 3. Build the Solution
Perform a clean build to confirm there are no warnings that could indicate latent issues:

```bash
dotnet build --configuration Release
```

Review any warnings, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review test output carefully. A passing build does not guarantee correct runtime behavior.

### 5. Check for Platform-Specific API Usage
Use the .NET Upgrade Assistant or the `Microsoft.DotNet.PlatformAbstractions` compatibility analyzer to identify any remaining Windows-only API calls that may compile successfully but fail at runtime on Linux or macOS:

```bash
dotnet add package Microsoft.DotNet.Compatibility
```

Pay particular attention to areas such as:
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions
- COM interop or P/Invoke calls
- `System.Drawing` (GDI+) usage

### 6. Review `AdoCore.csproj` Specifically
Since `AdoCore` is the outermost project listed, verify its project references and output type are correctly configured. Open the file and confirm:
- All `<ProjectReference>` paths resolve correctly relative to the new directory structure.
- The `<OutputType>` matches the intended artifact (e.g., `Library`, `Exe`).

### 7. Run on Target Platforms
If cross-platform support is a goal, run or publish the application on each intended operating system:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Test the published output on each target platform to surface any runtime-only platform compatibility issues.

### 8. Review Removed or Changed Configuration
Check that any `app.config` or `web.config` settings that were present in the legacy project have been migrated to `appsettings.json` or the appropriate .NET configuration provider, and that the application reads them correctly at runtime.