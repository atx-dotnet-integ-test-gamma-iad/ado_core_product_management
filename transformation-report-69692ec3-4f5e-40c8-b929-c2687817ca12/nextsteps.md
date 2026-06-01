# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other legacy .NET Framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve cleanly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no warnings that may indicate compatibility issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility annotations (`[SupportedOSPlatform]`).

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and modern .NET (e.g., changes in `HttpClient`, serialization, threading, or globalization).

### 5. Check for Windows-Specific APIs
If cross-platform support is a goal, use the .NET Compatibility Analyzer to identify any Windows-only API usage:

```bash
dotnet build /p:PlatformTarget=AnyCPU
```

Look for `CA1416` analyzer warnings, which flag calls to APIs that are not available on all platforms.

### 6. Review `app.config` / `web.config` Migrations
If the original project used `app.config` or `web.config`, confirm that configuration has been migrated to `appsettings.json` or environment-based configuration where appropriate. The legacy configuration system is not fully supported in modern .NET.

### 7. Validate Runtime Behavior
Run the application manually and exercise its primary workflows. Pay particular attention to:

- File I/O paths (path separator differences between Windows and Linux/macOS)
- Reflection-based code
- Any use of `BinaryFormatter` (removed in .NET 9, disabled by default in .NET 5+)
- COM interop or P/Invoke calls

### 8. Publish the Application
Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target.