# Next Steps

The transformation appears to have completed successfully. There are no build errors reported across any of the projects in the solution. Below are steps to validate, test, and deploy the migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless intentionally targeting multiple frameworks.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that were not captured previously:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or platform compatibility warnings (CA1416).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release --logger trx
```

Review the test results output. Investigate and resolve any failing tests before proceeding.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify any remaining Windows-specific API calls that may fail on Linux or macOS:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

Only add this package if Windows-specific APIs are required and the deployment target is Windows. Otherwise, replace those APIs with cross-platform alternatives.

## 6. Validate Runtime Behavior

Run the application directly and exercise its primary workflows:

```bash
dotnet run --project AdoCore --configuration Release
```

Confirm that configuration files (e.g., `appsettings.json`), file paths, and environment variables resolve correctly on the target operating system.

## 7. Check for Hardcoded Paths

Search the codebase for hardcoded Windows-style paths (e.g., `C:\`, backslashes as directory separators) and replace them with `Path.Combine` or `Path.DirectorySeparatorChar` to ensure cross-platform compatibility.

## 8. Review Removed or Changed APIs

Consult the [.NET breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes) for the specific version you are targeting. Verify that any APIs used in the project have not been removed or had behavioral changes introduced.

## 9. Publish the Application

Once validation is complete, publish the application for the intended target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier (`win-x64`, `osx-x64`, etc.) and `--self-contained` flag based on your deployment environment and whether the .NET runtime will be pre-installed on the target machine.

## 10. Verify the Published Output

Navigate to the publish output directory and confirm all expected files are present, including configuration files and any static assets. Run the published output directly to confirm it starts correctly before deploying to the target environment.