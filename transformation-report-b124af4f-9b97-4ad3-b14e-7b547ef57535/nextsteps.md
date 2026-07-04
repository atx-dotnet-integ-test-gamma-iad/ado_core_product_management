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
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved references.

### 3. Build the Solution
Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Review any warnings that surface, as some may indicate compatibility concerns that did not produce hard errors.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully, paying attention to any tests that were previously passing but now fail, as these can indicate behavioral differences between .NET Framework and cross-platform .NET.

### 5. Check for Windows-Specific API Usage
Even without build errors, certain APIs behave differently or are unavailable on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually for usage of APIs such as:
- `System.Windows.Forms`
- `Microsoft.Win32` registry access
- `System.Drawing` (requires additional packages on Linux/macOS)
- P/Invoke calls targeting Windows-only native libraries

### 6. Verify Configuration and App Settings
If the project previously used `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or environment variables where appropriate, as `System.Configuration.ConfigurationManager` has limited support in cross-platform .NET.

### 7. Test on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to identify any platform-specific runtime failures that would not appear during a Windows-only build.

### 8. Review Output Artifacts
Confirm the build output is producing the expected artifact type (executable, library, etc.):

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier to match your deployment target.