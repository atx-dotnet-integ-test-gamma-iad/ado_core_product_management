# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that may indicate compatibility issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers (`CA1416`, etc.).

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release --logger trx
```

Review the `.trx` output files for any failed or skipped tests and investigate the root cause of each.

### 5. Check for Windows-Specific API Usage
Use the .NET Compatibility Analyzer or the `Microsoft.DotNet.PlatformCompat.Analyzer` NuGet package to identify any remaining calls to Windows-only APIs. These will surface as warnings in the build output with the `CA1416` diagnostic code.

### 6. Verify Runtime Behavior on Target Platforms
Run the application on each platform you intend to support (Linux, macOS, Windows) and confirm that:

- File path handling uses `Path.Combine` and does not rely on hardcoded backslashes.
- Any configuration or resource file loading uses platform-neutral paths.
- External process calls or P/Invoke declarations are guarded with runtime platform checks where necessary.

### 7. Review Package Versions
Check that all NuGet dependencies are up to date and compatible with the target framework:

```bash
dotnet list package --outdated
```

Update packages that have newer stable versions available, particularly any that previously had Windows-only implementations.

### 8. Publish a Release Build
Once validation is complete, produce a self-contained or framework-dependent publish to confirm the output is as expected:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment. Verify the published output runs correctly before promoting it further.