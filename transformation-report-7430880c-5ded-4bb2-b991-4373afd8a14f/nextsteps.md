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

Perform a full build to confirm the error-free state observed after transformation holds in your local environment:

```bash
dotnet build --configuration Release
```

Check the output for any warnings that, while non-breaking, may indicate compatibility concerns worth addressing (e.g., nullable reference type warnings, obsolete API usage).

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release
```

Review test results carefully. A successful build does not guarantee correct runtime behavior, so passing tests are an important additional signal.

### 4. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0`):

```xml
<TargetFramework>net8.0</TargetFramework>
```

If it is still referencing a Windows-specific moniker such as `net48` or `net472`, update it accordingly.

### 5. Check for Platform-Specific API Usage

Even without build errors, the code may reference Windows-specific APIs that will fail at runtime on non-Windows platforms. Use the .NET Compatibility Analyzer to surface these issues:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the code manually for usages of APIs such as the Windows Registry, `System.Windows.Forms`, `System.Drawing` (non-cross-platform variant), or COM interop.

### 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Linux, macOS, Windows) to identify any platform-specific runtime failures that static analysis may not catch.

### 7. Review NuGet Package Compatibility

Confirm that all referenced NuGet packages support the target framework. Packages that have not been updated for modern .NET may require replacement with maintained alternatives. Check [nuget.org](https://www.nuget.org) for compatibility information.

### 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value for your target platform, for example:
- `win-x64`
- `linux-x64`
- `osx-x64`

Review the publish output directory to confirm all required assets are present before deploying.