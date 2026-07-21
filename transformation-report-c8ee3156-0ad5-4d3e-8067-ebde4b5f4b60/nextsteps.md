# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated package versions that may have been carried over from the legacy project.

### 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while not blocking, may indicate compatibility concerns with the target framework.

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

### 4. Review Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to an appropriate and currently supported version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Refer to the [.NET release schedule](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core) to ensure you are targeting a version that is still under active support.

### 5. Audit Removed APIs

Cross-platform .NET does not include certain APIs that were available in .NET Framework. Run the .NET Upgrade Assistant compatibility analyzer or the platform compatibility analyzer to identify any runtime risks:

```bash
dotnet tool install -g dotnet-upgrade-assistant
upgrade-assistant analyze <solution-file>.sln
```

Address any reported compatibility issues, particularly around areas such as:
- `System.Web` usage
- Windows Registry access
- Windows Communication Foundation (WCF) server-side APIs
- `AppDomain` isolation patterns

### 6. Verify Runtime Behavior on Target Platforms

If cross-platform support (Linux, macOS) is a goal, run the application on each target operating system to surface any platform-specific runtime issues that static analysis may not catch. Pay particular attention to:
- File path separators
- Case-sensitive file system behavior on Linux
- Platform-specific native library dependencies

### 7. Review NuGet Package Versions

Check that all referenced NuGet packages have versions compatible with the target framework. Packages that were built exclusively for .NET Framework may function through compatibility shims but could produce unexpected behavior:

```bash
dotnet list package --outdated
dotnet list package --deprecated
```

Update packages where stable, compatible versions are available.

### 8. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag and `--self-contained` option to match your deployment environment and distribution requirements.