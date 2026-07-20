# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. The project `AdoCore.csproj` compiled without issues.

## Validation

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

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as some failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime (e.g., differences in globalization, reflection, or threading behavior).

### 4. Check Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to an appropriate and supported version, such as:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Refer to the [.NET support lifecycle](https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core) to ensure you are targeting a currently supported version.

### 5. Review Removed or Replaced APIs

Even without build errors, some APIs behave differently or have subtle breaking changes in cross-platform .NET. Review the following areas manually:

- **`System.Configuration`**: If the project previously used `ConfigurationManager`, ensure it has been replaced with `Microsoft.Extensions.Configuration` or an equivalent.
- **`System.Drawing`**: On non-Windows platforms, `System.Drawing.Common` requires native dependencies. Consider replacing it with a cross-platform alternative if multi-OS support is needed.
- **Registry and Windows-specific APIs**: Any calls to `Microsoft.Win32.Registry` or similar will only function on Windows. Add runtime guards if cross-platform execution is required.
- **Reflection and serialization**: Behavior differences may exist, particularly with `BinaryFormatter`, which is disabled by default in modern .NET.

### 6. Run on Target Platforms

If cross-platform support is a goal, test the application explicitly on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that do not appear at compile time.

### 7. Review Warnings

Even a successful build may produce warnings that indicate future compatibility issues. Run the build with warnings treated carefully:

```bash
dotnet build --configuration Release /warnaserror
```

Address any warnings that are surfaced, particularly those related to obsolete APIs or nullable reference types.

### 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained false
```

Replace `<runtime-identifier>` with the appropriate value, for example:
- `win-x64` for Windows
- `linux-x64` for Linux
- `osx-x64` for macOS

Review the publish output directory to confirm all required assets are present before deployment.