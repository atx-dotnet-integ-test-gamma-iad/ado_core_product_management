# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework is set to a supported cross-platform .NET version (e.g., `net6.0`, `net7.0`, or `net8.0`):

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

If it is still referencing `net48` or any other .NET Framework moniker, update it accordingly.

## 2. Restore NuGet Packages

Run the following command from the solution root to ensure all dependencies are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about packages that are not compatible with the target framework.

## 3. Build the Solution

Perform a full build to confirm there are no errors:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to deprecated APIs or platform compatibility.

## 4. Run Existing Tests

If the solution contains a test project, execute the test suite to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test results and investigate any failures. Pay particular attention to tests that exercise database access, file I/O, or platform-specific behavior, as these areas are most commonly affected by cross-platform migrations.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the build output for `CA1416` warnings, which indicate calls to APIs that are only supported on specific platforms (e.g., Windows registry access, COM interop). Replace or conditionally compile any such usages.

## 6. Validate Runtime Behavior

Run the application on the target platform(s) (e.g., Linux, macOS, Windows) to confirm runtime behavior is correct:

```bash
dotnet run --configuration Release
```

Test all critical code paths, especially those involving:
- Database connections (ADO.NET providers, connection strings)
- File system paths (use `Path.Combine` rather than hardcoded separators)
- Configuration loading (`appsettings.json` vs. legacy `App.config`)

## 7. Review Configuration Files

If the project previously relied on `App.config` or `Web.config`, verify that configuration has been migrated to `appsettings.json` or environment variables, and that `Microsoft.Extensions.Configuration` is being used where appropriate.

## 8. Publish the Application

Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your target environment (e.g., `win-x64`, `osx-x64`). Review the contents of the `publish` output folder before deploying.