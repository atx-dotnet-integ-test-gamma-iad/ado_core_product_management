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
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no hidden build issues:

```bash
dotnet build --configuration Release
```

Review all warnings in the output, as some warnings may indicate compatibility concerns that do not block the build but could cause runtime issues.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 5. Check for Windows-Specific API Usage
Even if the build succeeds, some APIs that compiled successfully may not behave correctly or may throw `PlatformNotSupportedException` at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually for usages of:
- `Microsoft.Win32` registry APIs
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- COM interop
- P/Invoke calls targeting Windows-only system libraries

### 6. Run the Application
Execute the application directly and exercise its primary code paths:

```bash
dotnet run --project ./AdoCore/AdoCore.csproj --configuration Release
```

Observe runtime behavior and check application logs for any exceptions or unexpected behavior.

### 7. Validate on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to confirm consistent behavior across platforms.

### 8. Publish the Application
Once validation is complete, publish a self-contained or framework-dependent build as appropriate:

```bash
# Framework-dependent
dotnet publish --configuration Release --output ./publish

# Self-contained (example for Linux x64)
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish/linux-x64
```

Review the output directory to confirm all required files are present before deploying to the target environment.