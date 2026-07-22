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

### 3. Run Existing Tests

If the solution contains test projects, execute them to verify that runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any test failures carefully, as some may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

### 4. Check Target Framework Compatibility

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to an appropriate and consistent version (e.g., `net8.0`). Mixed or outdated target frameworks such as `net6.0` may still function but should be updated to a supported version.

### 5. Review Platform-Specific API Usage

Even without build errors, certain APIs that were available in .NET Framework may behave differently or have reduced functionality on cross-platform .NET. Pay particular attention to:

- `System.Windows.Forms` or `System.Web` references, which are not fully supported cross-platform
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions
- COM interop usage

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining compatibility concerns.

### 6. Run the Application

Execute the application directly and exercise its primary workflows to confirm functional correctness:

```bash
dotnet run --project AdoCore/AdoCore.csproj --configuration Release
```

### 7. Verify Output Artifacts

Publish the project and inspect the output to confirm all expected files, assets, and dependencies are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Review the `./publish` directory to ensure no files are missing compared to the legacy build output.

### 8. Address Runtime Warnings

Even if the build succeeds, run the application with detailed diagnostic output and review any runtime warnings that may point to deprecated or unsupported functionality:

```bash
dotnet run --configuration Release 2>&1 | tee runtime_output.log
```