# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are steps to validate and test the migrated project before deploying it.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net4x` or `netstandard` targets unless that is intentional.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or unresolved dependencies.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that were not surfaced during the transformation analysis:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger trx
```

Review the test results for any failures or skipped tests that may indicate behavioral regressions introduced during migration.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or the `dotnet-compatibility` tool to identify any APIs that may not be supported on all target platforms:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Review analyzer warnings in the build output and replace or conditionally compile any platform-specific code paths.

## 6. Validate Runtime Behavior

Run the application on each target platform (Windows, Linux, macOS) to confirm runtime behavior is consistent. Pay particular attention to:

- File path handling (`Path.Combine` vs hardcoded separators)
- Environment variable access
- Reflection-based code
- Any use of `Windows Registry` or other OS-specific features

## 7. Review NuGet Package Versions

Check that all NuGet packages in use have versions compatible with the target .NET version. Packages that previously targeted `net4x` may have newer versions with cross-platform support:

```bash
dotnet list package --outdated
```

Update packages where appropriate and re-run the build and tests after each update.

## 8. Publish and Smoke Test

Publish the application for the target runtime and perform a basic smoke test:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with your intended runtime identifier. Verify the published output runs as expected in the target environment.