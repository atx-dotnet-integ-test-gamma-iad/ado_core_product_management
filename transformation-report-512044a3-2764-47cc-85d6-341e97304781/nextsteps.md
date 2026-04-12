# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build context:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute the test suite to verify that runtime behavior has not changed:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures after a cross-platform migration are often caused by:
- Path separator differences (`\` vs `/`)
- Culture or encoding differences between platforms
- APIs that were available in .NET Framework but behave differently in .NET

## 4. Verify Platform-Specific API Usage

Check the code for any remaining usage of Windows-only APIs. You can use the .NET Compatibility Analyzer to assist with this:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Pay particular attention to:
- `System.Windows.Forms` or `System.Web` references
- Registry access (`Microsoft.Win32.Registry`)
- COM interop or P/Invoke calls targeting Windows-specific libraries

## 5. Review Configuration Files

Ensure that any configuration previously handled by `App.config` or `Web.config` has been correctly migrated to the appropriate .NET configuration system, such as `appsettings.json` with `Microsoft.Extensions.Configuration`.

## 6. Validate Output Artifacts

After a successful Release build, inspect the output directory (`bin/Release/net*/`) to confirm:
- The correct target framework moniker (TFM) is reflected in the output path
- All expected assemblies and dependencies are present
- No `.NET Framework`-specific assemblies have been inadvertently included

## 7. Smoke Test on Target Platforms

Run the application on each platform you intend to support (e.g., Windows, Linux, macOS) to catch any runtime issues that static analysis may not surface:

```bash
dotnet run --configuration Release
```

If publishing a self-contained executable, use:

```bash
dotnet publish --configuration Release --runtime <runtime-identifier> --self-contained true
```

Replace `<runtime-identifier>` with the appropriate value, such as `win-x64`, `linux-x64`, or `osx-x64`.

## 8. Review Project File Modernization

Open each `.csproj` file and confirm the following:
- The `<TargetFramework>` element targets the intended .NET version (e.g., `net8.0`)
- Unnecessary or legacy MSBuild properties have been removed
- `<PackageReference>` is used in place of legacy `packages.config` references