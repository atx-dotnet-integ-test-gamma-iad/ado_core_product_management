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
Perform a full build to confirm there are no warnings that may indicate compatibility issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility analyzers (`CA1416`), as these can indicate runtime issues on non-Windows platforms.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify behavioral correctness after the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may point to platform-specific behavior that was previously masked by the .NET Framework runtime.

### 5. Check for Windows-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the built-in platform compatibility analyzer to identify any remaining Windows-specific API calls. You can also search the codebase for common problem areas such as:

- `System.Windows.Forms`
- `System.Drawing` (requires additional package on Linux/macOS)
- `Microsoft.Win32` registry access
- `System.Runtime.InteropServices` P/Invoke calls targeting Windows DLLs

If any are found, evaluate whether a cross-platform alternative exists or whether a platform guard (`OperatingSystem.IsWindows()`) is appropriate.

### 6. Run on Target Platforms
If cross-platform support is a goal, build and run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime issues that static analysis may not surface:

```bash
dotnet run --configuration Release
```

### 7. Publish the Application
Once validation is complete, publish the application for the target runtime. For a self-contained, platform-specific publish:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, `osx-arm64`, etc.) as needed. Review the publish output directory to confirm all expected assets are present.