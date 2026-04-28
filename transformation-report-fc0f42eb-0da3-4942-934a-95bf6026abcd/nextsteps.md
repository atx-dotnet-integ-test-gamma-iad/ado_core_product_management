# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other .NET Framework moniker unless that is intentional for multi-targeting.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that could indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully, particularly for any tests that may have been skipped or that exercise platform-specific code paths.

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the build output for `CA1416` warnings, which indicate APIs that are only available on specific operating systems (e.g., Windows-only registry or WinForms APIs). Address these by either:
- Adding a runtime platform guard (`OperatingSystem.IsWindows()`)
- Replacing the API with a cross-platform alternative

### 6. Review Configuration and File Paths
Confirm that any hardcoded file paths use `Path.Combine` or `Path.DirectorySeparatorChar` rather than backslashes, which will not behave correctly on Linux or macOS.

### 7. Verify Runtime Behavior
Run the application on each target operating system (Windows, Linux, macOS) if cross-platform support is a requirement. Pay particular attention to:
- File I/O operations
- Encoding and culture-sensitive operations
- Any use of `System.Drawing` or other packages that have platform-specific native dependencies

### 8. Publish the Application
Once validation is complete, publish the application for the desired target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all required assets are present.