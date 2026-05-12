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

Address any warnings that surface during this step, particularly those related to nullable reference types or obsolete APIs, as these may indicate areas where the migration introduced subtle issues.

## 3. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review test output carefully. Any failing tests should be investigated to determine whether they are caused by behavioral differences between the old .NET Framework runtime and the new cross-platform .NET runtime.

## 4. Verify Platform-Specific Code

Inspect the codebase for any APIs that were available in .NET Framework but have changed or been removed in cross-platform .NET. Common areas to check include:

- `System.Web` usages (not available in cross-platform .NET)
- Windows Registry access (`Microsoft.Win32.Registry`)
- `AppDomain` usage patterns that differ between runtimes
- `BinaryFormatter` (deprecated and disabled by default)
- Any P/Invoke calls targeting Windows-only native libraries

Use the [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the `Microsoft.DotNet.PlatformAbstractions` tooling to identify remaining compatibility concerns.

## 5. Review Target Framework Monikers

Open each `.csproj` file and confirm that the `<TargetFramework>` element is set to an appropriate and currently supported version, such as `net8.0`. Avoid targeting end-of-life versions like `net5.0` or `net6.0` unless there is a specific reason.

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any platform-specific runtime issues that do not appear at compile time.

```bash
dotnet run --configuration Release
```

## 7. Review Configuration and App Settings

Ensure that any `App.config` or `Web.config` files have been properly migrated to `appsettings.json` or environment-based configuration using `Microsoft.Extensions.Configuration`. The old XML-based configuration system is not natively used in cross-platform .NET applications.

## 8. Publish the Application

Once validation is complete, publish the application using the following command, adjusting the runtime identifier (`-r`) as needed for your target environment:

```bash
dotnet publish --configuration Release -r win-x64 --self-contained false
```

For a self-contained deployment that includes the .NET runtime:

```bash
dotnet publish --configuration Release -r win-x64 --self-contained true
```

Review the output directory to confirm all required files are present before deploying to the target environment.