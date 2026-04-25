# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore and Build Locally

Run the following commands from the solution root to confirm a clean restore and build:

```bash
dotnet restore
dotnet build --configuration Release
```

Verify that no warnings or errors appear in the output.

## 3. Run Existing Tests

If a test project exists in the solution, execute the test suite to confirm existing functionality is intact:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and address regressions introduced during the migration.

## 4. Check for Platform-Specific API Usage

Even without build errors, some APIs may have been silently replaced or may behave differently on non-Windows platforms. Use the .NET Compatibility Analyzer to surface any remaining platform-specific calls:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
dotnet build
```

Review any analyzer warnings that are reported.

## 5. Validate NuGet Dependencies

Confirm that all NuGet packages referenced in `AdoCore.csproj` have versions compatible with your target framework:

```bash
dotnet list package --outdated
dotnet list package --vulnerable
```

Update any outdated or vulnerable packages as appropriate.

## 6. Test on Target Platforms

Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) to catch any runtime issues that do not surface at compile time:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators
- Environment variable access
- Registry access (not available on non-Windows)
- Windows-specific interop or P/Invoke calls

## 7. Review Output Artifacts

Publish the project and inspect the output to ensure all required files are present:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory match expectations, including any static assets or configuration files.

## 8. Review Configuration Files

Check that `app.config` or `web.config` entries have been migrated to `appsettings.json` or equivalent .NET configuration providers, as the old XML-based configuration system has limited support in cross-platform .NET.