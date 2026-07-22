# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

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

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not changed during the transformation:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 4. Check Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the minimum runtime version required by your environment.

### 5. Review Removed or Changed APIs

Cross-platform .NET removes or modifies certain APIs that existed in .NET Framework. Run the .NET Upgrade Assistant compatibility analyzer or the Platform Compatibility Analyzer to surface any runtime-level API issues that do not produce build errors:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze
```

Pay particular attention to:
- `System.Web` usages (not available in cross-platform .NET)
- Windows-specific APIs such as the registry, WCF server-side components, or remoting
- Any reflection-heavy code that may behave differently

### 6. Validate Runtime Behavior

Run the application manually and exercise its primary workflows. Compare the output and behavior against the legacy version to confirm functional equivalence.

### 7. Review NuGet Package Compatibility

Check that all referenced NuGet packages support the new target framework. Packages that only target `net45`, `net472`, or similar legacy monikers may function via compatibility shims but could cause runtime issues:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update any packages that have newer versions with explicit cross-platform .NET support.

### 8. Publish the Application

Once validation is complete, publish the application for your target environment:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value for your target platform, for example `win-x64`, `linux-x64`, or `osx-x64`.