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

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to a currently supported version of .NET, such as `net8.0`:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If it is targeting an older version such as `net5.0` or `net6.0`, consider updating to a long-term support (LTS) release.

### 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify runtime behavior matches expectations:

```bash
dotnet test --configuration Release
```

Address any test failures before proceeding, as they may indicate behavioral differences introduced during the migration.

### 5. Audit NuGet Package Compatibility

Review all NuGet dependencies in `AdoCore.csproj` and confirm they have versions compatible with the target framework. Pay particular attention to:

- Packages that previously targeted `.NET Framework` only
- Packages that have known replacements in modern .NET (e.g., `System.Web` dependencies)
- Any packages marked as deprecated on NuGet.org

### 6. Check for Removed or Changed APIs

Even without build errors, some APIs behave differently on cross-platform .NET. Review the code for usage of:

- `System.Web` namespaces
- Windows-specific registry or file path assumptions
- `AppDomain` features that are restricted in modern .NET
- `BinaryFormatter`, which is disabled by default in .NET 5 and later

The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) can assist in identifying these issues if not already used.

### 7. Test on Target Platforms

If cross-platform support is a goal, run and validate the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear as build errors.

### 8. Review Output Artifacts

Confirm the build output is placed in the expected location and that the output type (e.g., `Exe`, `Library`) is correct in the `.csproj` file:

```xml
<OutputType>Exe</OutputType>
```

Publish a self-contained or framework-dependent build to verify the deployment artifact is functional:

```bash
dotnet publish --configuration Release --output ./publish
```

Run the published output directly to confirm it starts and behaves correctly.