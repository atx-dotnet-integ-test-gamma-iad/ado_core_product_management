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

Review the output for any warnings about deprecated packages or packages that do not support the target framework. If any packages are flagged, check NuGet for updated versions that support the target TFM.

## 3. Build the Solution

Perform a clean build to confirm there are no compilation issues:

```bash
dotnet clean
dotnet build --configuration Release
```

Review the output for any warnings, even if there are no errors. Warnings related to nullable reference types, obsolete APIs, or platform compatibility attributes may indicate areas that need attention.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify existing behavior is preserved:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully. Failures may indicate behavioral differences between the legacy .NET Framework runtime and the new cross-platform .NET runtime, particularly around areas such as:

- `System.Configuration` usage
- Windows-specific APIs (e.g., registry access, WCF, Windows Forms)
- Globalization and encoding defaults
- Reflection behavior changes

## 5. Check for Platform-Specific API Usage

Run the .NET Compatibility Analyzer to identify any remaining platform-specific API calls that may not behave correctly on non-Windows systems:

```bash
dotnet add package Microsoft.DotNet.Analyzers.Compatibility
```

Alternatively, review the build output for `CA1416` platform compatibility warnings if analyzers are already enabled.

## 6. Test on Target Platforms

If cross-platform support is a goal, run and test the application on each intended operating system (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time.

```bash
dotnet run --configuration Release
```

Pay particular attention to:

- File path separator differences (`\` vs `/`)
- Case-sensitive file systems on Linux
- Missing Windows-only dependencies

## 7. Publish the Application

Once validation is complete, publish the application for the target runtime:

**Framework-dependent (requires .NET runtime installed on target machine):**

```bash
dotnet publish --configuration Release --output ./publish
```

**Self-contained (bundles the runtime):**

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained true --output ./publish
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. A full list of runtime identifiers is available in the [.NET RID Catalog](https://learn.microsoft.com/en-us/dotnet/core/rid-catalog).

## 8. Review Output Artifacts

Inspect the `./publish` directory to confirm all expected files are present, including configuration files, static assets, and any native dependencies. Verify the application starts correctly from the published output before promoting it to any environment.