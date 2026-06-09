# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on all machines that will build or run this project.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been resolved through compatibility fallbacks.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings introduced at compile time:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types, deprecated APIs, or platform compatibility analyzers (`CA1416`).

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review any failing tests and determine whether failures are caused by migration-related changes or pre-existing issues.

## 5. Perform Runtime Validation on Target Platforms

Since the goal is cross-platform support, run the application on each intended operating system (Windows, Linux, macOS) and verify:

- File path handling does not rely on Windows-specific separators.
- Any P/Invoke or interop code is either guarded with platform checks or replaced with cross-platform alternatives.
- Environment-specific configuration (registry access, Windows event log, etc.) is not called unconditionally.

## 6. Review Removed or Changed APIs

Check for any usage of APIs that were available in .NET Framework but have changed behavior or been removed in .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) and the [.NET API compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) are useful references for this step.

## 7. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` flag (`win-x64`, `osx-x64`, `linux-x64`, etc.) and `--self-contained` option based on your deployment requirements. A self-contained deployment (`--self-contained true`) bundles the .NET runtime and removes the dependency on a pre-installed runtime on the target machine.