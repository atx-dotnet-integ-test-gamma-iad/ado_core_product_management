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

Check the output for any warnings that, while non-blocking, may indicate compatibility concerns worth addressing.

### 3. Review Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to a currently supported version of .NET, such as `net8.0`. Avoid using end-of-life versions like `net5.0` or `net6.0` unless there is a specific requirement.

```xml
<TargetFramework>net8.0</TargetFramework>
```

### 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Address any test failures by comparing behavior between the original .NET Framework version and the new cross-platform version.

### 5. Verify Platform-Specific API Usage

Review the codebase for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET. Common areas to check include:

- `System.Web` usage
- Windows Registry access (`Microsoft.Win32.Registry`)
- Windows Communication Foundation (WCF) server-side components
- `AppDomain` usage beyond what is supported in .NET Core and later
- `BinaryFormatter` (deprecated and disabled by default)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` package to identify remaining issues.

### 6. Test on Target Platforms

Since the goal is cross-platform support, run and validate the application on each intended operating system (e.g., Windows, Linux, macOS):

```bash
dotnet run --configuration Release
```

Pay particular attention to file path separators, line endings, and any OS-specific behavior in the existing code.

### 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment. Use `--self-contained true` if the target machine does not have the .NET runtime installed.

Refer to the full list of runtime identifiers in the [Microsoft documentation](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).