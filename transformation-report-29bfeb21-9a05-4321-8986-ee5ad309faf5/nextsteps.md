# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are properly restored:

```bash
dotnet restore
```

Review the output for any warnings related to package compatibility or deprecated packages targeting older frameworks.

## 2. Build the Solution

Perform a full solution build to confirm the error-free state is consistent across all configurations:

```bash
dotnet build --configuration Release
```

Also verify the Debug configuration builds cleanly:

```bash
dotnet build --configuration Debug
```

## 3. Run Existing Tests

If the solution contains test projects, execute the full test suite:

```bash
dotnet test --configuration Release
```

Review test results carefully. Any test failures that were not present before the migration should be investigated, as they may indicate behavioral differences between the legacy .NET Framework and the new cross-platform .NET runtime.

## 4. Check Target Framework Compatibility

Open each `.csproj` file and confirm the `<TargetFramework>` element is set to an appropriate and supported version, such as `net8.0`. Avoid using end-of-life versions like `net5.0` or `net6.0` if long-term support is a requirement.

## 5. Review Platform-Specific APIs

Search the codebase for any APIs that were available in .NET Framework but have limited or no support in cross-platform .NET. Common areas to check include:

- `System.Web` usage
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage beyond what is supported
- WCF server-side components
- `BinaryFormatter` (deprecated and disabled by default)

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to assist with this review.

## 6. Validate Runtime Behavior

Run the application manually and exercise its primary workflows. Pay particular attention to:

- File path handling, as .NET on Linux/macOS is case-sensitive
- Configuration loading (e.g., migration from `App.config` to `appsettings.json`)
- Any reflection-based code that may behave differently under the new runtime

## 7. Publish the Application

Once validation is complete, publish the application using:

```bash
dotnet publish --configuration Release --output ./publish
```

For a self-contained deployment that does not require the .NET runtime to be installed on the target machine:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained true --output ./publish
```

Replace `win-x64` with the appropriate runtime identifier for your target platform (e.g., `linux-x64`, `osx-x64`).

## 8. Review Output Artifacts

Inspect the contents of the publish output directory to confirm all expected assemblies, configuration files, and static assets are present before distributing or deploying the application.