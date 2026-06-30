# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

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

Review the output for any warnings about deprecated packages or packages that do not support your target framework. If any packages are flagged, check NuGet.org for updated versions that support .NET.

## 3. Build the Solution

Perform a clean build to confirm no errors surface during compilation:

```bash
dotnet clean
dotnet build --configuration Release
```

Review all warnings in the build output. While warnings do not block compilation, they may indicate obsolete APIs or patterns that should be addressed before deployment.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify runtime behavior has not regressed:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures after a framework migration are often caused by:
- Behavioral differences in APIs between .NET Framework and modern .NET
- Missing configuration files (e.g., `app.config` vs `appsettings.json`)
- Platform-specific code paths that no longer apply

## 5. Audit Removed or Changed APIs

Check whether the project previously relied on any APIs that are not available in modern .NET. The [.NET Upgrade Assistant compatibility analyzer](https://learn.microsoft.com/en-us/dotnet/core/porting/upgrade-assistant-overview) or the [Platform Compatibility Analyzer](https://learn.microsoft.com/en-us/dotnet/standard/analyzers/platform-compat-analyzer) can assist with this.

You can also reference the official API diff documentation:
- [Breaking changes in .NET](https://learn.microsoft.com/en-us/dotnet/core/compatibility/breaking-changes)

## 6. Validate Cross-Platform Behavior

If cross-platform support is a goal, test the application on each target operating system (Windows, Linux, macOS) by running:

```bash
dotnet run --configuration Release
```

Pay particular attention to:
- File path separators (`\` vs `/`)
- Case sensitivity in file system operations
- Windows-specific registry or COM interop calls that may have been carried over

## 7. Publish the Application

Once validation is complete, publish the application using the appropriate runtime identifier (RID) for your target environment.

**Framework-dependent publish (smaller output, requires .NET runtime installed):**

```bash
dotnet publish -c Release -o ./publish
```

**Self-contained publish (includes the runtime, no dependency on installed .NET):**

```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate RID for your target platform (e.g., `win-x64`, `osx-x64`, `osx-arm64`).

## 8. Review Output Artifacts

Inspect the contents of the `./publish` directory to confirm all expected files are present, including configuration files, static assets, and any native dependencies.