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

Perform a full build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Debug
dotnet build --configuration Release
```

### 3. Review Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If multiple targets are needed, verify `<TargetFrameworks>` is set correctly.

### 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and modern .NET.

### 5. Check for Runtime-Only Issues

Some issues do not surface at build time. Manually exercise the primary code paths of `AdoCore` to check for:

- `PlatformNotSupportedException` thrown at runtime for APIs that are not supported on Linux or macOS.
- Missing configuration files or resources that were previously embedded or deployed differently.
- Any use of the Windows registry, COM interop, or Windows-specific APIs that may fail silently or throw on non-Windows platforms.

You can use the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) to help identify platform-specific API usage statically.

### 6. Review Removed or Changed APIs

Check the project for any use of APIs that were removed or changed in modern .NET. The [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) and the `Microsoft.DotNet.UpgradeAssistant` tool can assist with identifying these areas even after a transformation.

### 7. Validate NuGet Package Compatibility

Ensure all referenced NuGet packages support the target framework. Packages that only target `net45` or `net472`, for example, may have been included via compatibility shims. Verify that modern equivalents are used where available.

```bash
dotnet list package --outdated
```

### 8. Publish and Smoke Test

Once the above steps pass, produce a publish output and run a basic smoke test:

```bash
dotnet publish --configuration Release --output ./publish
```

Execute the published output on each target platform (Windows, Linux, macOS) that the project is expected to support and verify expected behavior.