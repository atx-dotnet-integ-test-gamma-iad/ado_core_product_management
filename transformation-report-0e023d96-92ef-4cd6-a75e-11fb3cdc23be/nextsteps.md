# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the root of the solution to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

### 2. Build the Solution

Perform a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Debug
dotnet build --configuration Release
```

### 3. Review Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If multiple targets are needed, verify `<TargetFrameworks>` is used correctly.

### 4. Run Existing Tests

If a test project exists in the solution, execute the test suite to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review any failing tests and address them before proceeding.

### 5. Check for Runtime-Only Issues

Some issues do not surface at build time. Manually exercise the core functionality of `AdoCore` to check for:

- Reflection-based code that may behave differently on .NET
- `System.Configuration` or `ConfigurationManager` usage that requires the `System.Configuration.ConfigurationManager` NuGet package
- File path assumptions using backslashes that may fail on Linux or macOS
- Platform-specific API calls that are present in .NET but throw `PlatformNotSupportedException` at runtime

### 6. Review Warnings

Even without errors, build warnings can indicate compatibility concerns. Run the build with a higher verbosity to surface all warnings:

```bash
dotnet build --verbosity normal 2>&1 | grep -i warning
```

Address any warnings related to obsolete APIs or nullable reference types.

### 7. Validate NuGet Package Compatibility

Check that all referenced NuGet packages support the target framework. Packages targeting only `.NET Framework` may have been included via compatibility shims. Review the `packages` or `obj` folder output and consult each package's NuGet page to confirm native .NET support.

### 8. Deploy to Target Environment

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value such as `win-x64`, `linux-x64`, or `osx-x64` depending on your deployment target.

Review the published output in the `bin/Release/<tfm>/<rid>/publish` directory before deploying.