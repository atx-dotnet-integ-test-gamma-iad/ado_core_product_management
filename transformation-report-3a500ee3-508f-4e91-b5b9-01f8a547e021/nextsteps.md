# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the absence of errors in a clean build environment:

```bash
dotnet build --configuration Release
```

Address any warnings that surface during this step, particularly those related to nullable reference types or platform compatibility analyzers, as these can indicate subtle issues introduced during migration.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed after migration:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific APIs

Review the codebase for any APIs that were previously available in .NET Framework but may behave differently or require alternative implementations in cross-platform .NET. Common areas to check include:

- `System.Windows.Forms` or `System.Web` usage (these are not fully cross-platform)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific interop or P/Invoke calls
- `AppDomain` usage, as some members are no longer supported
- `BinaryFormatter`, which is disabled by default in modern .NET

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 5. Review Target Framework Monikers

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to an appropriate and currently supported version, such as `net8.0`. Avoid using end-of-life versions such as `net5.0` or `net6.0` if long-term support is a requirement.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that would not appear during a Windows-only build.

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier for your deployment target:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier (e.g., `linux-x64`, `osx-x64`) based on your deployment environment. Use `--self-contained true` if you require the .NET runtime to be bundled with the output.

## 8. Review Output Artifacts

Inspect the contents of the `publish` output directory to confirm that all expected assemblies, configuration files, and static assets are present before deploying to the target environment.