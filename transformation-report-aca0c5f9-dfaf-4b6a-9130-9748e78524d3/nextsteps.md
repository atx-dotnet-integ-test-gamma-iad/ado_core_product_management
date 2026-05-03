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
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Run a full solution build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Review any warnings that appear, as some may indicate compatibility concerns that do not prevent compilation but could cause runtime issues.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully, paying attention to any tests that were previously passing under .NET Framework but now fail under the new target framework.

### 5. Check for Runtime-Only Issues
Some APIs behave differently or are unavailable on non-Windows platforms at runtime even when compilation succeeds. Review the code for usage of the following and test on your target platform:

- `System.Drawing` (requires additional native dependencies on Linux/macOS)
- Windows Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls targeting Windows-specific libraries
- `AppDomain` APIs with limited cross-platform support

### 6. Review NuGet Package Compatibility
Run the following command to check for any outdated or incompatible packages:

```bash
dotnet list package --outdated
```

Update packages where newer versions provide better cross-platform support or address known issues.

### 7. Validate Configuration and File Paths
If the application reads configuration files or uses file paths, verify that path separators and file casing are handled in a platform-agnostic way. Use `Path.Combine` and `Path.DirectorySeparatorChar` rather than hardcoded backslashes.

### 8. Publish the Application
Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained true
```

Replace `<runtime-identifier>` with the appropriate value for your target platform, for example:
- `win-x64`
- `linux-x64`
- `osx-x64`

Review the publish output directory to confirm all required assets and dependencies are present before deploying.