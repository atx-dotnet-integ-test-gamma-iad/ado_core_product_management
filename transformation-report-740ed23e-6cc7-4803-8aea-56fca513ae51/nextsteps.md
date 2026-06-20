# Next Steps

The transformation appears to have completed successfully. There are no build errors reported across any of the projects in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or any other Windows-only framework unless that is intentional.

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are restored cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that could not be resolved.

## 3. Build the Solution

Perform a full build to confirm there are no compilation issues:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or obsolete APIs, as these can indicate subtle compatibility issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate behavioral differences between .NET Framework and cross-platform .NET, such as changes in:

- `System.Drawing` (not fully supported cross-platform without additional packages)
- `System.Configuration` (replaced by `Microsoft.Extensions.Configuration`)
- Windows-specific APIs (registry access, WCF, etc.)

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer to identify any remaining Windows-specific API calls:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code for usage of APIs decorated with `[SupportedOSPlatform("windows")]` in the .NET runtime source. These will only function correctly on Windows.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

Pay particular attention to:

- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Environment variable differences

## 7. Review Output Artifacts

Check the `bin/Release` output directory to confirm the correct output type is being produced (e.g., `.dll`, self-contained executable, or framework-dependent executable). If a self-contained deployment is needed, publish with:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your target platform (`win-x64`, `osx-x64`, etc.).

## 8. Validate Application Behavior

Run the application end-to-end and compare its behavior against the original .NET Framework version. Focus on:

- Data access and database connectivity
- External service integrations
- Configuration loading
- Logging output

## 9. Review Deprecated or Removed APIs

Consult the official Microsoft documentation on breaking changes between .NET Framework and .NET:

[https://learn.microsoft.com/en-us/dotnet/core/compatibility/fx-core](https://learn.microsoft.com/en-us/dotnet/core/compatibility/fx-core)

This is particularly relevant for `AdoCore`, which likely involves data access. Confirm that all ADO.NET providers in use have cross-platform compatible NuGet packages available and are referenced correctly.