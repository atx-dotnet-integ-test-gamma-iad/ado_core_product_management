# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

### 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while non-blocking, may indicate deprecated APIs or framework-specific code paths that could cause runtime issues.

### 3. Run the Test Suite

If the solution contains test projects, execute them to verify runtime behavior:

```bash
dotnet test --configuration Release
```

Review test results carefully. A successful build does not guarantee correct runtime behavior, particularly for code that previously relied on Windows-specific APIs or .NET Framework-only features.

### 4. Review Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If the project needs to support multiple frameworks simultaneously, consider using `<TargetFrameworks>` (plural) with a semicolon-separated list.

### 5. Check for Platform-Specific API Usage

Even without build errors, some APIs may compile successfully but fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code for usages of:
- `System.Windows.Forms` or `System.Drawing` (GDI+)
- `Microsoft.Win32` registry access
- `System.Runtime.InteropServices` P/Invoke calls targeting Windows DLLs
- `AppDomain.SetupInformation` or other removed APIs

### 6. Validate Configuration Files

If the project previously used `app.config` or `web.config`, confirm that settings have been migrated to the appropriate cross-platform equivalents such as `appsettings.json` and `Microsoft.Extensions.Configuration`.

### 7. Test on Target Platforms

If cross-platform support is a requirement, run the application on each intended operating system (Linux, macOS, Windows) to catch any platform-specific runtime failures that static analysis may not surface.

```bash
dotnet run --configuration Release
```

### 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

Refer to the [.NET Runtime Identifier catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog) for a full list of supported runtime identifiers.