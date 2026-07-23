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

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while not blocking, may indicate compatibility concerns with the target framework.

### 3. Run the Test Suite

If the solution contains test projects, execute all tests to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test results carefully. A successful build does not guarantee correct runtime behavior, particularly after a cross-platform migration.

### 4. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended modern .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the runtime version installed on all target machines.

### 5. Check for Platform-Specific API Usage

Even without build errors, some APIs that compiled successfully may behave differently or throw at runtime on non-Windows platforms. Review usages of the following areas:

- `System.Drawing` (requires additional native dependencies on Linux/macOS)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop or P/Invoke calls
- File path separators and case sensitivity

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify any remaining platform-specific concerns.

### 6. Test on All Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) and validate core functionality manually or through integration tests.

### 7. Review NuGet Package Versions

Confirm that all referenced NuGet packages have versions compatible with the target .NET framework. Packages that previously targeted `.NET Framework` may have newer versions with cross-platform support:

```bash
dotnet list package --outdated
```

Update packages where appropriate, verifying that updates do not introduce breaking API changes.

### 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, such as `win-x64`, `linux-x64`, or `osx-x64`, depending on your deployment target.