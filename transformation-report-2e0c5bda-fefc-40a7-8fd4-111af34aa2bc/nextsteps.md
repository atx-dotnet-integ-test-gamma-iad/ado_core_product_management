# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other .NET Framework monikers unless a multi-targeting scenario is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a clean build to confirm there are no errors or warnings that may have been suppressed during transformation:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate compatibility issues at runtime.

### 4. Run Existing Tests
If the solution contains test projects, execute the full test suite:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and cross-platform .NET (e.g., differences in globalization, file path handling, or reflection behavior).

### 5. Check for Windows-Specific API Usage
Even without build errors, certain APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually or use the API Portability Analyzer tool to identify any remaining platform-specific calls such as those in `Microsoft.Win32`, `System.Drawing`, or P/Invoke declarations.

### 6. Review `App.config` / `Web.config` Migrations
If the original project used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or the appropriate .NET configuration provider. Configuration handling changed significantly between .NET Framework and cross-platform .NET.

### 7. Validate Runtime Behavior
Run the application and exercise its primary code paths. Pay particular attention to:

- File I/O operations that use hardcoded backslashes (`\`) in paths — replace with `Path.Combine` or `Path.DirectorySeparatorChar`.
- Culture-sensitive string operations that may behave differently under ICU (used by default in .NET 5+) versus NLS.
- Any use of `AppDomain`, `Remoting`, or `BinaryFormatter`, which are either removed or restricted in cross-platform .NET.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier (`win-x64`, `osx-x64`, `linux-arm64`, etc.) to match your deployment target. Use `--self-contained true` if the runtime will not be pre-installed on the target machine.