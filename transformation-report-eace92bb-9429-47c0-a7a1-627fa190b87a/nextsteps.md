# Next Steps

The solution has no build errors following the transformation. The steps below cover validation and deployment of the migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

If multiple targets are required, use `<TargetFrameworks>` (plural) with a semicolon-separated list.

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or version conflicts and update them as needed in the `.csproj` file.

## 3. Build the Solution

Perform a clean build to confirm there are no errors in the restored state:

```bash
dotnet build --configuration Release
```

Address any warnings that surface at this stage, particularly those related to nullable reference types or obsolete APIs, as these can indicate runtime issues.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that behavior has not changed during the migration:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate platform-specific behavior differences between .NET Framework and cross-platform .NET.

## 5. Check for Windows-Specific APIs

Even when a project builds successfully, it may contain APIs that only function on Windows. Use the .NET Compatibility Analyzer to surface these:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, run the project on a non-Windows machine or inside a Linux environment to observe any `PlatformNotSupportedException` errors at runtime.

## 6. Review Configuration and File Paths

Inspect any file path handling, configuration file loading (e.g., `App.config` vs `appsettings.json`), and registry access. These are common sources of cross-platform runtime failures that do not produce build errors.

- Replace `ConfigurationManager` usage with `Microsoft.Extensions.Configuration` if not already done.
- Replace backslash path separators with `Path.Combine` or forward slashes.

## 7. Validate Runtime Behavior

Run the application directly and exercise its primary functionality:

```bash
dotnet run --configuration Release
```

Compare the output and behavior against the original .NET Framework version to confirm functional equivalence.

## 8. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent release:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs correctly from that output folder before distributing it.