# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full build to confirm the absence of errors in a clean environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these can indicate latent issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific Behavior

Cross-platform .NET differs from .NET Framework in several areas. Manually verify the following:

- **File system paths**: Ensure no hardcoded Windows-style paths (e.g., backslashes) exist in the codebase.
- **Registry access**: `Microsoft.Win32.Registry` is not available on Linux/macOS. If the project uses registry access, this will need to be replaced with an alternative configuration mechanism.
- **Windows Communication Foundation (WCF)**: WCF server-side is not supported in cross-platform .NET. If WCF is used, consider migrating to gRPC or ASP.NET Core.
- **`System.Drawing`**: On non-Windows platforms, `System.Drawing.Common` requires native dependencies. Consider replacing it with a cross-platform alternative such as `SkiaSharp` if cross-platform image processing is needed.
- **`AppDomain`**: Some `AppDomain` APIs are no longer supported. Review any usage of `AppDomain.CreateDomain` or similar methods.

## 5. Review Removed or Changed APIs

Use the [.NET Upgrade Assistant](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [.NET Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/analyzers) to scan for any API usage that may behave differently at runtime even if it compiles successfully:

```bash
dotnet add package Microsoft.DotNet.ApiCompat
```

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended target operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that do not appear at compile time.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) as needed. Use `--self-contained true` if you want to bundle the .NET runtime with the output.

## 8. Review Output Structure

After publishing, verify the output directory contains all expected assemblies, configuration files, and static assets. Confirm that any files previously copied by MSBuild post-build events are still being included correctly.