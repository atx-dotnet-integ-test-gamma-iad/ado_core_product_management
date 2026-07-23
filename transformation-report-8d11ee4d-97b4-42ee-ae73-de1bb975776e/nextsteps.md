# Next Steps

## Summary

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution, including `AdoCore.csproj`.

## Validation Steps

### 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated package versions that may need to be updated.

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

Review any test failures carefully, as they may indicate behavioral differences between the original .NET Framework runtime and the new cross-platform .NET runtime.

### 4. Check Target Framework Compatibility

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to an appropriate and consistent version (e.g., `net8.0`). Mixed or outdated target frameworks such as `net6.0` should be updated if long-term support is a requirement.

### 5. Review Platform-Specific APIs

Search the codebase for any APIs that were available in .NET Framework but have known behavioral differences or are unsupported in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` references (not supported cross-platform)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions (e.g., hardcoded backslashes)
- `AppDomain` usage
- `BinaryFormatter` (deprecated and disabled by default in modern .NET)

### 6. Verify Runtime Behavior on Target Platforms

If the intent is to run on non-Windows platforms (Linux, macOS), manually test or run the application on those platforms to surface any remaining platform-specific issues that do not appear as build errors.

### 7. Review NuGet Package Versions

Check that all NuGet dependencies reference versions that support the new target framework. Use the following command to identify outdated packages:

```bash
dotnet list package --outdated
```

Update packages where necessary, being cautious of breaking changes in major version upgrades.

### 8. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment targeting a specific runtime, use:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment target.