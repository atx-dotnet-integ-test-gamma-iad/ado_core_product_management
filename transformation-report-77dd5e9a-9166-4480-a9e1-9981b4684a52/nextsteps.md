# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate areas that may cause runtime issues.

## 3. Run Existing Tests

If the solution contains test projects, execute the test suite to verify that behavior has not changed during migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime, particularly around areas such as:

- Globalization and culture handling
- File path separators
- Reflection behavior
- Thread and task scheduling

## 4. Validate Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to the intended version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure consistency across all projects in the solution to avoid inter-project compatibility issues.

## 5. Review Removed or Changed APIs

Cross-reference your codebase against the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) and the [.NET API differences](https://learn.microsoft.com/en-us/dotnet/core/porting/net-framework-tech-unavailable) documentation. Pay particular attention to:

- `System.Web` usages (not available in cross-platform .NET)
- Windows Communication Foundation (WCF) server-side APIs
- Windows-specific registry or COM interop calls
- `AppDomain` usage

## 6. Run on Target Platforms

If cross-platform support is a goal, test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues:

```bash
dotnet run --configuration Release
```

Pay attention to file system case sensitivity on Linux, path separator differences, and any platform-specific library dependencies.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier for your environment (e.g., `win-x64`, `osx-x64`). Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 8. Review Output Directory

Inspect the publish output directory to confirm all expected assemblies, configuration files, and static assets are present before deploying to the target environment.