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

Resolve any warnings about deprecated or unlisted packages by updating them to their current cross-platform equivalents.

### 3. Build the Solution
Perform a full build to confirm the absence of errors is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Review any warnings that surface during the build, as some may indicate compatibility concerns that do not block compilation but could cause runtime issues.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify behavioral correctness after the transformation:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures at this stage often indicate platform-specific assumptions in the original code (e.g., Windows file path separators, registry access, or Windows-only APIs).

### 5. Check for Platform-Specific API Usage
Use the .NET Compatibility Analyzer or review the code manually for any calls to APIs that are not supported on all target platforms. Common areas to check include:

- `System.Windows.Forms` or `System.Drawing` (require additional packages on non-Windows)
- `Microsoft.Win32` registry access
- P/Invoke calls to Windows-native DLLs
- Hardcoded file path separators (`\` instead of `Path.Combine` or `Path.DirectorySeparatorChar`)

### 6. Run on All Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime-only issues that the compiler would not catch.

```bash
dotnet run --configuration Release
```

### 7. Publish the Application
Once validation is complete, publish the application using the appropriate runtime identifier for each target platform:

```bash
# Windows
dotnet publish -c Release -r win-x64 --self-contained true

# Linux
dotnet publish -c Release -r linux-x64 --self-contained true

# macOS
dotnet publish -c Release -r osx-x64 --self-contained true
```

Review the output directory to confirm all required assets and dependencies are present before distributing.