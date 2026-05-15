# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version (e.g., `net8.0` or `net6.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing a Windows-specific framework (e.g., `net472`), update it accordingly.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated or incompatible packages.

## 3. Build the Solution

Perform a clean build to confirm there are no latent issues:

```bash
dotnet build --configuration Release
```

Verify that the build output reports zero errors and zero warnings, or review any warnings that may indicate compatibility concerns.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not been broken during the migration:

```bash
dotnet test --configuration Release
```

Review the test results and address any failing tests before proceeding.

## 5. Validate Runtime Behavior on Target Platforms

Since the goal is cross-platform compatibility, run the application on each intended platform (Windows, Linux, macOS) to identify any platform-specific runtime issues that would not surface at compile time. Pay particular attention to:

- File path separators (`/` vs `\`)
- Platform-specific APIs that may have been used in the original code
- Registry access or Windows-specific interop calls
- Case-sensitive file system behavior on Linux

## 6. Review Removed or Changed APIs

Check the code for any usage of APIs that behave differently or have been removed in modern .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.UpgradeAssistant` tool can help identify these:

```bash
dotnet tool install -g upgrade-assistant
upgrade-assistant analyze <solution-file>.sln
```

## 7. Review NuGet Package Compatibility

Confirm that all referenced NuGet packages support the target framework. Packages that were designed for .NET Framework may have limited or no support for cross-platform .NET. Replace any such packages with their modern equivalents where necessary.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier (`win-x64`, `osx-x64`, `linux-x64`, etc.) and `--self-contained` flag based on your deployment requirements.