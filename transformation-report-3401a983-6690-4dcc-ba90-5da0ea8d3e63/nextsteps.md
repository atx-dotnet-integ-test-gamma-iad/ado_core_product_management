# Next Steps

The transformation appears to have completed successfully. There are no build errors reported across any of the projects in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net4x` or `netstandard` targets unless that is intentional.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly against the new target framework:

```bash
dotnet restore
```

Review the output for any dependency warnings, such as packages that do not support the target framework or packages that have been deprecated.

## 3. Build the Solution

Perform a clean build of the entire solution to confirm there are no warnings that may indicate runtime issues:

```bash
dotnet build --configuration Release
```

Address any warnings related to nullable reference types, obsolete APIs, or platform compatibility attributes (`[SupportedOSPlatform]`).

## 4. Run Existing Tests

If the solution contains test projects, execute the full test suite:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime, particularly around:

- Globalization and culture handling
- File path separators
- Reflection behavior
- `System.Configuration` usage (which is not fully supported on cross-platform .NET)

## 5. Check for Windows-Specific API Usage

Run the .NET Compatibility Analyzer or review the build output for `CA1416` platform compatibility warnings. APIs such as the Windows Registry, `System.Drawing` (GDI+), WCF server-side components, and certain `System.Security` features may not function on non-Windows platforms.

You can also use the `dotnet-apicompat` tool or the compatibility suppressor to identify problematic calls:

```bash
dotnet tool install -g Microsoft.DotNet.ApiCompat
```

## 6. Validate Runtime Behavior

Run the application manually or through integration tests on each target platform (Windows, Linux, macOS) to catch any runtime-only issues that do not surface at compile time. Pay particular attention to:

- File I/O paths using hardcoded backslashes
- Case-sensitive file system differences on Linux/macOS
- Environment variable differences across operating systems
- Thread culture and encoding defaults

## 7. Review `App.config` / `Web.config` Usage

Cross-platform .NET does not use `App.config` or `Web.config` in the same way as .NET Framework. If the project relied on `ConfigurationManager`, consider migrating configuration to `Microsoft.Extensions.Configuration` using `appsettings.json` or environment variables.

## 8. Publish the Application

Once validation is complete, publish the application for the desired runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, `osx-arm64`, etc.) as needed. Review the publish output directory to confirm all required assets are present.