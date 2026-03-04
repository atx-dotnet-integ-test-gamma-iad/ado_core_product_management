# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET version installed on your machine by running:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages that only target `net4x` with their cross-platform equivalents where applicable.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review any warnings in the build output, as some warnings may indicate runtime issues that do not surface as errors.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests and determine whether failures are caused by behavioral differences in the new runtime or by test setup issues related to the migration.

## 5. Validate Platform-Specific Code

Search the codebase for any APIs that were commonly Windows-only in .NET Framework, including but not limited to:

- `System.Windows.Forms`
- `System.Drawing` (GDI+)
- `Microsoft.Win32.Registry`
- `System.Security.Permissions`
- COM interop calls

Run the following on non-Windows platforms if cross-platform support is required, and address any `PlatformNotSupportedException` exceptions that surface at runtime.

## 6. Check Configuration and App Settings

If the project previously used `App.config` or `Web.config`, verify that settings have been migrated to `appsettings.json` or environment variables, as `ConfigurationManager` behavior differs in cross-platform .NET. Confirm the following:

- Connection strings are accessible at runtime.
- Any custom configuration sections have been ported correctly.

## 7. Smoke Test Core Functionality

Manually exercise the primary entry points of the application to confirm expected behavior. Focus on:

- Data access operations if `AdoCore` implies ADO.NET usage.
- Connection handling, query execution, and result mapping.
- Exception handling paths, particularly around database connectivity.

## 8. Review Nullable Reference Type Warnings

If the project has `<Nullable>enable</Nullable>` in the `.csproj`, review any nullable warnings in the build output. While these do not cause build failures by default, they can indicate potential null reference issues at runtime.

## 9. Publish the Application

Once validation is complete, publish the application for the target environment:

```bash
dotnet publish --configuration Release --runtime win-x64 --self-contained false
```

Replace `win-x64` with the appropriate runtime identifier for your target platform, such as `linux-x64` or `osx-x64`. Use `--self-contained true` if the target machine does not have the .NET runtime installed.

## 10. Verify Output Artifacts

Inspect the publish output directory to confirm all expected assemblies, configuration files, and static assets are present before deploying to the target environment.