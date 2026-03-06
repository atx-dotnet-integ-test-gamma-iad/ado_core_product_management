# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other .NET Framework monikers unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility issues that did not surface as hard errors.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as some failures may be caused by platform-specific behavior that changed between .NET Framework and cross-platform .NET (e.g., file path separators, culture-sensitive operations, or registry access).

### 5. Check for Windows-Specific API Usage
Even when a project builds successfully, it may contain APIs that only function correctly on Windows. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code for usages of:
- `Microsoft.Win32` namespace
- `System.Windows.Forms` or `System.Drawing` (without the `EnableWindowsFormsHighDpiAutoResizingPolicy` compat shim)
- P/Invoke calls targeting Windows-only native libraries
- `RegistryKey` or other Windows registry APIs

### 6. Validate Runtime Behavior on Target Platforms
If cross-platform support (Linux, macOS) is a goal, run the application on each target operating system and verify core functionality. Pay particular attention to:
- File system path handling (use `Path.Combine` rather than hardcoded separators)
- Case sensitivity in file paths
- Line ending differences (`\r\n` vs `\n`)
- Environment variable names and availability

### 7. Review `App.config` / `Web.config` Migrations
If the original project used `App.config` or `Web.config`, confirm that configuration has been migrated to `appsettings.json` or another supported configuration provider, and that all configuration keys are being read correctly at runtime.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your target environment. Use `--self-contained false` if you intend to rely on a pre-installed .NET runtime on the target machine.

Review the publish output directory to confirm all expected assets and dependencies are present before deploying.