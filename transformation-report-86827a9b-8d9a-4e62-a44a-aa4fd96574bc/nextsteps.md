# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended cross-platform .NET version, for example:

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

Review the output for any warnings about deprecated packages or packages that do not support the target framework. Replace any packages that only support `.NET Framework` with their cross-platform equivalents where applicable.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review all warnings in the build output. Warnings related to obsolete APIs or platform compatibility should be addressed before deployment.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully. Failures may indicate behavioral differences between .NET Framework and cross-platform .NET, such as changes in:

- `System.Drawing` support (not fully supported on Linux/macOS without additional packages)
- `AppDomain` behavior
- Reflection differences
- Culture and encoding defaults

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the built-in Roslyn analyzers to identify any remaining platform-specific API calls:

```bash
dotnet add package Microsoft.DotNet.PlatformAbstractions
```

Alternatively, enable the platform compatibility analyzer by ensuring the following is present in the `.csproj`:

```xml
<EnableNETAnalyzers>true</EnableNETAnalyzers>
<AnalysisMode>All</AnalysisMode>
```

Rebuild and review any new `CA1416` (platform compatibility) warnings.

## 6. Test on Target Platforms

If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time.

```bash
dotnet run --configuration Release
```

Pay particular attention to:

- File path separator differences (`\` vs `/`)
- Case sensitivity of the file system on Linux
- Windows-only APIs such as the registry or certain WinForms/WPF components

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

**Framework-dependent (requires .NET runtime on the target machine):**

```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (bundles the runtime):**

```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, `osx-arm64`, etc.) as needed. A full list of runtime identifiers is available in the [.NET RID catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).

## 8. Review Output Artifacts

Inspect the `./publish` directory to confirm all expected files, configuration files, and assets are present. Verify that any files previously copied by MSBuild targets or post-build events are still being included correctly.