# Next Steps

The transformation appears to have completed successfully. There are no build errors reported across any of the projects in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects still reference `net48`, `netcoreapp`, or other legacy monikers unless that is intentional.

## 2. Restore Dependencies

Run a full NuGet restore to confirm all packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts.

## 3. Build the Solution

Perform a clean build to confirm no errors surface outside of the IDE:

```bash
dotnet build --configuration Release
```

Address any warnings that could indicate runtime issues, such as nullable reference warnings or obsolete API usage.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as they may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime.

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for APIs that are Windows-only or otherwise platform-restricted:

```bash
dotnet add package Microsoft.Windows.Compatibility
```

If the application is intended to run on non-Windows platforms, replace or conditionally compile any Windows-specific APIs (e.g., registry access, `System.Drawing`, WCF server-side, etc.).

## 6. Validate Configuration Files

- Confirm that `app.config` or `web.config` settings have been migrated to `appsettings.json` or environment variables where applicable.
- Verify that connection strings, logging configuration, and any custom configuration sections are correctly read at runtime.

## 7. Smoke Test the Application

Run the application locally and exercise its primary workflows:

```bash
dotnet run --project <YourMainProject> --configuration Release
```

Check application logs for runtime exceptions that would not appear at compile time, such as missing assemblies, reflection-based failures, or configuration binding errors.

## 8. Review Removed or Changed APIs

Consult the official [.NET breaking changes documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes) for the version you are targeting. Pay particular attention to areas such as:

- `System.Runtime.Serialization` / binary serialization (removed in .NET 9)
- `System.Web` (not available outside of Windows-specific compatibility packs)
- `AppDomain` isolation patterns
- Thread culture and globalization behavior changes

## 9. Publish a Self-Contained Build

Once validation passes, produce a release-ready publish output:

```bash
dotnet publish --configuration Release --self-contained true --runtime <target-rid>
```

Replace `<target-rid>` with the appropriate Runtime Identifier, for example `win-x64`, `linux-x64`, or `osx-x64`. Verify the output directory contains all expected files and that the application runs correctly from the published output.