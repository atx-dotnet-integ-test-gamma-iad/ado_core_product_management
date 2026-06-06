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
Perform a full build to confirm the absence of errors is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that may indicate compatibility issues that did not surface as hard errors.

### 4. Run the Test Suite
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test results carefully, particularly for any tests that exercise platform-specific behavior such as file paths, registry access, or Windows-specific APIs.

### 5. Check for Platform-Specific API Usage
Even without build errors, the code may reference APIs that compile but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually for usages of:
- `Microsoft.Win32` namespace
- `System.Windows.Forms` or `System.Drawing` (unless the `Windows Compatibility Pack` is intentionally included)
- P/Invoke calls targeting Windows-only native libraries
- `Environment.GetFolderPath` with Windows-specific `SpecialFolder` values

### 6. Run on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Linux, macOS) to catch any runtime-only platform issues:

```bash
dotnet run --configuration Release
```

### 7. Review NuGet Package Compatibility
Confirm that all third-party NuGet packages in use have versions that support the target framework. Check each package on [nuget.org](https://www.nuget.org) if any runtime issues arise.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate Runtime Identifier (RID) for your deployment target. Common RIDs include:
- `win-x64`
- `linux-x64`
- `osx-x64`
- `osx-arm64`

Refer to the [.NET RID Catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog) for a full list of supported identifiers.